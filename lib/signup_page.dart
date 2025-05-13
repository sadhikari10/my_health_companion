import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'signin_page.dart';
import 'database.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _agreedToTnC = false;

  bool _passwordVisible = false;
  File? _profileImage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _signUp() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String contact = _contactController.text.trim();
    String password = _passwordController.text;

    List<String> emptyFields = [];

    if (firstName.isEmpty) emptyFields.add("First Name");
    if (lastName.isEmpty) emptyFields.add("Last Name");
    if (email.isEmpty) emptyFields.add("Email");
    if (contact.isEmpty) emptyFields.add("Contact No");
    if (password.isEmpty) emptyFields.add("Password");

    if (emptyFields.length > 1) {
      _showMessage("More than one empty field detected");
      return;
    } else if (emptyFields.length == 1) {
      _showMessage("${emptyFields[0]} cannot be empty");
      return;
    }
    if (!_agreedToTnC) {
      _showMessage("Please agree to the Terms and Conditions.");
      return;
    }

    // Regex validations
    final nameRegExp = RegExp(r'^[a-zA-Z]+$');
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegExp = RegExp(r'^\d+$');
    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W).{8,}$');

    if (!nameRegExp.hasMatch(firstName)) {
      _showMessage("First Name can contain alphabets only");
      return;
    }

    if (!nameRegExp.hasMatch(lastName)) {
      _showMessage("Last Name can contain alphabets only");
      return;
    }

    if (!emailRegExp.hasMatch(email)) {
      _showMessage("Invalid email format");
      return;
    }

    if (!phoneRegExp.hasMatch(contact)) {
      _showMessage("Contact No must contain digits only");
      return;
    }

    if (!passwordRegExp.hasMatch(password)) {
      _showMessage("Password must be at least 8 characters long with 1 uppercase, 1 lowercase, and 1 special character");
      return;
    }

    // All validations passed
    try {
      await DatabaseHelper.instance.createUser(
        firstName,
        lastName,
        email,
        contact,
        password,
        _profileImage?.path,
      );

      _showMessage("User Registered");

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed: users.email')) {
        _showMessage("User with the provided email already exists");
      } else {
        _showMessage("Something went wrong. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show background
      extendBodyBehindAppBar: true, // Extend image under AppBar
      appBar: AppBar(
        title: Text("Sign Up"),
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
          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // First Name
                    _buildTextBox(_firstNameController, "First Name"),
                    SizedBox(height: 16),
                    // Last Name
                    _buildTextBox(_lastNameController, "Last Name"),
                    SizedBox(height: 16),
                    // Email
                    _buildTextBox(_emailController, "Email"),
                    SizedBox(height: 16),
                    // Contact No
                    _buildTextBox(_contactController, "Contact No"),
                    SizedBox(height: 16),
                    // Password
                    _buildTextBox(_passwordController, "Password", obscureText: true),
                    SizedBox(height: 20),
                    // Profile Picture
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        children: [
                          _profileImage != null
                              ? CircleAvatar(
                                  radius: 30,
                                  backgroundImage: FileImage(_profileImage!),
                                )
                              : CircleAvatar(
                                  radius: 30,
                                  child: Icon(Icons.person),
                                ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextButton(
                              onPressed: _pickImage,
                              child: Text("Choose Profile Picture"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _agreedToTnC,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTnC = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showTermsandConditions(context),
                              child: Text(
                                "I Agree to Terms and Conditions",
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: Text("Sign Up"),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Already have an account?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignInPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: Text("Sign In"),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      "Thriving Health, Vibrant Life Every Day",
                      textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  Widget _buildTextBox(TextEditingController controller, String label, {bool obscureText = false}) {
    bool isPasswordField = label.toLowerCase() == "password";
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPasswordField ? !_passwordVisible : obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showTermsandConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Terms and Conditions"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("1. You agree not to misuse the app."),
                SizedBox(height: 8),
                Text("2. The app stores your personal information"),
                SizedBox(height: 8),
                Text("3. Your password will be encrypted and only known to you."),
                SizedBox(height: 8),
                Text("4. This app is meant for personal health tracking, so your disease information will be stored in the app's database."),
                SizedBox(height: 8),
                Text("5. By using this app, you consent to the terms mentioned above."),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}