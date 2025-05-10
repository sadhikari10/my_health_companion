import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

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
      print('Database initialization completed successfully');
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

  Future<int> insertMedicationInfo(
    int userId,
    String diseaseName,
    String medicationName,
    String dosage,
    String? startDate,
    String? endDate,
    String? prescriber,
  ) async {
    print('Inserting medication info: $medicationName for user ID: $userId');
    final db = await database;
    try {
      final id = await db.insert('user_medication_info', {
        'user_id': userId,
        'disease_name': diseaseName,
        'medication_name': medicationName,
        'dosage': dosage,
        'start_date': startDate,
        'end_date': endDate,
        'prescriber': prescriber,
      });
      print('Medication info inserted with ID: $id');
      // Initialize doses for the current day
      final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await initializeDailyDoses(userId, currentDate, medicationName: medicationName);
      print('Initialized daily doses for $medicationName on $currentDate');
      return id;
    } catch (e, stackTrace) {
      print('Error inserting medication info: $e');
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

  Future<void> deleteMedicationInfo(int id) async {
    print('Deleting medication info ID: $id');
    final db = await database;
    try {
      final meds = await db.query(
        'user_medication_info',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (meds.isEmpty) {
        print('No medication found with ID: $id');
        return;
      }
      final medicationName = meds.first['medication_name'] as String;
      final userId = meds.first['user_id'] as int;
      final diseaseName = meds.first['disease_name'] as String;

      await db.delete(
        'medication_logs',
        where: 'user_id = ? AND medicine_name = ?',
        whereArgs: [userId, medicationName],
      );
      print('Deleted medication logs for $medicationName');

      await db.delete(
        'medication_reminders',
        where: 'user_id = ? AND disease_name = ?',
        whereArgs: [userId, diseaseName],
      );
      print('Deleted medication reminders for $diseaseName');

      await db.delete(
        'user_medication_info',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Medication info deleted successfully for ID: $id');
    } catch (e, stackTrace) {
      print('Error deleting medication info: $e');
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
      print('Fetched ${results.length} medications: $results');
      return results;
    } catch (e, stackTrace) {
      print('Error fetching user medications: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> insertMedicationLog(Map<String, dynamic> log) async {
    print('Processing medication log for: ${log['medicine_name']}');
    final db = await database;
    final userId = log['user_id'] as int;
    final medicineName = log['medicine_name'] as String;
    final logDate = log['log_date'] as String;
    final logTime = log['log_time'] as String;
    final logDay = log['log_day'] as String;

    try {
      final remainingDoses = await getRemainingDoses(userId, medicineName, logDate);
      if (remainingDoses == 0) {
        print('All doses already taken for $medicineName on $logDate');
        throw Exception('All doses already taken for today');
      }

      final untakenLogs = await db.query(
        'medication_logs',
        where: 'user_id = ? AND medicine_name = ? AND log_date = ? AND taken = ?',
        whereArgs: [userId, medicineName, logDate, 0],
        orderBy: 'id ASC',
        limit: 1,
      );

      if (untakenLogs.isNotEmpty) {
        final logId = untakenLogs.first['id'] as int;
        await db.update(
          'medication_logs',
          {
            'taken': 1,
            'log_time': logTime,
            'log_day': logDay,
          },
          where: 'id = ?',
          whereArgs: [logId],
        );
        print('Updated medication log ID $logId to taken for $medicineName on $logDate at $logTime');
      } else {
        await db.insert('medication_logs', {
          'user_id': userId,
          'medicine_name': medicineName,
          'taken': 1,
          'log_date': logDate,
          'log_time': logTime,
          'log_day': logDay,
        });
        print('Inserted new taken log for $medicineName on $logDate at $logTime (fallback)');
      }
    } catch (e, stackTrace) {
      print('Error processing medication log: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<int> getRemainingDoses(int userId, String medicineName, String logDate) async {
    print('Checking remaining doses for user ID: $userId, medicine: $medicineName, date: $logDate');
    final db = await database;
    try {
      final meds = await db.query(
        'user_medication_info',
        where: 'user_id = ? AND medication_name = ?',
        whereArgs: [userId, medicineName],
      );
      if (meds.isEmpty) {
        print('No medication found for $medicineName');
        return 0;
      }
      final dosage = meds.first['dosage'] as String;
      final dailyDosage = await parseDailyDosage(dosage);

      final takenLogs = await db.query(
        'medication_logs',
        where: 'user_id = ? AND medicine_name = ? AND log_date = ? AND taken = ?',
        whereArgs: [userId, medicineName, logDate, 1],
      );
      print('Found ${takenLogs.length} taken logs for $medicineName on $logDate');
      return dailyDosage - takenLogs.length;
    } catch (e, stackTrace) {
      print('Error checking remaining doses: $e');
      print(stackTrace);
      return 0;
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
    final startDate = startTime.toIso8601String().substring(0, 10);
    try {
      final results = await db.rawQuery('''
        SELECT ml.id, ml.medicine_name, ml.taken, ml.log_date, ml.log_time, ml.log_day, umi.disease_name
        FROM medication_logs ml
        INNER JOIN user_medication_info umi ON ml.medicine_name = umi.medication_name
        WHERE ml.user_id = ? AND ml.log_date >= ?
        ORDER BY ml.log_date DESC, ml.log_time DESC
      ''', [userId, startDate]);
      print('Fetched ${results.length} medication logs with diseases: $results');
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
      await db.insert('medication_reminders', reminder);
      print('Medication reminder inserted successfully');
    } catch (e, stackTrace) {
      print('Error inserting medication reminder: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> deleteMedicationReminder(int id) async {
    print('Deleting medication reminder ID: $id');
    final db = await database;
    try {
      await db.delete(
        'medication_reminders',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Medication reminder deleted successfully');
    } catch (e, stackTrace) {
      print('Error deleting medication reminder: $e');
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

  Future<int> getDailyLogCount(int userId, String medicineName, String logDate) async {
    print('Counting logs for user ID: $userId, medicine: $medicineName, date: $logDate');
    final db = await database;
    try {
      final results = await db.query(
        'medication_logs',
        where: 'user_id = ? AND medicine_name = ? AND log_date = ? AND taken = ?',
        whereArgs: [userId, medicineName, logDate, 1],
      );
      print('Found ${results.length} taken logs: $results');
      return results.length;
    } catch (e, stackTrace) {
      print('Error counting daily logs: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<int> parseDailyDosage(String dosage) async {
    print('Parsing dosage: $dosage');
    try {
      final dosageLower = dosage.toLowerCase().trim();
      if (RegExp(r'^\d+$').hasMatch(dosageLower)) {
        final count = int.parse(dosageLower);
        print('Parsed numeric-only dosage: $count times daily');
        return count;
      }
      final numericRegex = RegExp(r'(\d+)\s*(times|time)\s*(daily|per day)', caseSensitive: false);
      final numericMatch = numericRegex.firstMatch(dosageLower);
      if (numericMatch != null) {
        final count = int.parse(numericMatch.group(1)!);
        print('Parsed numeric dosage: $count times daily');
        return count;
      }
      if (dosageLower.contains('twice')) {
        print('Parsed textual dosage: 2 times daily');
        return 2;
      }
      if (dosageLower.contains('thrice')) {
        print('Parsed textual dosage: 3 times daily');
        return 3;
      }
      print('Defaulting to 1 dose per day');
      return 1;
    } catch (e, stackTrace) {
      print('Error parsing dosage: $e');
      print(stackTrace);
      return 1;
    }
  }

  Future<void> initializeDailyDoses(int userId, String logDate, {String? medicationName}) async {
    print('Initializing daily doses for user ID: $userId on $logDate${medicationName != null ? ' for $medicationName' : ''}');
    final db = await database;
    try {
      final medications = medicationName != null
          ? await db.query(
              'user_medication_info',
              where: 'user_id = ? AND medication_name = ?',
              whereArgs: [userId, medicationName],
            )
          : await getUserMedications(userId);

      for (var med in medications) {
        final medName = med['medication_name'] as String;
        final dosage = med['dosage'] as String;
        final dailyDosage = await parseDailyDosage(dosage);

        // Check if doses are already initialized for this medication and date
        final existingLogs = await db.query(
          'medication_logs',
          where: 'user_id = ? AND medicine_name = ? AND log_date = ?',
          whereArgs: [userId, medName, logDate],
        );
        if (existingLogs.length >= dailyDosage) {
          print('Doses already initialized for $medName on $logDate (${existingLogs.length} logs found)');
          continue;
        }

        // Insert remaining doses
        final dosesToInsert = dailyDosage - existingLogs.length;
        print('Initializing $dosesToInsert doses for $medName on $logDate');
        for (var i = 0; i < dosesToInsert; i++) {
          final log = {
            'user_id': userId,
            'medicine_name': medName,
            'taken': 0,
            'log_date': logDate,
            'log_time': '00:00',
            'log_day': DateFormat('EEEE').format(DateTime.parse(logDate)),
          };
          await db.insert('medication_logs', log);
          print('Inserted untaken dose ${i + 1} for $medName on $logDate');
        }
      }
    } catch (e, stackTrace) {
      print('Error initializing daily doses: $e');
      print(stackTrace);
      rethrow;
    }
  }
}