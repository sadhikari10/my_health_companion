import 'package:flutter/material.dart';
import 'dashboard.dart';

class AppointmentTrackingPage extends StatefulWidget {
  @override
  _AppointmentTrackingPageState createState() => _AppointmentTrackingPageState();
}

class _AppointmentTrackingPageState extends State<AppointmentTrackingPage> {
  DateTime? _previousAppointment;
  DateTime? _nextAppointment;

  Future<void> _selectDate(BuildContext context, bool isPrevious) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isPrevious) {
          _previousAppointment = picked;
        } else {
          _nextAppointment = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    return date == null ? "Select Date" : "${date.day}/${date.month}/${date.year}";
  }

  void _saveAppointments() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Appointments saved")),
    );
    // Implement saving logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Appointment Tracking")),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade100, Colors.blue.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Previous Appointment Date", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(_formatDate(_previousAppointment)),
                    ),
                    SizedBox(height: 30),
                    Text("Next Scheduled Visit", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text(_formatDate(_nextAppointment)),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _saveAppointments,
                      child: Text("Save"),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DashboardPage(user: {'first_name': 'User'})),
                      ),
                      child: Text("Return to Dashboard"),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "Thriving Health, Vibrant Life Every Day",
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
