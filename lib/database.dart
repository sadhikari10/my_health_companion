import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isInitializing = false;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      print('Returning cached database');
      return _database!;
    }
    if (_isInitializing) {
      print('Database initialization in progress, waiting...');
      try {
        return await _waitForDatabase().timeout(Duration(seconds: 30), onTimeout: () {
          throw TimeoutException('Database initialization timed out after 30 seconds');
        });
      } catch (e, stackTrace) {
        print('Error waiting for database: $e');
        print(stackTrace);
        rethrow;
      }
    }
    print('Initializing database...');
    _isInitializing = true;
    try {
      _database = await _initDB("users.db");
      print('Database initialized');
      return _database!;
    } catch (e, stackTrace) {
      print('Error initializing database: $e');
      print(stackTrace);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<Database> _waitForDatabase() async {
    while (_isInitializing) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    if (_database == null) {
      throw StateError('Database is null after initialization completed');
    }
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    print('Opening database at: $path');
    try {
      final database = await openDatabase(
        path,
        version: 7,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      ).timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Database opening timed out');
      });
      print('Database opened successfully');
      await insertPredefinedDiseases(database).timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Inserting predefined diseases timed out');
      });
      return database;
    } catch (e, stackTrace) {
      print('Error opening database: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    print('Creating database tables...');
    try {
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
      await db.execute('''
        CREATE TABLE medication_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          medicine_name TEXT NOT NULL,
          taken INTEGER NOT NULL,
          log_date TEXT NOT NULL,
          log_time TEXT NOT NULL,
          log_day TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE appointments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          appointment_type TEXT NOT NULL,
          appointment_date TEXT NOT NULL,
          appointment_time TEXT NOT NULL,
          appointment_day TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE medication_reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          disease_name TEXT NOT NULL,
          reminder_time TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');
      print('Tables created successfully');
    } catch (e, stackTrace) {
      print('Error creating tables: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    try {
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
      if (oldVersion < 4) {
        await db.execute('''
          CREATE TABLE medication_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            medicine_name TEXT NOT NULL,
            taken INTEGER NOT NULL,
            log_date TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
      }
      if (oldVersion < 5) {
        await db.execute('ALTER TABLE medication_logs ADD COLUMN log_time TEXT NOT NULL DEFAULT ""');
        await db.execute('ALTER TABLE medication_logs ADD COLUMN log_day TEXT NOT NULL DEFAULT ""');
      }
      if (oldVersion < 6) {
        await db.execute('''
          CREATE TABLE appointments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            appointment_type TEXT NOT NULL,
            appointment_date TEXT NOT NULL,
            appointment_time TEXT NOT NULL,
            appointment_day TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
      }
      if (oldVersion < 7) {
        await db.execute('''
          CREATE TABLE medication_reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            disease_name TEXT NOT NULL,
            reminder_time TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
      }
      print('Database upgraded successfully');
    } catch (e, stackTrace) {
      print('Error upgrading database: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> insertPredefinedDiseases(Database db) async {
    print('Checking for existing diseases');
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM diseases'));
    print('Disease count: $count');
    if (count != null && count > 0) {
      print('Predefined diseases already exist, skipping insertion');
      return;
    }

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
    print('Inserting ${diseases.length} predefined diseases');
    try {
      const chunkSize = 5;
      for (var i = 0; i < diseases.length; i += chunkSize) {
        final batch = db.batch();
        final end = (i + chunkSize < diseases.length) ? i + chunkSize : diseases.length;
        for (var j = i; j < end; j++) {
          batch.insert('diseases', diseases[j]);
        }
        await batch.commit(noResult: true);
        print('Inserted batch ${i ~/ chunkSize + 1}');
      }
      print('Predefined diseases inserted successfully');
    } catch (e, stackTrace) {
      print('Error inserting predefined diseases: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('Database closed');
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
    print('Creating user: $email');
    final db = await database;
    print('Database ready for user creation');
    try {
      final id = await db.insert('users', {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'contact_no': contactNo,
        'password': password,
        'profile_image': profileImagePath,
      });
      print('User created with ID: $id');
      return id;
    } catch (e, stackTrace) {
      print('Error creating user: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    print('Fetching user: $email');
    final db = await database;
    try {
      final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
      print('User fetch result: ${res.isNotEmpty ? res.first : null}');
      return res.isNotEmpty ? res.first : null;
    } catch (e, stackTrace) {
      print('Error getting user: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    print('Fetching user by ID: $id');
    final db = await database;
    try {
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('User fetch result: ${results.isNotEmpty ? results.first : null}');
      return results.isNotEmpty ? results.first : null;
    } catch (e, stackTrace) {
      print('Error getting user by ID: $e');
      print(stackTrace);
      rethrow;
    }
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
    print('Updating user ID: $id');
    final db = await database;
    try {
      final result = await db.update(
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
      print('User update result: $result');
      return result;
    } catch (e, stackTrace) {
      print('Error updating user: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> insertDisease(String name, String category) async {
    print('Inserting disease: $name');
    final db = await database;
    try {
      await db.insert('diseases', {
        'name': name,
        'category': category,
      });
      print('Disease inserted: $name');
    } catch (e, stackTrace) {
      print('Error inserting disease: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllDiseases() async {
    print('Fetching all diseases');
    final db = await database;
    try {
      final results = await db.query('diseases');
      print('Fetched ${results.length} diseases');
      return results;
    } catch (e, stackTrace) {
      print('Error getting all diseases: $e');
      print(stackTrace);
      rethrow;
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
    print('Updating medication info ID: $id');
    final db = await database;
    try {
      final result = await db.update(
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
      print('Medication update result: $result');
      return result;
    } catch (e, stackTrace) {
      print('Error updating medication info: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserMedications(int userId) async {
    print('Fetching medications for user ID: $userId');
    final db = await database;
    try {
      final results = await db.query(
        'user_medication_info',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print('Fetched ${results.length} medications');
      return results;
    } catch (e, stackTrace) {
      print('Error fetching user medications: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> insertMedicationLog(Map<String, dynamic> log) async {
    print('Inserting medication log: ${log['medicine_name']}');
    final db = await database;
    try {
      await db.insert('medication_logs', log);
      print('Medication log inserted successfully');
    } catch (e, stackTrace) {
      print('Error inserting medication log: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMedicationLogs(int userId) async {
    print('Fetching medication logs for user ID: $userId');
    final db = await database;
    try {
      final results = await db.query(
        'medication_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'log_date DESC, log_time DESC',
      );
      print('Fetched ${results.length} medication logs');
      return results;
    } catch (e, stackTrace) {
      print('Error fetching medication logs: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> deleteMedicationLog(int id) async {
    print('Deleting medication log ID: $id');
    final db = await database;
    try {
      await db.delete(
        'medication_logs',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Medication log deleted successfully');
    } catch (e, stackTrace) {
      print('Error deleting medication log: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> insertAppointment(Map<String, dynamic> appointment) async {
    print('Inserting appointment: ${appointment['appointment_type']}');
    final db = await database;
    try {
      await db.insert('appointments', appointment);
      print('Appointment inserted successfully');
    } catch (e, stackTrace) {
      print('Error inserting appointment: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments(int userId) async {
    print('Fetching appointments for user ID: $userId');
    final db = await database;
    try {
      final results = await db.query(
        'appointments',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'appointment_date DESC',
      );
      print('Fetched ${results.length} appointments');
      return results;
    } catch (e, stackTrace) {
      print('Error fetching appointments: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAppointment(int id) async {
    print('Deleting appointment ID: $id');
    final db = await database;
    try {
      await db.delete(
        'appointments',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Appointment deleted successfully');
    } catch (e, stackTrace) {
      print('Error deleting appointment: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMedicationLogsWithDiseases(int userId, DateTime startTime) async {
    print('Fetching medication logs with diseases for user ID: $userId from $startTime');
    final db = await database;
    final startDate = startTime.toIso8601String().substring(0, 10); // YYYY-MM-DD
    try {
      final results = await db.rawQuery('''
        SELECT ml.id, ml.medicine_name, ml.taken, ml.log_date, ml.log_time, ml.log_day, umi.disease_name
        FROM medication_logs ml
        INNER JOIN user_medication_info umi ON ml.medicine_name = umi.medication_name
        WHERE ml.user_id = ? AND ml.log_date >= ?
        ORDER BY ml.log_date DESC, ml.log_time DESC
      ''', [userId, startDate]);
      print('Fetched ${results.length} medication logs with diseases');
      return results;
    } catch (e, stackTrace) {
      print('Error fetching medication logs with diseases: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> insertMedicationReminder(Map<String, dynamic> reminder) async {
    print('Inserting medication reminder for disease: ${reminder['disease_name']}');
    final db = await database;
    try {
      // Update or insert reminder (replace if exists)
      await db.delete(
        'medication_reminders',
        where: 'user_id = ? AND disease_name = ?',
        whereArgs: [reminder['user_id'], reminder['disease_name']],
      );
      await db.insert('medication_reminders', reminder);
      print('Medication reminder inserted successfully');
    } catch (e, stackTrace) {
      print('Error inserting medication reminder: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMedicationReminders(int userId) async {
    print('Fetching medication reminders for user ID: $userId');
    final db = await database;
    try {
      final results = await db.query(
        'medication_reminders',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print('Fetched ${results.length} medication reminders');
      return results;
    } catch (e, stackTrace) {
      print('Error fetching medication reminders: $e');
      print(stackTrace);
      rethrow;
    }
  }
}