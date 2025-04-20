import 'dart:io';
import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'information_storage.dart';
import 'medication_reminder.dart';
import 'log_medication.dart';
import 'health_guidance.dart';
import 'appointment_tracking.dart';
import 'change_information.dart';  

class DashboardPage extends StatelessWidget {
  final Map<String, dynamic> user;

  DashboardPage({required this.user});

  @override
  Widget build(BuildContext context) {
    final String? profileImagePath = user['profile_image'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            InkWell(
              onTap: () {
                // Navigate to Change Information page when the user icon is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangeInformationPage(userId: user['id'])),
                );
              },
              child: CircleAvatar(
                backgroundImage: profileImagePath != null && File(profileImagePath).existsSync()
                    ? FileImage(File(profileImagePath))
                    : null,
                backgroundColor: profileImagePath == null ? Colors.grey[300] : null,
                radius: 20,
                child: profileImagePath == null ? Icon(Icons.person, color: Colors.grey[700]) : null,
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
                _buildButton(context, "Information Storage", InformationStoragePage()),
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
