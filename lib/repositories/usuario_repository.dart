import '../database/db_helper.dart';
import '../models/usuario.dart';
import '../utils/senha_utils.dart';

class UsuarioRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> cadastrar(Usuario usuario) async {
    final db = await _dbHelper.database;

    final usuarioComHash = Usuario(
      nome: usuario.nome,
      email: usuario.email,
      senha: SenhaUtils.gerarHash(usuario.senha),
    );

    return await db.insert('usuarios', usuarioComHash.toMap());
  }

  Future<Usuario?> buscarPorEmail(String email) async {
    final db = await _dbHelper.database;

    final resultado = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (resultado.isEmpty) return null;
    return Usuario.fromMap(resultado.first);
  }

  Future<Usuario?> login(String email, String senha) async {
    final usuario = await buscarPorEmail(email);

    if (usuario == null) return null;

    final hashDigitado = SenhaUtils.gerarHash(senha);
    if (usuario.senha != hashDigitado) return null;

    return usuario;
  }

  Future<Usuario?> buscarPorId(int id) async {
    final db = await _dbHelper.database;
    final resultado = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (resultado.isEmpty) return null;
    return Usuario.fromMap(resultado.first);
  }
}