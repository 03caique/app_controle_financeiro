import '../database/db_helper.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> criar(Categoria categoria) async {
    final db = await _dbHelper.database;
    return await db.insert('categorias', categoria.toMap());
  }

  Future<List<Categoria>> listarTodas() async {
    final db = await _dbHelper.database;
    final resultado = await db.query('categorias');
    return resultado.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<List<Categoria>> listarPorTipo(String tipo) async {
    final db = await _dbHelper.database;
    final resultado = await db.query(
      'categorias',
      where: 'tipo = ?',
      whereArgs: [tipo],
    );
    return resultado.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<int> atualizar(Categoria categoria) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categorias',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}