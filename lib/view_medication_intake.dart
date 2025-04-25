import 'package:flutter/material.dart';
import 'package:my_health_companion/database.dart';
import 'dashboard.dart';

class ViewMedicationIntakePage extends StatefulWidget {
  final int userId;

  ViewMedicationIntakePage({required this.userId});

  @override
  _ViewMedicationIntakePageState createState() => _ViewMedicationIntakePageState();
}

class _ViewMedicationIntakePageState extends State<ViewMedicationIntakePage> {
  List<Map<String, dynamic>> _medicationLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedicationLogs();
  }

  Future<void> _fetchMedicationLogs() async {
    try {
      final logs = await DatabaseHelper.instance.getMedicationLogs(widget.userId);
      setState(() {
        _medicationLogs = logs;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching medication logs: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching medication logs')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMedicationLog(int id) async {
    try {
      await DatabaseHelper.instance.deleteMedicationLog(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Medication log deleted successfully')),
      );
      await _fetchMedicationLogs(); // Refresh the list
    } catch (e, stackTrace) {
      print('Error deleting medication log: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting medication log')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Medication Intake'),
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
                  : _medicationLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'No medication logs found.',
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: _medicationLogs.map((log) {
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  title: Text(
                                    log['medicine_name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        'Date: ${log['log_date']}',
                                        style: const TextStyle(color: Colors.blueGrey),
                                      ),
                                      Text(
                                        'Time: ${log['log_time']}',
                                        style: const TextStyle(color: Colors.blueGrey),
                                      ),
                                      Text(
                                        'Day: ${log['log_day']}',
                                        style: const TextStyle(color: Colors.blueGrey),
                                      ),
                                      Text(
                                        'Status: ${log['taken'] == 1 ? 'Taken' : 'Not Taken'}',
                                        style: const TextStyle(color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _deleteMedicationLog(log['id']);
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
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