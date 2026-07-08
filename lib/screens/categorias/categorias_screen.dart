import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../repositories/categoria_repository.dart';
import '../../repositories/transacao_repository.dart';

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
          title: Text(categoria == null ? 'Nova Categoria' : 'Editar Categoria'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'despesa', child: Text('Despesa')),
                    DropdownMenuItem(value: 'receita', child: Text('Receita')),
                  ],
                  onChanged: (v) => setStateDialog(() => tipo = v ?? 'despesa'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: limiteController,
                  decoration: const InputDecoration(
                    labelText: 'Limite mensal (opcional)',
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Salvar'),
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
        title: const Text('Excluir categoria'),
        content: Text('Excluir "${categoria.nome}"?'),
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
    await _repository.excluir(categoria.id!);
    _carregar();
  }

  Widget? _buildProgressoLimite(Categoria c) {
    if (c.limite == null || c.limite! <= 0) return null;

    final limite = c.limite!;
    final gasto = _gastosPorCategoria[c.id] ?? 0;
    final proporcao = (gasto / limite).clamp(0.0, 1.0);
    final estourou = gasto > limite;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: proporcao,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              color: estourou ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${gasto.toStringAsFixed(2)} de R\$ ${limite.toStringAsFixed(2)}'
            '${estourou ? '  •  Estourou!' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: estourou ? Colors.red[800] : Colors.grey[700],
            ),
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
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final c = _categorias[index];
                return ListTile(
                  leading: Icon(
                    c.tipo == 'receita' ? Icons.arrow_upward : Icons.arrow_downward,
                    color: c.tipo == 'receita' ? Colors.green : Colors.red,
                  ),
                  title: Text(c.nome),
                  subtitle: _buildProgressoLimite(c),
                  onTap: () => _abrirFormulario(categoria: c),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _excluir(c),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}