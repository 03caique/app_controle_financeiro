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
import '../../theme/app_theme.dart';

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
  double _gastoCategoriaFiltrada = 0;

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

    final mapaCategorias = {for (final c in categorias) c.id!: c.nome};

    double gastoCategoriaFiltrada = 0;
    if (_filtroCategoriaId != null) {
      final agora = DateTime.now();
      final anoMes = '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
      gastoCategoriaFiltrada = await _transacaoRepository
          .totalGastoPorCategoriaNoMes(
            widget.usuario.id!,
            _filtroCategoriaId!,
            anoMes,
          );
    }

    if (!mounted) return;
    setState(() {
      _saldo = saldo;
      _totalReceitas = totalReceitas;
      _totalDespesas = totalDespesas;
      _transacoes = transacoes;
      _nomesCategorias = mapaCategorias;
      _gastoCategoriaFiltrada = gastoCategoriaFiltrada;
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

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brass, // Data selecionada
              onPrimary: Colors.white, // Texto da data selecionada
              surface: AppColors.parchment, // Fundo do calendário
              onSurface: AppColors.inkNavy, // Texto normal
            ),
            scaffoldBackgroundColor: AppColors.parchment,
            dialogBackgroundColor: AppColors.parchment,

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brass,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.inkNavy,
              foregroundColor: AppColors.parchment,
              elevation: 0,
            ),
          ),
          child: child!,
        );
      },
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
              MaterialPageRoute(
                builder: (_) => CategoriasScreen(usuarioId: widget.usuario.id!),
              ),
            ).then((_) => _carregarDados()),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brass),
            )
          : RefreshIndicator(
              onRefresh: _carregarDados,
              color: AppColors.brass,
              backgroundColor: AppColors.parchment,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBlocoFiltro(),
                  const SizedBox(height: 16),
                  _buildCardSaldo(),
                  const SizedBox(height: 28),
                  Text(
                    'ÚLTIMAS TRANSAÇÕES',
                    style: AppTypography.eyebrow.copyWith(
                      color: AppColors.parchment,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_transacoes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Nenhuma transação registrada.',
                          style: TextStyle(
                            color: AppColors.parchment.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._transacoes.map(_buildItemTransacao),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppColors.brass,
        foregroundColor: AppColors.inkNavy,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Wrapper "página de livro-caixa" usado pelos blocos de filtro, saldo
  /// e limite — mantém a identidade visual consistente com login/cadastro.
  Widget _parchmentBlock({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBlocoFiltro() {
    return _parchmentBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBarraFiltro(),
          if (_filtroCategoriaId != null) ...[
            const SizedBox(height: 12),
            const LedgerRule(ticks: 20),
            const SizedBox(height: 12),
            _buildCardLimiteCategoria(),
          ],
        ],
      ),
    );
  }

  Widget _buildCardSaldo() {
    final corSaldo = _saldo >= 0 ? AppColors.emerald : AppColors.brick;

    return _parchmentBlock(
      child: Column(
        children: [
          Text('SALDO DISPONÍVEL', style: AppTypography.eyebrow),
          const SizedBox(height: 8),
          Text(
            'R\$ ${_saldo.toStringAsFixed(2)}',
            style: AppTypography.amount(fontSize: 30, color: corSaldo),
          ),
          const SizedBox(height: 18),
          const LedgerRule(ticks: 24),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('RECEITAS', style: AppTypography.eyebrow),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${_totalReceitas.toStringAsFixed(2)}',
                    style: AppTypography.amount(
                      fontSize: 16,
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text('DESPESAS', style: AppTypography.eyebrow),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${_totalDespesas.toStringAsFixed(2)}',
                    style: AppTypography.amount(
                      fontSize: 16,
                      color: AppColors.brick,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemTransacao(Transacao t) {
    final isReceita = t.tipo == 'receita';
    final cor = isReceita ? AppColors.emerald : AppColors.brick;

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.brick,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.parchment),
      ),
      confirmDismiss: (_) async {
        await _excluirTransacao(t);
        return false; // A lista é recarregada pelo _carregarDados.
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          onTap: () => _abrirFormulario(transacao: t),
          leading: Icon(
            isReceita ? Icons.arrow_upward : Icons.arrow_downward,
            color: cor,
          ),
          title: Text(
            _nomesCategorias[t.categoriaId] ?? 'Categoria',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            t.descricao?.isNotEmpty == true ? t.descricao! : t.data,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Text(
            'R\$ ${t.valor.toStringAsFixed(2)}',
            style: AppTypography.amount(fontSize: 15, color: cor),
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
            decoration: const InputDecoration(labelText: 'CATEGORIA'),
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
          icon: const Icon(Icons.date_range, color: AppColors.brass),
          tooltip: 'Filtrar por período',
          onPressed: _selecionarPeriodo,
        ),
        if (_filtroCategoriaId != null || _filtroPeriodo != null)
          IconButton(
            icon: const Icon(Icons.filter_alt_off, color: AppColors.mutedInk),
            tooltip: 'Limpar filtros',
            onPressed: _limparFiltros,
          ),
      ],
    );
  }

  Widget _buildCardLimiteCategoria() {
    final categoria = _todasCategorias.firstWhere(
      (c) => c.id == _filtroCategoriaId,
      orElse: () => Categoria(nome: '', tipo: 'despesa'),
    );

    if (categoria.limite == null || categoria.limite! <= 0) {
      return Text(
        'Esta categoria não tem limite definido.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final limite = categoria.limite!;
    final gasto = _gastoCategoriaFiltrada;
    final proporcao = (gasto / limite).clamp(0.0, 1.0);
    final estourou = gasto > limite;
    final cor = estourou ? AppColors.brick : AppColors.brass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIMITE MENSAL · ${categoria.nome.toUpperCase()}',
          style: AppTypography.eyebrow,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: proporcao,
            minHeight: 8,
            backgroundColor: AppColors.mutedInk.withValues(alpha: 0.2),
            color: cor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'R\$ ${gasto.toStringAsFixed(2)} de R\$ ${limite.toStringAsFixed(2)}'
          '${estourou ? '  •  Limite ultrapassado!' : ''}',
          style: AppTypography.amount(fontSize: 13, color: cor),
        ),
      ],
    );
  }
}
