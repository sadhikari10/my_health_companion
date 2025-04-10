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
    await DatabaseHelper.instance.createUser(
      _firstNameController.text,
      _lastNameController.text,
      _emailController.text,
      _contactController.text,
      _passwordController.text,
      _profileImage?.path, // Save image path
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Registered")));
    Navigator.push(context, MaterialPageRoute(builder: (context) => SignInPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Picture Section
                  _profileImage != null
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: FileImage(_profileImage!),
                        )
                      : CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.person),
                        ),
                  TextButton(
                    onPressed: _pickImage,
                    child: Text("Choose Profile Picture"),
                  ),
                  SizedBox(height: 16),

                  // Text Fields
                  TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(labelText: "First Name")),
                  TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(labelText: "Last Name")),
                  TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: "Email")),
                  TextField(
                      controller: _contactController,
                      decoration: InputDecoration(labelText: "Contact No")),
                  TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: "Password"),
                      obscureText: true),
                  SizedBox(height: 20),

                  ElevatedButton(onPressed: _signUp, child: Text("Sign Up")),
                  TextButton(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (context) => SignInPage())),
                      child: Text("Already have an account? Sign In")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
