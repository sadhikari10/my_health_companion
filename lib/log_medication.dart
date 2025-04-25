import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_health_companion/database.dart';
import 'dashboard.dart';

class LogMedicationPage extends StatefulWidget {
  final int userId;

  LogMedicationPage({required this.userId});

  @override
  _LogMedicationPageState createState() => _LogMedicationPageState();
}

class _LogMedicationPageState extends State<LogMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMedication;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDay;
  bool _isTaken = true; // Default to Taken
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    try {
      final medications = await DatabaseHelper.instance.getUserMedications(widget.userId);
      setState(() {
        _medications = medications;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching medications: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching medications')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDay = DateFormat('EEEE').format(picked);
      });
    }
  }

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

  void _submitLog() async {
    if (_formKey.currentState!.validate()) {
      try {
        final log = {
          'user_id': widget.userId,
          'medicine_name': _selectedMedication!,
          'taken': _isTaken ? 1 : 0,
          'log_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'log_time': _selectedTime!.format(context),
          'log_day': _selectedDay!,
        };
        await DatabaseHelper.instance.insertMedicationLog(log);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medication ${_isTaken ? 'taken' : 'missed'} logged successfully')),
        );
        // Clear form
        setState(() {
          _selectedMedication = null;
          _selectedDate = null;
          _selectedTime = null;
          _selectedDay = null;
          _isTaken = true;
          _formKey.currentState!.reset();
        });
      } catch (e, stackTrace) {
        print('Error logging medication: $e');
        print(stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging medication')),
        );
      }
    }
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Medication Log',
            style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to log this medication?',
            style: TextStyle(color: Colors.blueGrey),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'No',
                style: TextStyle(color: Colors.blueGrey),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _submitLog(); // Proceed with logging
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Medication'),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Medication',
                              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedMedication,
                              hint: const Text('Choose a medication'),
                              onChanged: (value) => setState(() => _selectedMedication = value),
                              items: _medications.map((med) {
                                return DropdownMenuItem<String>(
                                  value: med['medication_name'] as String,
                                  child: Text(med['medication_name'] as String),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) => value == null ? 'Please select a medication' : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Intake Status',
                              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text('Taken'),
                                    value: true,
                                    groupValue: _isTaken,
                                    onChanged: (value) => setState(() => _isTaken = value!),
                                    activeColor: Colors.blue.shade600,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text('Missed'),
                                    value: false,
                                    groupValue: _isTaken,
                                    onChanged: (value) => setState(() => _isTaken = value!),
                                    activeColor: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Select Date',
                              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: _selectedDate == null
                                    ? 'Choose a date'
                                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onTap: () => _selectDate(context),
                              validator: (value) => _selectedDate == null ? 'Please select a date' : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Select Time',
                              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: _selectedTime == null
                                    ? 'Choose a time'
                                    : _selectedTime!.format(context),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onTap: () => _selectTime(context),
                              validator: (value) => _selectedTime == null ? 'Please select a time' : null,
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: _showConfirmationDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 2,
                                    ),
                                    child: const Text(
                                      'Log Medication',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
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
                                    child: const Text(
                                      'Return to Dashboard',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Center(
                child: Text(
                  'Thriving Health, Vibrant Life Every Day',
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