import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../models/transacao.dart';
import '../../repositories/transacao_repository.dart';
import '../../repositories/categoria_repository.dart';
import '../login/login_screen.dart';
import '../transacoes/transacao_form_screen.dart';
import '../../services/preferencias_service.dart';
import '../categorias/categorias_screen.dart';
import '../../models/categoria.dart';


class HomeScreen extends StatefulWidget {
  final Usuario usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _transacaoRepository = TransacaoRepository();
  final _categoriaRepository = CategoriaRepository();

  bool _carregando = true;
  double _saldo = 0;
  double _totalReceitas = 0;
  double _totalDespesas = 0;
  List<Transacao> _transacoes = [];
  Map<int, String> _nomesCategorias = {};
  int? _filtroCategoriaId;
  DateTimeRange? _filtroPeriodo;
  List<Categoria> _todasCategorias = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final saldo = await _transacaoRepository.calcularSaldo(widget.usuario.id!);
    final categorias = await _categoriaRepository.listarTodas();

    final transacoes = await _transacaoRepository.listarComFiltro(
      usuarioId: widget.usuario.id!,
      categoriaId: _filtroCategoriaId,
      dataInicio: _filtroPeriodo != null
          ? _formatarDataBanco(_filtroPeriodo!.start)
          : null,
      dataFim: _filtroPeriodo != null
          ? _formatarDataBanco(_filtroPeriodo!.end)
          : null,
    );

    _todasCategorias = categorias;
    
    double totalReceitas = 0;
    double totalDespesas = 0;
    for (final t in transacoes) {
      if (t.tipo == 'receita') {
        totalReceitas += t.valor;
      } else {
        totalDespesas += t.valor;
      }
    }

    final mapaCategorias = {
      for (final c in categorias) c.id!: c.nome,
    };

    if (!mounted) return;
    setState(() {
      _saldo = saldo;
      _totalReceitas = totalReceitas;
      _totalDespesas = totalDespesas;
      _transacoes = transacoes;
      _nomesCategorias = mapaCategorias;
      _carregando = false;
    });
  }

  Future<void> _abrirFormulario({Transacao? transacao}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransacaoFormScreen(
          usuarioId: widget.usuario.id!,
          transacaoExistente: transacao,
        ),
      ),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  Future<void> _excluirTransacao(Transacao transacao) async {
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

    await _transacaoRepository.excluir(transacao.id!);
    _carregarDados();
  }

  String _formatarDataBanco(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '${data.year}-$mes-$dia';
  }

  Future<void> _selecionarPeriodo() async {
    final periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _filtroPeriodo,
    );
    if (periodo != null) {
      setState(() => _filtroPeriodo = periodo);
      _carregarDados();
    }
  }

  void _limparFiltros() {
    setState(() {
      _filtroCategoriaId = null;
      _filtroPeriodo = null;
    });
    _carregarDados();
  }

  void _logout() async {
    await PreferenciasService().limparSessao();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${widget.usuario.nome}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriasScreen()),
            ).then((_) => _carregarDados()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBarraFiltro(),
                  const SizedBox(height: 16),
                  _buildCardSaldo(),
                  const SizedBox(height: 24),
                  const Text(
                    'Últimas transações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_transacoes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Nenhuma transação registrada.')),
                    )
                  else
                    ..._transacoes.map(_buildItemTransacao),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCardSaldo() {
    return Card(
      color: _saldo >= 0 ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Saldo disponível', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'R\$ ${_saldo.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _saldo >= 0 ? Colors.green[800] : Colors.red[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Receitas'),
                    Text(
                      'R\$ ${_totalReceitas.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Despesas'),
                    Text(
                      'R\$ ${_totalDespesas.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTransacao(Transacao t) {
    final isReceita = t.tipo == 'receita';
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _excluirTransacao(t);
        return false; // A lista é recarregada pelo _carregarDados.
      },
      child: Card(
        child: ListTile(
          onTap: () => _abrirFormulario(transacao: t),
          leading: Icon(
            isReceita ? Icons.arrow_upward : Icons.arrow_downward,
            color: isReceita ? Colors.green : Colors.red,
          ),
          title: Text(_nomesCategorias[t.categoriaId] ?? 'Categoria'),
          subtitle: Text(
            t.descricao?.isNotEmpty == true ? t.descricao! : t.data,
          ),
          trailing: Text(
            'R\$ ${t.valor.toStringAsFixed(2)}',
            style: TextStyle(
              color: isReceita ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarraFiltro() {
      return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              initialValue: _filtroCategoriaId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._todasCategorias.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.nome)),
                ),
              ],
              onChanged: (valor) {
                setState(() => _filtroCategoriaId = valor);
                _carregarDados();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filtrar por período',
            onPressed: _selecionarPeriodo,
          ),
          if (_filtroCategoriaId != null || _filtroPeriodo != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Limpar filtros',
              onPressed: _limparFiltros,
            ),
        ],
      );
    }
}