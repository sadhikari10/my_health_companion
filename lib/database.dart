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
    final database = await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
    await insertPredefinedDiseases(); // Ensure predefined diseases are inserted
    return database;
  }

  Future _createDB(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        contact_no TEXT NOT NULL,
        password TEXT NOT NULL,
        profile_image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE diseases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_medication_info(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        disease_name TEXT NOT NULL,
        medication_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        prescriber TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN profile_image TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS user_medication_info');
      await db.execute('''
        CREATE TABLE user_medication_info(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          disease_name TEXT NOT NULL,
          medication_name TEXT NOT NULL,
          dosage TEXT NOT NULL,
          start_date TEXT,
          end_date TEXT,
          prescriber TEXT,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');
    }
  }

  Future<int> createUser(
    String firstName,
    String lastName,
    String email,
    String contactNo,
    String password,
    String? profileImagePath,
  ) async {
    final db = await database;
    return await db.insert('users', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'contact_no': contactNo,
      'password': password,
      'profile_image': profileImagePath
    });
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(
    int id,
    String firstName,
    String lastName,
    String email,
    String contactNo,
    String password,
    String? profileImagePath,
  ) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'contact_no': contactNo,
        'password': password,
        'profile_image': profileImagePath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertDisease(String name, String category) async {
    final db = await database;
    await db.insert('diseases', {
      'name': name,
      'category': category,
    });
  }

  Future<List<Map<String, dynamic>>> getAllDiseases() async {
    final db = await database;
    return await db.query('diseases');
  }

  Future<void> insertPredefinedDiseases() async {
    final db = await database;
    final List<Map<String, String>> diseases = [
      {'name': 'Red green colour blindness', 'category': 'Inherited Disease'},
      {'name': 'Webbed toes', 'category': 'Inherited Disease'},
      {'name': 'Porcupine man', 'category': 'Inherited Disease'},
      {'name': 'Wilson disease', 'category': 'Inherited Disease'},
      {'name': 'Cholera', 'category': 'Acute Infectious'},
      {'name': 'Hepatitis A', 'category': 'Acute Infectious'},
      {'name': 'Burns', 'category': 'Acute Non Infectious'},
      {'name': 'Cardiac attack', 'category': 'Acute Non Infectious'},
      {'name': 'Tuberculosis', 'category': 'Chronic Infectious'},
      {'name': 'Leprosy', 'category': 'Chronic Infectious'},
      {'name': 'Cancer', 'category': 'Chronic Non Infectious'},
      {'name': 'Arthritis', 'category': 'Chronic Non Infectious'},
      {'name': 'Hypertension', 'category': 'Chronic Non Infectious'},
      {'name': 'Diabetes mellitus', 'category': 'Chronic Non Infectious'},
      {'name': 'Vitamin A deficiency', 'category': 'Vitamin Deficiency'},
      {'name': 'Vitamin B12 deficiency', 'category': 'Vitamin Deficiency'},
      {'name': 'Vitamin C deficiency', 'category': 'Vitamin Deficiency'},
      {'name': 'Vitamin D deficiency', 'category': 'Vitamin Deficiency'},
      {'name': 'Vitamin E deficiency', 'category': 'Vitamin Deficiency'},
      {'name': 'Vitamin K deficiency', 'category': 'Vitamin Deficiency'},
      {'name': 'Iron deficiency', 'category': 'Minerals Deficiency'},
      {'name': 'Calcium deficiency', 'category': 'Minerals Deficiency'},
      {'name': 'Magnesium deficiency', 'category': 'Minerals Deficiency'},
      {'name': 'Zinc deficiency', 'category': 'Minerals Deficiency'},
      {'name': 'Iodine deficiency', 'category': 'Minerals Deficiency'},
    ];

    for (var disease in diseases) {
      await db.insert('diseases', disease);
    }
  }

  Future<int> updateMedicationInfo(
    int id,
    String diseaseName,
    String medicationName,
    String dosage,
    String? startDate,
    String? endDate,
    String? prescriber,
  ) async {
    final db = await database;
    return await db.update(
      'user_medication_info',
      {
        'disease_name': diseaseName,
        'medication_name': medicationName,
        'dosage': dosage,
        'start_date': startDate,
        'end_date': endDate,
        'prescriber': prescriber,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}