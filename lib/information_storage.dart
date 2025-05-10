import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_health_companion/database.dart';
import 'information_list.dart';

class InformationStoragePage extends StatefulWidget {
  final String userEmail;

  const InformationStoragePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _InformationStoragePageState createState() => _InformationStoragePageState();
}

class _InformationStoragePageState extends State<InformationStoragePage> {
  String? _selectedDisease;
  final TextEditingController _customDiseaseController = TextEditingController();
  final TextEditingController _medicationNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _prescriberController = TextEditingController();
  List<String> _diseaseList = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndDiseases();
  }

  @override
  void dispose() {
    _customDiseaseController.dispose();
    _medicationNameController.dispose();
    _dosageController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _prescriberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndDiseases() async {
    try {
      final user = await DatabaseHelper.instance.getUser(widget.userEmail);
      if (user != null) {
        _userId = user['id'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load user info")),
        );
        return;
      }

      final db = await DatabaseHelper.instance.database;
      final diseases = await db.query('diseases');
      setState(() {
        _diseaseList = diseases.map((e) => e['name'] as String).toList();
        _diseaseList.add("Other");
      });
    } catch (e) {
      print("Error loading data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading diseases")),
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Widget _buildDatePicker(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      onTap: () => _selectDate(controller),
    );
  }

  Future<void> _confirmAndSave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Save"),
        content: Text("Are you sure you want to save this information?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Save")),
        ],
      ),
    );

    if (confirm == true) {
      _saveInformation();
    }
  }

  Future<void> _saveInformation() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not found")),
      );
      return;
    }

    String? diseaseToSave = _selectedDisease;
    if (_selectedDisease == 'Other') {
      if (_customDiseaseController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter the disease name")),
        );
        return;
      }
      diseaseToSave = _customDiseaseController.text.trim();
    }

    if (diseaseToSave == null ||
        _medicationNameController.text.trim().isEmpty ||
        _dosageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    // Validate dosage format
    final dosageLower = _dosageController.text.trim().toLowerCase();
    if (!dosageLower.contains(RegExp(r'\d+\s*(mg|tablet|capsule).*times.*(daily|per day)', caseSensitive: false)) &&
        !dosageLower.contains('twice') &&
        !dosageLower.contains('thrice') &&
        !RegExp(r'^\d+$').hasMatch(dosageLower)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid dosage format')),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.insertMedicationInfo(
        _userId!,
        diseaseToSave,
        _medicationNameController.text.trim(),
        _dosageController.text.trim(),
        _startDateController.text.trim().isEmpty ? null : _startDateController.text.trim(),
        _endDateController.text.trim().isEmpty ? null : _endDateController.text.trim(),
        _prescriberController.text.trim().isEmpty ? null : _prescriberController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Information saved successfully")),
      );

      // Navigate to InformationListPage to show updated list
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InformationListPage(userEmail: widget.userEmail),
        ),
      );
    } catch (e, stackTrace) {
      print("Error saving information: $e");
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving information: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Medication Info")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDisease,
              decoration: InputDecoration(
                labelText: "Select Disease",
                border: OutlineInputBorder(),
              ),
              items: _diseaseList.map((disease) {
                return DropdownMenuItem(
                  value: disease,
                  child: Text(disease),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDisease = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedDisease == "Other")
              TextField(
                controller: _customDiseaseController,
                decoration: InputDecoration(
                  labelText: "Enter Disease Name",
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _medicationNameController,
              decoration: InputDecoration(
                labelText: "Medication Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(
                labelText: "Dosage",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildDatePicker("Start Date (YYYY-MM-DD)", _startDateController),
            const SizedBox(height: 16),
            _buildDatePicker("End Date (YYYY-MM-DD)", _endDateController),
            const SizedBox(height: 16),
            TextField(
              controller: _prescriberController,
              decoration: InputDecoration(
                labelText: "Prescriber",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _confirmAndSave,
              child: Text("Save"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("View My Disease List"),
            ),
          ],
        ),
      ),
    );
  }
}