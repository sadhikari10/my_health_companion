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
  bool _isTaken = false;
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

  Future<bool> _canLogMedication() async {
    if (_selectedMedication == null) {
      print('Cannot log: _selectedMedication is null');
      return false;
    }
    final logDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final remainingDoses = await DatabaseHelper.instance.getRemainingDoses(
      widget.userId,
      _selectedMedication!,
      logDate,
    );
    print('Remaining doses for $_selectedMedication on $logDate: $remainingDoses');
    return remainingDoses > 0;
  }

  Future<void> _showDailyStatus() async {
    if (_selectedMedication == null) return;
    final logDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = true;
    final logCount = await DatabaseHelper.instance.getDailyLogCount(widget.userId, _selectedMedication!, logDate);
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
    if (_formKey.currentState!.validate() && _isTaken) {
      try {
        final canLog = await _canLogMedication();
        if (!canLog) {
          final logDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
        final now = DateTime.now();
        final log = {
          'user_id': widget.userId,
          'medicine_name': _selectedMedication!,
          'taken': 1,
          'log_date': DateFormat('yyyy-MM-dd').format(now),
          'log_time': DateFormat('HH:mm').format(now),
          'log_day': DateFormat('EEEE').format(now),
        };
        print('Submitting log: $log');
        await DatabaseHelper.instance.insertMedicationLog(log);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medication logged successfully')),
        );
        await _showDailyStatus();
        setState(() {
          _selectedMedication = null;
          _isTaken = false;
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
    } else if (!_isTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please check the "Taken" box to log medication')),
      );
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
            ElevatedButton(
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
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
          Container(
            height: 1,
            color: Colors.grey.shade400,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      try {
                        return Image.asset(
                          'assets/images/medical_image.jpg',
                          fit: BoxFit.cover,
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
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                              labelText: 'Select Medication',
                              border: InputBorder.none,
                            ),
                            validator: (value) => value == null ? 'Please select a medication' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isTaken,
                                onChanged: (value) {
                                  setState(() {
                                    _isTaken = value ?? false;
                                  });
                                },
                                activeColor: Colors.blue.shade600,
                              ),
                              const Text(
                                'Taken',
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: _showConfirmationDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                      'Log Medication',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
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
                                          SnackBar(content: const Text('Error: User not found')),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                      'Return to Dashboard',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}