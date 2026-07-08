import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../repositories/categoria_repository.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _repository = CategoriaRepository();
  List<Categoria> _categorias = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final lista = await _repository.listarTodas();
    if (!mounted) return;
    setState(() {
      _categorias = lista;
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
                  subtitle: c.limite != null
                      ? Text('Limite: R\$ ${c.limite!.toStringAsFixed(2)}')
                      : null,
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