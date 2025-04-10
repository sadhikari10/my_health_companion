import 'package:flutter/material.dart';
import 'dashboard.dart';

class HealthGuidancePage extends StatefulWidget {
  @override
  _HealthGuidancePageState createState() => _HealthGuidancePageState();
}

class _HealthGuidancePageState extends State<HealthGuidancePage> {
  String? _selectedNutrient;

  final List<String> _nutrientTypes = [
    "Carbohydrates",
    "Proteins",
    "Fats",
    "Vitamins",
    "Minerals",
    "Water",
    "Fiber",
  ];

  void _submitNutrient() {
    if (_selectedNutrient != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selected Nutrient: $_selectedNutrient")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a nutrient type.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health Guidance")),
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
                    Text("Choose the Nutrient Type", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedNutrient,
                      onChanged: (value) => setState(() => _selectedNutrient = value),
                      items: _nutrientTypes.map((nutrient) {
                        return DropdownMenuItem(
                          value: nutrient,
                          child: Text(nutrient),
                        );
                      }).toList(),
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitNutrient,
                      child: Text("Submit Nutrient"),
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
