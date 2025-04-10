import 'package:flutter/material.dart';
import 'dashboard.dart'; // Import DashboardPage
import 'signup_page.dart'; // Import SignUpPage
import 'database.dart'; // Import DatabaseHelper

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    final user = await DatabaseHelper.instance.getUser(_emailController.text);
    if (user != null && user['password'] == _passwordController.text) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage(user: user)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid Credentials")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In")),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade100, Colors.blue.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email")),
                TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
                SizedBox(height: 20),
                ElevatedButton(onPressed: _signIn, child: Text("Sign In")),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage())), child: Text("New User? Sign Up")),
                SizedBox(height: 40),
                Text("Thriving Health, Vibrant Life Every Day", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
