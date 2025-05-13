import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'signup_page.dart';
import 'database.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Both email and password fields are required")),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email is required")),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password is required")),
      );
      return;
    }

    final user = await DatabaseHelper.instance.getUser(email);
    if (user != null && user['password'] == password) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage(user: user)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid Credentials")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show background
      extendBodyBehindAppBar: true, // Extend image under AppBar
      appBar: AppBar(
        title: Text("Sign In"),
        backgroundColor: Colors.blue.shade800.withOpacity(0.8), // Semi-transparent AppBar
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand, // Ensure Stack fills entire screen
        children: [
          // Fallback background color
          Container(
            color: Colors.blue.shade50, // Matches app theme
          ),
          // Background image
          Positioned.fill(
            child: Builder(
              builder: (context) {
                try {
                  return Image.asset(
                    'assets/images/sss.png',
                    fit: BoxFit.cover, // Fill entire screen, may crop
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    errorBuilder: (context, error, stackTrace) {
                      print('Asset loading error: $error\n$stackTrace');
                      return Container(
                        color: Colors.red,
                        child: Center(child: Text('Failed to load image')),
                      );
                    },
                  );
                } catch (e) {
                  print('Exception loading asset: $e');
                  return Container(
                    color: Colors.red,
                    child: Center(child: Text('Exception loading image')),
                  );
                }
              },
            ),
          ),
          // Semi-transparent overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3), // Adjust opacity
            ),
          ),
          // Content, ignoring SafeArea to use full screen
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: Text("Sign In"),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        "New User?",
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpPage()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: Text("Sign Up"),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      Text(
                        "Thriving Health, Vibrant Life Every Day",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}