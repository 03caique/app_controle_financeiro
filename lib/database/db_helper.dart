import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'controle_financeiro.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        limite REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE transacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        categoria_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        descricao TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
        FOREIGN KEY (categoria_id) REFERENCES categorias (id)
      )
    ''');

    await _seedCategorias(db);
  }

  Future<void> _seedCategorias(Database db) async {
    final categoriasPadrao = [
      {'nome': 'Salário', 'tipo': 'receita', 'limite': null},
      {'nome': 'Outras Receitas', 'tipo': 'receita', 'limite': null},
      {'nome': 'Alimentação', 'tipo': 'despesa', 'limite': null},
      {'nome': 'Transporte', 'tipo': 'despesa', 'limite': null},
      {'nome': 'Moradia', 'tipo': 'despesa', 'limite': null},
      {'nome': 'Lazer', 'tipo': 'despesa', 'limite': null},
      {'nome': 'Saúde', 'tipo': 'despesa', 'limite': null},
      {'nome': 'Outros', 'tipo': 'despesa', 'limite': null},
    ];

    for (final categoria in categoriasPadrao) {
      await db.insert('categorias', categoria);
    }
  }
}