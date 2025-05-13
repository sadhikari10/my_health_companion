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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
          border: InputBorder.none,
        ),
        onTap: () => _selectDate(controller),
      ),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text("Save"),
          ),
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

    // Validate dosage: must be numeric and between 1-9
    final dosage = _dosageController.text.trim();
    if (!RegExp(r'^\d+$').hasMatch(dosage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dosage must be a numeric value")),
      );
      return;
    }
    final dosageValue = int.parse(dosage);
    if (dosageValue < 1 || dosageValue > 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dosage must be between 1 and 9")),
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
      appBar: AppBar(
        title: Text("Add Medication Info"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Horizontal line separator
          Container(
            height: 1,
            color: Colors.grey.shade400,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          // Main body content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
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
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedDisease == "Other")
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                          labelText: "Dosage (1-9)",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDatePicker("Start Date (YYYY-MM-DD)", _startDateController),
                    const SizedBox(height: 16),
                    _buildDatePicker("End Date (YYYY-MM-DD)", _endDateController),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _confirmAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text("Save"),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InformationListPage(userEmail: widget.userEmail),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text("View My Disease List"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}