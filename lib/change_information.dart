import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database.dart';

class ChangeInformationPage extends StatefulWidget {
  final int userId;

  const ChangeInformationPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ChangeInformationPageState createState() => _ChangeInformationPageState();
}

class _ChangeInformationPageState extends State<ChangeInformationPage> {
  Map<String, dynamic>? user;
  Map<String, TextEditingController> _controllers = {};
  String? _imagePath; // Store the image path
  bool _passwordVisible = false; // Flag to toggle password visibility

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Load user information from the database
  Future<void> _loadUserInfo() async {
    final userData = await DatabaseHelper.instance.getUserById(widget.userId);
    if (userData != null) {
      setState(() {
        user = userData;
        _controllers = _createControllers(userData);
        _imagePath = userData['profile_image'];
      });
    }
  }

  // Create TextEditingControllers dynamically based on available fields
  Map<String, TextEditingController> _createControllers(Map<String, dynamic> userData) {
    Map<String, TextEditingController> controllers = {};
    userData.forEach((key, value) {
      if (value != null && key != 'id' && key != 'profile_image') {
        controllers[key] = TextEditingController(text: value.toString());
      }
    });
    return controllers;
  }

  // Function to pick a new image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Validate input fields using regular expressions
  bool _validateInputs() {
    // Email regex: user@domain.com
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    // Name regex: Letters, spaces, hyphens only
    final nameRegex = RegExp(r'^[a-zA-Z\s-]+$');
    // Contact number regex: Digits, optional + at start
    final contactRegex = RegExp(r'^\+?\d{7,15}$');

    if (!_controllers.containsKey('email') || !emailRegex.hasMatch(_controllers['email']!.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid email address")),
      );
      return false;
    }

    if (!_controllers.containsKey('first_name') || !nameRegex.hasMatch(_controllers['first_name']!.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("First name should contain only letters, spaces, or hyphens")),
      );
      return false;
    }

    if (!_controllers.containsKey('last_name') || !nameRegex.hasMatch(_controllers['last_name']!.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Last name should contain only letters, spaces, or hyphens")),
      );
      return false;
    }

    if (!_controllers.containsKey('contact_no') || !contactRegex.hasMatch(_controllers['contact_no']!.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Contact number should be 7-15 digits, optionally starting with +")),
      );
      return false;
    }

    if (!_controllers.containsKey('password') || _controllers['password']!.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 6 characters long")),
      );
      return false;
    }

    return true;
  }

  // Function to save the updated user information
  Future<void> _saveUserInfo() async {
    if (!_validateInputs()) {
      return;
    }

    // Prepare the updated user data
    Map<String, dynamic> updatedUser = {};
    _controllers.forEach((key, controller) {
      updatedUser[key] = controller.text;
    });

    if (_imagePath != null) {
      updatedUser['profile_image'] = _imagePath;
    }

    // Update the user information in the database
    await DatabaseHelper.instance.updateUser(
      widget.userId,
      updatedUser['first_name'],
      updatedUser['last_name'],
      updatedUser['email'],
      updatedUser['contact_no'],
      updatedUser['password'],
      updatedUser['profile_image'],
    );

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Information updated successfully")));

    Navigator.pop(context, updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Change Information'),
        backgroundColor: Colors.blue.shade800.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fallback background color
          Container(
            color: Colors.blue.shade50,
          ),
          // Background image
          Positioned.fill(
            child: Builder(
              builder: (context) {
                try {
                  return Image.asset(
                    'assets/images/sss.jpg',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      print('Asset loading error: $error\n$stackTrace');
                      return Container(
                        color: Colors.blue.shade50,
                        child: Center(child: Text('Failed to load background image')),
                      );
                    },
                  );
                } catch (e) {
                  print('Exception loading asset: $e');
                  return Container(
                    color: Colors.blue.shade50,
                    child: Center(child: Text('Exception loading background image')),
                  );
                }
              },
            ),
          ),
          // Semi-transparent overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Horizontal line separator
                  Container(
                    height: 1,
                    color: Colors.grey.shade400,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  SizedBox(height: 16),
                  // Form fields
                  ..._buildFormFields(),
                  // Save button
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: _saveUserInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Save Changes"),
                      ),
                    ),
                  ),
                  // Back to Home button
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Back to Home"),
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
        ],
      ),
    );
  }

  // Dynamically create form fields based on the available data
  List<Widget> _buildFormFields() {
    List<Widget> fields = [];

    _controllers.forEach((key, controller) {
      fields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: TextField(
              controller: controller,
              obscureText: key == 'password' && !_passwordVisible,
              decoration: InputDecoration(
                labelText: _capitalize(key),
                border: InputBorder.none,
                suffixIcon: key == 'password'
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
              onChanged: (value) {
                setState(() {
                  user?[key] = value;
                });
              },
            ),
          ),
        ),
      );
    });

    // Add the profile image section
    fields.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: Row(
            children: [
              _imagePath != null
                  ? CircleAvatar(
                      radius: 30,
                      backgroundImage: FileImage(File(_imagePath!)),
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
      ),
    );

    return fields;
  }

  // Helper function to capitalize field labels
  String _capitalize(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}