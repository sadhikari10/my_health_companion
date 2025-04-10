import 'package:flutter/material.dart';
import 'dashboard.dart';

class MedicationReminderPage extends StatefulWidget {
  @override
  _MedicationReminderPageState createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> {
  TimeOfDay? _selectedTime;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medication Reminder")),
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
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Select Medication Reminder Time", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _selectTime(context),
                        child: Text(_selectedTime == null ? "Pick Time" : _selectedTime!.format(context)),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Save reminder logic here
                          // For example, save _selectedTime
                        },
                        child: Text("Save"),
                      ),
                      SizedBox(height: 30),
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
