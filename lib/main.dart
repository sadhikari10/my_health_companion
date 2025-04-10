import 'package:flutter/material.dart';
import 'database.dart';  // Import DatabaseHelper here
import 'signin_page.dart';  // Import SignInPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;  // Use the DatabaseHelper here
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInPage(),
    );
  }
}

