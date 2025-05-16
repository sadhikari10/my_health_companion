import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // Validate dosage is a positive integer
    final dosageText = _dosageController.text.trim();
    try {
      final dosage = int.parse(dosageText);
      if (dosage <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Dosage must be a positive number")),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dosage must be a valid number")),
      );
      return;
    }

    await DatabaseHelper.instance.updateMedicationInfo(
      widget.info['id'],
      diseaseToSave,
      _medicationNameController.text.trim(),
      dosageText,
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
      backgroundColor: Colors.transparent, // Transparent to show background
      extendBodyBehindAppBar: true, // Extend image under AppBar
      appBar: AppBar(
        title: const Text('Disease Details'),
        backgroundColor: Colors.white, // White background
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand, // Ensure Stack fills entire screen
        children: [
          // Fallback background color
          Container(
            color: Colors.blue.shade50, // Matches app theme
          ),
          // Background image
          Positioned.fill(
            child: Builder(
              builder: (context) {
                try {
                  return Image.asset(
                    'assets/images/medical_image.jpg',
                    fit: BoxFit.cover, // Fill entire screen, may crop
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
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
              color: Colors.black.withOpacity(0.3), // Adjust opacity
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
                  const SizedBox(height: 16),
                  // Disease dropdown
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // Semi-transparent
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedDisease,
                      decoration: const InputDecoration(
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
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9), // Semi-transparent
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: _customDiseaseController,
                        decoration: const InputDecoration(
                          labelText: "Enter Disease Name",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // Semi-transparent
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _medicationNameController,
                      decoration: const InputDecoration(
                        labelText: "Medication Name",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // Semi-transparent
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: "Dosage",
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // Semi-transparent
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: "Start Date (YYYY-MM-DD)",
                        border: InputBorder.none,
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _startDateController),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // Semi-transparent
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: "End Date (YYYY-MM-DD)",
                        border: InputBorder.none,
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _endDateController),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // Semi-transparent
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: _prescriberController,
                      decoration: const InputDecoration(
                        labelText: "Prescriber",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text("Save Changes"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text("Return to Information List"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
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