import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../models/transacao.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/transacao_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class TransacaoFormScreen extends StatefulWidget {
  final int usuarioId;
  final Transacao? transacaoExistente;

  const TransacaoFormScreen({
    super.key,
    required this.usuarioId,
    this.transacaoExistente,
  });

  bool get isEdicao => transacaoExistente != null;

  @override
  State<TransacaoFormScreen> createState() => _TransacaoFormScreenState();
}

class _TransacaoFormScreenState extends State<TransacaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();

  final _categoriaRepository = CategoriaRepository();
  final _transacaoRepository = TransacaoRepository();

  String _tipo = 'despesa';
  DateTime _data = DateTime.now();
  int? _categoriaId;
  List<Categoria> _categorias = [];

  bool _carregandoCategorias = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    final existente = widget.transacaoExistente;
    if (existente != null) {
      _tipo = existente.tipo;
      _valorController.text = existente.valor.toStringAsFixed(2);
      _descricaoController.text = existente.descricao ?? '';
      _data = DateTime.tryParse(existente.data) ?? DateTime.now();
      _categoriaId = existente.categoriaId;
    }

    _carregarCategorias();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    setState(() => _carregandoCategorias = true);
    final categorias = await _categoriaRepository.listarPorTipo(_tipo);

    if (!mounted) return;
    setState(() {
      _categorias = categorias;
      if (_categoriaId != null &&
          !categorias.any((c) => c.id == _categoriaId)) {
        _categoriaId = null;
      }
      _categoriaId ??= categorias.isNotEmpty ? categorias.first.id : null;
      _carregandoCategorias = false;
    });
  }

  Future<void> _mudarTipo(String novoTipo) async {
    if (novoTipo == _tipo) return;
    setState(() {
      _tipo = novoTipo;
      _categoriaId = null;
    });
    await _carregarCategorias();
  }

  Future<void> _selecionarData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada != null) {
      setState(() => _data = selecionada);
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  String _dataParaBanco(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '${data.year}-$mes-$dia';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre ou selecione uma categoria.')),
      );
      return;
    }

    setState(() => _salvando = true);

    final valor = double.parse(_valorController.text.replaceAll(',', '.'));
    final descricao = _descricaoController.text.trim();

    final transacao = Transacao(
      id: widget.transacaoExistente?.id,
      usuarioId: widget.usuarioId,
      categoriaId: _categoriaId!,
      tipo: _tipo,
      valor: valor,
      data: _dataParaBanco(_data),
      descricao: descricao.isEmpty ? null : descricao,
    );

    if (widget.isEdicao) {
      await _transacaoRepository.atualizar(transacao);
    } else {
      await _transacaoRepository.criar(transacao);
    }

    if (_tipo == 'despesa') {
      final categoria = _categorias.firstWhere((c) => c.id == _categoriaId);
      if (categoria.limite != null && categoria.limite! > 0) {
        final anoMes = _dataParaBanco(_data).substring(0, 7);
        final totalGasto = await _transacaoRepository
            .totalGastoPorCategoriaNoMes(widget.usuarioId, categoria.id!, anoMes);

        if (totalGasto > categoria.limite!) {
          await NotificationService().mostrarNotificacao(
            id: categoria.id!,
            titulo: 'Limite de gastos ultrapassado!',
            corpo:
                'Você já gastou R\$ ${totalGasto.toStringAsFixed(2)} em '
                '${categoria.nome}, passando do limite de '
                'R\$ ${categoria.limite!.toStringAsFixed(2)}.',
          );
        }
      }
    }

    setState(() => _salvando = false);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text(
          'Excluir transação',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Tem certeza que deseja excluir este registro?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.mutedInk),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.brick),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await _transacaoRepository.excluir(widget.transacaoExistente!.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdicao ? 'Editar Transação' : 'Nova Transação'),
        actions: [
          if (widget.isEdicao)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _salvando ? null : _excluir,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isEdicao ? 'EDITAR REGISTRO' : 'NOVO REGISTRO',
                    textAlign: TextAlign.center,
                    style: AppTypography.eyebrow,
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'despesa', label: Text('DESPESA')),
                      ButtonSegment(value: 'receita', label: Text('RECEITA')),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (selecao) => _mudarTipo(selecao.first),
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.mutedInk,
                      selectedBackgroundColor: AppColors.brass,
                      selectedForegroundColor: AppColors.inkNavy,
                      side: const BorderSide(color: AppColors.mutedInk),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const LedgerRule(),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _valorController,
                    decoration: const InputDecoration(
                      labelText: 'VALOR',
                      prefixText: 'R\$ ',
                    ),
                    style: AppTypography.amount(fontSize: 18),
                    cursorColor: AppColors.brass,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o valor';
                      }
                      final normalizado = value.replaceAll(',', '.');
                      final numero = double.tryParse(normalizado);
                      if (numero == null || numero <= 0) {
                        return 'Informe um valor válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _carregandoCategorias
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(color: AppColors.brass),
                        )
                      : DropdownButtonFormField<int>(
                          initialValue: _categoriaId,
                          decoration: const InputDecoration(
                            labelText: 'CATEGORIA',
                          ),
                          style: textTheme.bodyLarge,
                          items: _categorias
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.nome),
                                ),
                              )
                              .toList(),
                          onChanged: (valor) =>
                              setState(() => _categoriaId = valor),
                          validator: (valor) =>
                              valor == null ? 'Selecione uma categoria' : null,
                        ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _selecionarData,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'DATA',
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.mutedInk,
                        ),
                      ),
                      child: Text(_formatarData(_data), style: textTheme.bodyLarge),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'DESCRIÇÃO (OPCIONAL)',
                    ),
                    style: textTheme.bodyLarge,
                    cursorColor: AppColors.brass,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.inkNavy,
                              ),
                            ),
                          )
                        : const Text('SALVAR'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}