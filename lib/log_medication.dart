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
      print('Fetched medications: $medications');
      setState(() {
        _medications = medications;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching medications: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching medications: $e')),
      );
      setState(() {
        _medications = [];
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

  Future<bool> _canLogMedication() async {
    if (_selectedMedication == null || _selectedDate == null) {
      print('Cannot log: _selectedMedication or _selectedDate is null');
      return false;
    }
    final logDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final remainingDoses = await DatabaseHelper.instance.getRemainingDoses(
      widget.userId,
      _selectedMedication!,
      logDate,
    );
    print('Remaining doses for $_selectedMedication on $logDate: $remainingDoses');
    return remainingDoses > 0;
  }

  Future<void> _showDailyStatus() async {
    if (_selectedMedication == null || _selectedDate == null) return;
    final logDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final isToday = logDate == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logCount = await DatabaseHelper.instance.getDailyLogCount(widget.userId, _selectedMedication!, logDate);
    // For today, show only taken doses; missed doses are calculated at end of day
    if (isToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status: $logCount taken today')),
      );
    } else {
      final medication = _medications.firstWhere(
        (m) => m['medication_name'] == _selectedMedication,
        orElse: () => <String, dynamic>{'dosage': 'unknown'},
      );
      final dosage = medication['dosage'] as String? ?? 'unknown';
      final dailyDosage = dosage.isNotEmpty ? await DatabaseHelper.instance.parseDailyDosage(dosage) : 1;
      final missedCount = dailyDosage - logCount > 0 ? dailyDosage - logCount : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status: $logCount taken, $missedCount missed on $logDate')),
      );
    }
  }

  void _submitLog() async {
    if (_formKey.currentState!.validate()) {
      try {
        final canLog = await _canLogMedication();
        if (!canLog) {
          final logDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          final remainingDoses = await DatabaseHelper.instance.getRemainingDoses(
            widget.userId,
            _selectedMedication!,
            logDate,
          );
          print('Cannot log: No remaining doses for $_selectedMedication on $logDate');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('All doses already taken for today')),
          );
          return;
        }
        final log = {
          'user_id': widget.userId,
          'medicine_name': _selectedMedication!,
          'taken': 1, // Always log as taken
          'log_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'log_time': _selectedTime!.format(context),
          'log_day': _selectedDay!,
        };
        print('Submitting log: $log');
        await DatabaseHelper.instance.insertMedicationLog(log);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medication logged successfully')),
        );
        // Show daily status after logging
        await _showDailyStatus();
        // Clear form
        setState(() {
          _selectedMedication = null;
          _selectedDate = null;
          _selectedTime = null;
          _selectedDay = null;
          _formKey.currentState!.reset();
        });
      } catch (e, stackTrace) {
        print('Error logging medication: $e');
        print(stackTrace);
        final errorMessage = e.toString().contains('All doses already taken')
            ? 'All doses already taken for today'
            : 'Error logging medication: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
                _submitLog();
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
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedMedication,
                                hint: const Text('Choose a medication'),
                                onChanged: (value) => setState(() => _selectedMedication = value),
                                items: _medications.map((med) {
                                  return DropdownMenuItem<String>(
                                    value: med['medication_name'] as String,
                                    child: Text(med['medication_name'] as String),
                                  );
                                }).toList(),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                validator: (value) => value == null ? 'Please select a medication' : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Select Date',
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: _selectedDate == null
                                      ? 'Choose a date'
                                      : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                  border: InputBorder.none,
                                  suffixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
                                ),
                                onTap: () => _selectDate(context),
                                validator: (value) => _selectedDate == null ? 'Please select a date' : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Select Time',
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: _selectedTime == null
                                      ? 'Choose a time'
                                      : _selectedTime!.format(context),
                                  border: InputBorder.none,
                                  suffixIcon: Icon(Icons.access_time, color: Colors.blue.shade600),
                                ),
                                onTap: () => _selectTime(context),
                                validator: (value) => _selectedTime == null ? 'Please select a time' : null,
                              ),
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
    );
  }
}