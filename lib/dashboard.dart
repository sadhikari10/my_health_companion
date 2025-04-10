import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'information_storage.dart';
import 'medication_reminder.dart';
import 'log_medication.dart';
import 'health_guidance.dart';
import 'appointment_tracking.dart';

class DashboardPage extends StatelessWidget {
  final Map<String, dynamic> user;

  DashboardPage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome, ${user['first_name']}!")),
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
