import '../database/db_helper.dart';
import '../models/transacao.dart';

class TransacaoRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> criar(Transacao transacao) async {
    final db = await _dbHelper.database;
    return await db.insert('transacoes', transacao.toMap());
  }

  Future<List<Transacao>> listarPorUsuario(int usuarioId) async {
    final db = await _dbHelper.database;
    final resultado = await db.query(
      'transacoes',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'data DESC',
    );
    return resultado.map((map) => Transacao.fromMap(map)).toList();
  }

  Future<List<Transacao>> listarPorCategoria(int usuarioId, int categoriaId) async {
    final db = await _dbHelper.database;
    final resultado = await db.query(
      'transacoes',
      where: 'usuario_id = ? AND categoria_id = ?',
      whereArgs: [usuarioId, categoriaId],
      orderBy: 'data DESC',
    );
    return resultado.map((map) => Transacao.fromMap(map)).toList();
  }

  Future<List<Transacao>> listarPorPeriodo(
    int usuarioId,
    String dataInicio,
    String dataFim,
  ) async {
    final db = await _dbHelper.database;
    final resultado = await db.query(
      'transacoes',
      where: 'usuario_id = ? AND data BETWEEN ? AND ?',
      whereArgs: [usuarioId, dataInicio, dataFim],
      orderBy: 'data DESC',
    );
    return resultado.map((map) => Transacao.fromMap(map)).toList();
  }

  Future<int> atualizar(Transacao transacao) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transacoes',
      transacao.toMap(),
      where: 'id = ?',
      whereArgs: [transacao.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transacoes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> calcularSaldo(int usuarioId) async {
    final db = await _dbHelper.database;

    final receitas = await db.rawQuery(
      'SELECT SUM(valor) as total FROM transacoes WHERE usuario_id = ? AND tipo = ?',
      [usuarioId, 'receita'],
    );

    final despesas = await db.rawQuery(
      'SELECT SUM(valor) as total FROM transacoes WHERE usuario_id = ? AND tipo = ?',
      [usuarioId, 'despesa'],
    );

    final totalReceitas = (receitas.first['total'] as double?) ?? 0.0;
    final totalDespesas = (despesas.first['total'] as double?) ?? 0.0;

    return totalReceitas - totalDespesas;
  }

  Future<double> totalGastoPorCategoriaNoMes(
    int usuarioId,
    int categoriaId,
    String anoMes, 
  ) async {
    final db = await _dbHelper.database;
    final resultado = await db.rawQuery(
      '''SELECT SUM(valor) as total FROM transacoes
         WHERE usuario_id = ? AND categoria_id = ? AND tipo = 'despesa'
         AND data LIKE ?''',
      [usuarioId, categoriaId, '$anoMes%'],
    );
    return (resultado.first['total'] as double?) ?? 0.0;
  }

  Future<List<Transacao>> listarComFiltro({
    required int usuarioId,
    int? categoriaId,
    String? dataInicio,
    String? dataFim,
  }) async {
    final db = await _dbHelper.database;
    final condicoes = <String>['usuario_id = ?'];
    final args = <Object?>[usuarioId];

    if (categoriaId != null) {
      condicoes.add('categoria_id = ?');
      args.add(categoriaId);
    }
    if (dataInicio != null && dataFim != null) {
      condicoes.add('data BETWEEN ? AND ?');
      args.add(dataInicio);
      args.add(dataFim);
    }

    final resultado = await db.query(
      'transacoes',
      where: condicoes.join(' AND '),
      whereArgs: args,
      orderBy: 'data DESC',
    );
    return resultado.map((map) => Transacao.fromMap(map)).toList();
  }
}