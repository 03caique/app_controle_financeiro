import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../models/transacao.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/transacao_repository.dart';
import '../../services/notification_service.dart';

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
        title: const Text('Excluir transação'),
        content: const Text('Tem certeza que deseja excluir este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'despesa', label: Text('Despesa')),
                    ButtonSegment(value: 'receita', label: Text('Receita')),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (selecao) => _mudarTipo(selecao.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                  ),
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
                const SizedBox(height: 16),
                _carregandoCategorias
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(),
                      )
                    : DropdownButtonFormField<int>(
                        initialValue: _categoriaId,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
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
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selecionarData,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Data'),
                    child: Text(_formatarData(_data)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? const CircularProgressIndicator()
                      : const Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}