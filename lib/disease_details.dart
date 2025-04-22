import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_health_companion/database.dart';

class DiseaseDetailsPage extends StatefulWidget {
  final Map<String, dynamic> info;

  const DiseaseDetailsPage({Key? key, required this.info}) : super(key: key);

  @override
  _DiseaseDetailsPageState createState() => _DiseaseDetailsPageState();
}

class _DiseaseDetailsPageState extends State<DiseaseDetailsPage> {
  final TextEditingController _customDiseaseController = TextEditingController();
  final TextEditingController _medicationNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _prescriberController = TextEditingController();
  String? _selectedDisease;
  List<String> _diseaseList = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    _selectedDisease = widget.info['disease_name'] ?? '';
    _customDiseaseController.text = widget.info['disease_name'] ?? '';
    _medicationNameController.text = widget.info['medication_name'] ?? '';
    _dosageController.text = widget.info['dosage'] ?? '';
    _startDateController.text = widget.info['start_date'] ?? '';
    _endDateController.text = widget.info['end_date'] ?? '';
    _prescriberController.text = widget.info['prescriber'] ?? '';
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    try {
      final diseases = await DatabaseHelper.instance.getAllDiseases();
      setState(() {
        _diseaseList = diseases.map((e) => e['name'] as String).toList();
        _diseaseList.add("Other");
        
        if (!_diseaseList.contains(_selectedDisease)) {
          _selectedDisease = "Other";
        }
      });
    } catch (e) {
      print("Error loading diseases: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading diseases")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      controller.text = formattedDate;
    }
  }

  Future<void> _saveChanges() async {
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

    await DatabaseHelper.instance.updateMedicationInfo(
      widget.info['id'],
      diseaseToSave,
      _medicationNameController.text.trim(),
      _dosageController.text.trim(),
      _startDateController.text.trim().isEmpty ? null : _startDateController.text.trim(),
      _endDateController.text.trim().isEmpty ? null : _endDateController.text.trim(),
      _prescriberController.text.trim().isEmpty ? null : _prescriberController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Changes saved successfully")),
    );

    Navigator.pop(context, true); // Return true to trigger refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disease Details'),
      ),
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
                  if (value != "Other") {
                    _customDiseaseController.text = value ?? '';
                  }
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
            TextField(
              controller: _startDateController,
              decoration: InputDecoration(
                labelText: "Start Date (YYYY-MM-DD)",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, _startDateController),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endDateController,
              decoration: InputDecoration(
                labelText: "End Date (YYYY-MM-DD)",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, _endDateController),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _prescriberController,
              decoration: InputDecoration(
                labelText: "Prescriber",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                  child: Text(
                    "Return to Information List",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: Text("Save Changes"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}