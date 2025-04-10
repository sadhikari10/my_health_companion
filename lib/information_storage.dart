import 'package:flutter/material.dart';
import 'dashboard.dart';

class InformationStoragePage extends StatefulWidget {
  @override
  _InformationStoragePageState createState() => _InformationStoragePageState();
}

class _InformationStoragePageState extends State<InformationStoragePage> {
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _prescriberController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedDisease;

  final List<String> _diseaseList = [
    "Diabetes", "Hypertension", "Asthma", "Heart Disease", "Migraine", "Other"
  ];

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Information Storage")),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Disease Name"),
                      DropdownButtonFormField<String>(
                        value: _selectedDisease,
                        onChanged: (value) => setState(() => _selectedDisease = value),
                        items: _diseaseList.map((disease) {
                          return DropdownMenuItem(
                            value: disease,
                            child: Text(disease),
                          );
                        }).toList(),
                        decoration: InputDecoration(border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _medicationController,
                        decoration: InputDecoration(labelText: "Medication Name", border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _dosageController,
                        decoration: InputDecoration(labelText: "Dosage", border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 10),
                      Text("Start Date"),
                      ElevatedButton(
                        onPressed: () => _selectDate(context, true),
                        child: Text(_startDate == null ? "Select Start Date" : _startDate!.toLocal().toString().split(' ')[0]),
                      ),
                      SizedBox(height: 10),
                      Text("End Date"),
                      ElevatedButton(
                        onPressed: () => _selectDate(context, false),
                        child: Text(_endDate == null ? "Select End Date" : _endDate!.toLocal().toString().split(' ')[0]),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _prescriberController,
                        decoration: InputDecoration(labelText: "Prescriber's Name", border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Save information logic here
                        },
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
