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
  File? _profileImage;

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
  if(!_agreedToTnC)
  {
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
    _showMessage("User with the provided email already exsits");
  } else {
    _showMessage("Something went wrong. Please try again.");
  }
}

}



 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text("Sign Up")),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //SizedBox(height: 10),
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

              // Profile Picture (after password)
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                padding: EdgeInsets.symmetric(horizontal:20),
                child: Row(
                  children:[
                    Checkbox(
                      value: 
                      _agreedToTnC,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTnC = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text("I Agree to Terms and Conditions"),
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
                    child: Text("Sign Up"),
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text(
  "Already have an account?",
  textAlign: TextAlign.center,
  style: TextStyle(color: Colors.black87),
),
SizedBox(height: 8),
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignInPage()),
    );
  },
  child: Text("Sign In"),
),
            ],
          ),
        ),
      ),
    ),
  );
}


Widget _buildTextBox(TextEditingController controller, String label, {bool obscureText = false}) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    padding: EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey),
    ),
    child: TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
      ),
    ),
  );
}
void _showMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
}