import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_health_companion/database.dart';
import 'dashboard.dart';

class AppointmentTrackingPage extends StatefulWidget {
  final int userId;

  AppointmentTrackingPage({required this.userId});

  @override
  _AppointmentTrackingPageState createState() => _AppointmentTrackingPageState();
}

class _AppointmentTrackingPageState extends State<AppointmentTrackingPage> {
  DateTime? _lastAppointmentDate;
  TimeOfDay? _lastAppointmentTime;
  DateTime? _followUpDate;
  TimeOfDay? _followUpTime;

  final dateFormatter = DateFormat('yyyy-MM-dd');
  final timeFormatter = DateFormat('HH:mm');
  final dayFormatter = DateFormat('EEEE');

  Future<void> _selectDate(BuildContext context, bool isLastAppointment) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.blue.shade50,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isLastAppointment) {
          _lastAppointmentDate = picked;
        } else {
          _followUpDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isLastAppointment) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.blue.shade50,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isLastAppointment) {
          _lastAppointmentTime = picked;
        } else {
          _followUpTime = picked;
        }
      });
    }
  }

  Future<void> _saveAppointments() async {
    try {
      if (_lastAppointmentDate != null && _lastAppointmentTime != null) {
        final date = dateFormatter.format(_lastAppointmentDate!);
        final time = _lastAppointmentTime!.format(context);
        final day = dayFormatter.format(_lastAppointmentDate!);
        await DatabaseHelper.instance.insertAppointment({
          'user_id': widget.userId,
          'appointment_type': 'last_appointment',
          'appointment_date': date,
          'appointment_time': time,
          'appointment_day': day,
        });
        print('Saved last appointment: $date, $time, $day');
      }
      if (_followUpDate != null && _followUpTime != null) {
        final date = dateFormatter.format(_followUpDate!);
        final time = _followUpTime!.format(context);
        final day = dayFormatter.format(_followUpDate!);
        await DatabaseHelper.instance.insertAppointment({
          'user_id': widget.userId,
          'appointment_type': 'follow_up',
          'appointment_date': date,
          'appointment_time': time,
          'appointment_day': day,
        });
        print('Saved follow-up appointment: $date, $time, $day');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointments saved successfully')),
      );
      // Reset fields
      setState(() {
        _lastAppointmentDate = null;
        _lastAppointmentTime = null;
        _followUpDate = null;
        _followUpTime = null;
      });
    } catch (e, stackTrace) {
      print('Error saving appointments: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving appointments: $e')),
      );
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Appointments'),
          content: const Text('Are you sure you want to save the appointment details?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _saveAppointments(); // Save the appointments
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Appointments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Horizontal line separator
          Container(
            height: 1,
            color: Colors.grey.shade400,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          // Main body content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Appointment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ListTile(
                          title: Text(
                            _lastAppointmentDate == null
                                ? 'Select Date'
                                : dateFormatter.format(_lastAppointmentDate!),
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          trailing: Icon(Icons.calendar_today, color: Colors.blue.shade600),
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ListTile(
                          title: Text(
                            _lastAppointmentTime == null
                                ? 'Select Time'
                                : _lastAppointmentTime!.format(context),
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          trailing: Icon(Icons.access_time, color: Colors.blue.shade600),
                          onTap: () => _selectTime(context, true),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Follow-Up Appointment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ListTile(
                          title: Text(
                            _followUpDate == null
                                ? 'Select Date'
                                : dateFormatter.format(_followUpDate!),
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          trailing: Icon(Icons.calendar_today, color: Colors.blue.shade600),
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ListTile(
                          title: Text(
                            _followUpTime == null
                                ? 'Select Time'
                                : _followUpTime!.format(context),
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          trailing: Icon(Icons.access_time, color: Colors.blue.shade600),
                          onTap: () => _selectTime(context, false),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _showConfirmDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Save Appointments',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = await DatabaseHelper.instance.getUserById(widget.userId);
                            if (user != null) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DashboardPage(user: user),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: User not found')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Return to Dashboard',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Center(
              child: Text(
                'Thriving Health, Vibrant Life Every Day',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}