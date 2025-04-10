import 'package:flutter/material.dart';
import 'dashboard.dart';

class LogMedicationPage extends StatefulWidget {
  @override
  _LogMedicationPageState createState() => _LogMedicationPageState();
}

class _LogMedicationPageState extends State<LogMedicationPage> {
  String? _selectedMedicine1;
  String? _selectedMedicine2;
  bool _takenMedicine1 = false;
  bool _takenMedicine2 = false;

  final List<String> _medicineList = [
    "Paracetamol",
    "Ibuprofen",
    "Amoxicillin",
    "Metformin",
    "Atorvastatin",
    "Other",
  ];

  void _saveLog() {
    // Save logic placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Medication log saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log Medication Intake")),
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text("Select First Medication"),
                      DropdownButtonFormField<String>(
                        value: _selectedMedicine1,
                        onChanged: (value) => setState(() => _selectedMedicine1 = value),
                        items: _medicineList.map((medicine) {
                          return DropdownMenuItem(
                            value: medicine,
                            child: Text(medicine),
                          );
                        }).toList(),
                        decoration: InputDecoration(border: OutlineInputBorder()),
                      ),
                      CheckboxListTile(
                        title: Text("Taken?"),
                        value: _takenMedicine1,
                        onChanged: (value) => setState(() => _takenMedicine1 = value ?? false),
                      ),
                      SizedBox(height: 20),
                      Text("Select Second Medication"),
                      DropdownButtonFormField<String>(
                        value: _selectedMedicine2,
                        onChanged: (value) => setState(() => _selectedMedicine2 = value),
                        items: _medicineList.map((medicine) {
                          return DropdownMenuItem(
                            value: medicine,
                            child: Text(medicine),
                          );
                        }).toList(),
                        decoration: InputDecoration(border: OutlineInputBorder()),
                      ),
                      CheckboxListTile(
                        title: Text("Taken?"),
                        value: _takenMedicine2,
                        onChanged: (value) => setState(() => _takenMedicine2 = value ?? false),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveLog,
                        child: Text("Save Log"),
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
