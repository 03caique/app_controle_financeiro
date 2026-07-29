import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/transacao_repository.dart';
import '../../theme/app_theme.dart';

class CategoriasScreen extends StatefulWidget {
  final int usuarioId;

  const CategoriasScreen({super.key, required this.usuarioId});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _repository = CategoriaRepository();
  final _transacaoRepository = TransacaoRepository();
  List<Categoria> _categorias = [];
  Map<int, double> _gastosPorCategoria = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final lista = await _repository.listarTodas();

    final agora = DateTime.now();
    final anoMes = '${agora.year}-${agora.month.toString().padLeft(2, '0')}';

    final gastos = <int, double>{};
    for (final c in lista) {
      if (c.id != null && c.limite != null && c.limite! > 0) {
        gastos[c.id!] = await _transacaoRepository.totalGastoPorCategoriaNoMes(
          widget.usuarioId,
          c.id!,
          anoMes,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _categorias = lista;
      _gastosPorCategoria = gastos;
      _carregando = false;
    });
  }

  Future<void> _abrirFormulario({Categoria? categoria}) async {
    final nomeController = TextEditingController(text: categoria?.nome ?? '');
    final limiteController = TextEditingController(
      text: categoria?.limite != null
          ? categoria!.limite!.toStringAsFixed(2)
          : '',
    );
    String tipo = categoria?.tipo ?? 'despesa';
    final formKey = GlobalKey<FormState>();

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.parchment,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          title: Text(
            categoria == null ? 'Nova Categoria' : 'Editar Categoria',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'NOME'),
                    cursorColor: AppColors.brass,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'TIPO'),
                    items: const [
                      DropdownMenuItem(
                        value: 'despesa',
                        child: Text('Despesa'),
                      ),
                      DropdownMenuItem(
                        value: 'receita',
                        child: Text('Receita'),
                      ),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => tipo = v ?? 'despesa'),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: limiteController,
                    decoration: const InputDecoration(
                      labelText: 'LIMITE MENSAL (OPCIONAL)',
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brick,
                      foregroundColor: Colors
                          .white, // Ajuste a cor do texto se preferir outra cor de alto contraste
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text("Salvar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (salvar != true) return;

    final limiteTexto = limiteController.text.trim().replaceAll(',', '.');
    final limite = limiteTexto.isEmpty ? null : double.tryParse(limiteTexto);

    final nova = Categoria(
      id: categoria?.id,
      nome: nomeController.text.trim(),
      tipo: tipo,
      limite: limite,
    );

    if (categoria == null) {
      await _repository.criar(nova);
    } else {
      await _repository.atualizar(nova);
    }
    _carregar();
  }

  Future<void> _excluir(Categoria categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text(
          'Excluir categoria',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Excluir "${categoria.nome}"?',
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
    await _repository.excluir(categoria.id!);
    _carregar();
  }

  Widget? _buildProgressoLimite(Categoria c) {
    if (c.limite == null || c.limite! <= 0) return null;

    final limite = c.limite!;
    final gasto = _gastosPorCategoria[c.id] ?? 0;
    final proporcao = (gasto / limite).clamp(0.0, 1.0);
    final estourou = gasto > limite;
    final cor = estourou ? AppColors.brick : AppColors.brass;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: proporcao,
              minHeight: 6,
              backgroundColor: AppColors.mutedInk.withValues(alpha: 0.2),
              color: cor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'R\$ ${gasto.toStringAsFixed(2)} de R\$ ${limite.toStringAsFixed(2)}'
            '${estourou ? '  •  Estourou!' : ''}',
            style: AppTypography.amount(fontSize: 12, color: cor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brass),
            )
          : _categorias.isEmpty
          ? Center(
              child: Text(
                'Nenhuma categoria cadastrada.',
                style: TextStyle(
                  color: AppColors.parchment.withValues(alpha: 0.6),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final c = _categorias[index];
                final isReceita = c.tipo == 'receita';
                final cor = isReceita ? AppColors.emerald : AppColors.brick;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      isReceita ? Icons.arrow_upward : Icons.arrow_downward,
                      color: cor,
                    ),
                    title: Text(
                      c.nome,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: _buildProgressoLimite(c),
                    onTap: () => _abrirFormulario(categoria: c),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.mutedInk,
                      ),
                      onPressed: () => _excluir(c),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppColors.brass,
        foregroundColor: AppColors.inkNavy,
        child: const Icon(Icons.add),
      ),
    );
  }
}
