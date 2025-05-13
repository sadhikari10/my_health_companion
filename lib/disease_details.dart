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

    // Validate dosage format (e.g., 1-p, 10-p)
    final dosageRegex = RegExp(r'^\d+-p$');
    if (!dosageRegex.hasMatch(_dosageController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dosage must be in the format 'number-p' (e.g., 1-p, 10-p)")),
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Disease Details'),
        backgroundColor: Colors.blue.shade800.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fallback background color
          Container(
            color: Colors.blue.shade50,
          ),
          // Background image
          Positioned.fill(
            child: Builder(
              builder: (context) {
                try {
                  return Image.asset(
                    'assets/images/sss.jpg',
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
          // Semi-transparent overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Horizontal line separator
                  Container(
                    height: 1,
                    color: Colors.grey.shade400,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  SizedBox(height: 16),
                  // Disease dropdown
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedDisease,
                      decoration: InputDecoration(
                        labelText: "Select Disease",
                        border: InputBorder.none,
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
                  ),
                  if (_selectedDisease == "Other") ...[
                    SizedBox(height: 16),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: _customDiseaseController,
                        decoration: InputDecoration(
                          labelText: "Enter Disease Name",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _medicationNameController,
                      decoration: InputDecoration(
                        labelText: "Medication Name",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        labelText: "Dosage",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _startDateController,
                      decoration: InputDecoration(
                        labelText: "Start Date (YYYY-MM-DD)",
                        border: InputBorder.none,
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _startDateController),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _endDateController,
                      decoration: InputDecoration(
                        labelText: "End Date (YYYY-MM-DD)",
                        border: InputBorder.none,
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _endDateController),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _prescriberController,
                      decoration: InputDecoration(
                        labelText: "Prescriber",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Save Changes"),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Return to Information List"),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    "Thriving Health, Vibrant Life Every Day",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}