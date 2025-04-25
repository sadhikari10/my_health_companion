import 'package:flutter/material.dart';
import 'package:my_health_companion/database.dart';
import 'dashboard.dart';

class HealthGuidancePage extends StatefulWidget {
  final int userId;

  HealthGuidancePage({required this.userId});

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
      appBar: AppBar(
        title: const Text("Health Guidance"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Choose the Nutrient Type",
                      style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedNutrient,
                      onChanged: (value) => setState(() => _selectedNutrient = value),
                      items: _nutrientTypes.map((nutrient) {
                        return DropdownMenuItem(
                          value: nutrient,
                          child: Text(nutrient),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitNutrient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Text("Submit Nutrient", style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
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
                      child: const Text("Return to Dashboard", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Center(
                child: Text(
                  "Thriving Health, Vibrant Life Every Day",
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
      ),
    );
  }
}