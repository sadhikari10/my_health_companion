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
  String? _imagePath;  // Store the image path
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
        _imagePath = userData['profile_image'];  // Get the image path from the user data
      });
    }
  }

  // Create TextEditingControllers dynamically based on available fields
  Map<String, TextEditingController> _createControllers(Map<String, dynamic> userData) {
    Map<String, TextEditingController> controllers = {};
    userData.forEach((key, value) {
      if (value != null && key != 'id' && key != 'profile_image') {  // Don't include 'id' or 'profile_image'
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

  // Function to save the updated user information
  Future<void> _saveUserInfo() async {
    // Prepare the updated user data
    Map<String, dynamic> updatedUser = {};
    _controllers.forEach((key, controller) {
      updatedUser[key] = controller.text;
    });

    if (_imagePath != null) {
      updatedUser['profile_image'] = _imagePath;  // Update the image path
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
  //Navigator.pop(context, 'User details updated successfully');
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
      appBar: AppBar(title: Text('Change Information')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Dynamically create form fields based on the available data
            ..._buildFormFields(),

            // Save button
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveUserInfo,
              child: Text("Save Changes"),
            ),

            // Button to return to the homepage
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // This will take the user back to the previous screen (home page)
              },
              child: Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamically create form fields based on the available data
  List<Widget> _buildFormFields() {
    List<Widget> fields = [];

    _controllers.forEach((key, controller) {
      if (key == 'password') {
        fields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: controller,
              obscureText: !_passwordVisible,  // Hide the password by default
              decoration: InputDecoration(
                labelText: _capitalize(key),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;  // Toggle password visibility
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  user?[key] = value;  // Update the user data on change
                });
              },
            ),
          ),
        );
      } else {
        fields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: _capitalize(key),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  user?[key] = value;  // Update the user data on change
                });
              },
            ),
          ),
        );
      }
    });

    // Add the profile image section in the requested format
    fields.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
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
              // Display the profile image or a default icon if the image is not set
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
