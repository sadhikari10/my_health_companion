import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("users.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        contact_no TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');
  }

  Future<int> createUser(String firstName, String lastName, String email, String contactNo, String password) async {
    final db = await database;
    return await db.insert('users', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'contact_no': contactNo,
      'password': password
    });
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty ? res.first : null;
  }
}
