import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database.dart';
import 'signin_page.dart';

Future<void> initializeDatabase() async {
  // Initialize databaseFactory for sqflite_common_ffi
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.instance.database;
  print('Database initialized in isolate');
}

void main() async {
  // Initialize sqflite_common_ffi for non-isolate context
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await compute((_) => initializeDatabase(), null);
    print('Database initialization completed');
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print(stackTrace);
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      DatabaseHelper.instance.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInPage(),
    );
  }
}