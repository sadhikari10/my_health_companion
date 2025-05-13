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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Medication Intake'),
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
                image: DecorationImage(
                  image: AssetImage('assets/images/medical_image.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.6),
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _medicationLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'No medication logs found.',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
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
                                color: Colors.white.withOpacity(0.9),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  title: Text(
                                    log['medicine_name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        'Date: ${log['log_date']}',
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                      Text(
                                        'Time: ${log['log_time']}',
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                      Text(
                                        'Day: ${log['log_day']}',
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                      Text(
                                        'Status: ${log['taken'] == 1 ? 'Taken' : 'Not Taken'}',
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
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
    );
  }
}