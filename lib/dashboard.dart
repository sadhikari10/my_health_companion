import 'dart:io';
import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'medication_reminder.dart';
import 'log_medication.dart';
import 'health_guidance.dart';
import 'appointment_tracking.dart';
import 'change_information.dart';
import 'database.dart' as db;
import 'information_list.dart';
import 'view_medication_intake.dart';
import 'view_appointment.dart';
import 'view_progress.dart';

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
    try {
      final updatedUser = await db.DatabaseHelper.instance.getUserById(user['id']);
      if (updatedUser != null) {
        setState(() {
          user = updatedUser;
        });
      }
    } catch (e, stackTrace) {
      print('Error refreshing user: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing user data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? profileImagePath = user['profile_image'];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Reduced height for better spacing
        child: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 32, // Smaller logo to prevent crowding
                errorBuilder: (context, error, stackTrace) {
                  print('Logo loading error: $error\n$stackTrace');
                  return Icon(Icons.broken_image, color: Colors.grey[700], size: 32);
                },
              ),
              Row(
                children: [
                  GestureDetector(
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
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          backgroundImage: profileImagePath != null && File(profileImagePath).existsSync()
                              ? FileImage(File(profileImagePath))
                              : null,
                          backgroundColor: profileImagePath == null ? Colors.grey[300] : null,
                          radius: 16, // Smaller avatar
                          child: profileImagePath == null
                              ? Icon(Icons.person, color: Colors.grey[700], size: 20)
                              : null,
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Welcome, ${user['first_name']}!",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) {
                try {
                  return Image.asset(
                    'assets/images/medical_image.jpg',
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
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          Column(
            children: [
              Container(
                height: 1,
                color: Colors.grey.shade400,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                          children: [
                            _buildGridButton(
                              context,
                              "Information Storage",
                              Icons.info_outline,
                              InformationListPage(userEmail: user['email']),
                            ),
                            _buildGridButton(
                              context,
                              "Medication Reminder",
                              Icons.alarm,
                              MedicationReminderPage(userId: user['id']),
                            ),
                            _buildGridButton(
                              context,
                              "Log Medication",
                              Icons.edit_note,
                              LogMedicationPage(userId: user['id']),
                            ),
                            _buildGridButton(
                              context,
                              "Health Guidance",
                              Icons.health_and_safety,
                              HealthGuidancePage(userId: user['id']),
                            ),
                            _buildGridButton(
                              context,
                              "Appointments",
                              Icons.calendar_today,
                              AppointmentTrackingPage(userId: user['id']),
                            ),
                            _buildGridButton(
                              context,
                              "View Medicine Intake",
                              Icons.view_list,
                              ViewMedicationIntakePage(userId: user['id']),
                            ),
                            _buildGridButton(
                              context,
                              "View Appointment",
                              Icons.event,
                              ViewAppointmentPage(userId: user['id']),
                            ),
                            _buildGridButton(
                              context,
                              "View Progress",
                              Icons.trending_up,
                              ViewProgressPage(userId: user['id']),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => SignInPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            minimumSize: const Size(double.infinity, 48), // Full-width button
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade500, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}