import 'dart:io';
import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'medication_reminder.dart';
import 'log_medication.dart';
import 'health_guidance.dart';
import 'appointment_tracking.dart';
import 'change_information.dart';
import 'database.dart ' as db; 
import 'information_list.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;

  DashboardPage({required this.user});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Map<String, dynamic> user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  Future<void> _refreshUser() async {
    final updatedUser = await db.DatabaseHelper.instance.getUserById(user['id']);
    if (updatedUser != null) {
      setState(() {
        user = updatedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? profileImagePath = user['profile_image'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeInformationPage(userId: user['id']),
                  ),
                );
                if (result != null) {
                  await _refreshUser();
                }
              },
              child: CircleAvatar(
                backgroundImage: profileImagePath != null && File(profileImagePath).existsSync()
                    ? FileImage(File(profileImagePath))
                    : null,
                backgroundColor: profileImagePath == null ? Colors.grey[300] : null,
                radius: 20,
                child: profileImagePath == null
                    ? Icon(Icons.person, color: Colors.grey[700])
                    : null,
              ),
            ),
            SizedBox(width: 12),
            Text("Welcome, ${user['first_name']}!"),
          ],
        ),
      ),
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
                _buildButton(context, "Information Storage", InformationListPage(userEmail: user['email'])),
                _buildButton(context, "Medication Reminder System", MedicationReminderPage()),
                _buildButton(context, "Log Medication Intake", LogMedicationPage()),
                _buildButton(context, "Health Guidance", HealthGuidancePage()),
                _buildButton(context, "Appointment Tracking", AppointmentTrackingPage()),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SignInPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Logout", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Text(title),
      ),
    );
  }
}