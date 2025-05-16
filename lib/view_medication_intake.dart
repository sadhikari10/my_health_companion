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
      backgroundColor: Colors.transparent, // Transparent to show background
      extendBodyBehindAppBar: true, // Extend image under AppBar
      appBar: AppBar(
        title: const Text('View Medication Intake'),
        backgroundColor: Colors.white,
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
            child: Column(
              children: [
                // Horizontal line separator
                Container(
                  height: 1,
                  color: Colors.grey.shade400,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                // Main content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _medicationLogs.isEmpty
                          ? const Center(
                              child: Text(
                                'No medication logs found.',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: _medicationLogs.map((log) {
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: Colors.white.withOpacity(0.9), // Semi-transparent
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
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                          Text(
                                            'Time: ${log['log_time']}',
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                          Text(
                                            'Day: ${log['log_day']}',
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                          Text(
                                            'Status: ${log['taken'] == 1 ? 'Taken' : 'Not Taken'}',
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                        ],
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
                      backgroundColor: Colors.blueGrey,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}