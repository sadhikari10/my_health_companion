import 'package:flutter/material.dart';
import 'package:my_health_companion/database.dart';
import 'information_storage.dart';
import 'disease_details.dart';
import 'dashboard.dart';

class InformationListPage extends StatefulWidget {
  final String userEmail;

  InformationListPage({required this.userEmail});

  @override
  _InformationListPageState createState() => _InformationListPageState();
}

class _InformationListPageState extends State<InformationListPage> {
  int? _userId;
  List<Map<String, dynamic>> _medicationInfo = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndMedicationInfo();
  }

  Future<void> _loadUserAndMedicationInfo() async {
    final user = await DatabaseHelper.instance.getUser(widget.userEmail);
    if (user != null && user.containsKey('id')) {
      setState(() {
        _userId = user['id'];
      });
      await _loadMedicationInfo();
    }
  }

  Future<void> _loadMedicationInfo() async {
    if (_userId == null) return;
    final db = await DatabaseHelper.instance.database;
    try {
      final results = await db.rawQuery('''
        SELECT umi.*, d.category AS disease_category
        FROM user_medication_info umi
        LEFT JOIN diseases d ON TRIM(LOWER(umi.disease_name)) = TRIM(LOWER(d.name))
        WHERE umi.user_id = ?
      ''', [_userId]);
      setState(() {
        _medicationInfo = results;
      });
    } catch (e, stackTrace) {
      print('Error fetching medication info: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching medication info: $e')),
      );
    }
  }

  Future<void> _deleteMedicationInfo(int id) async {
    try {
      await DatabaseHelper.instance.deleteMedicationInfo(id);
      await _loadMedicationInfo(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Information deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting information: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(int id, String diseaseName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "$diseaseName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog (Cancel)
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteMedicationInfo(id); // Proceed with deletion
              },
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToDashboard() async {
    final user = await DatabaseHelper.instance.getUser(widget.userEmail);
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(user: user),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to load user data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show background
      extendBodyBehindAppBar: true, // Extend image under AppBar
      appBar: AppBar(
        title: Text('Disease List'),
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
                    'assets/images/list.jpg',
                    fit: BoxFit.cover, // Fill entire screen, may crop
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    errorBuilder: (context, error, stackTrace) {
                      print('Asset loading error: $error\n$stackTrace');
                      return Container(
                        color: Colors.red,
                        child: Center(child: Text('Failed to load image')),
                      );
                    },
                  );
                } catch (e) {
                  print('Exception loading asset: $e');
                  return Container(
                    color: Colors.red,
                    child: Center(child: Text('Exception loading image')),
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
            child: _medicationInfo.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No information stored yet.',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InformationStoragePage(userEmail: widget.userEmail),
                                ),
                              ).then((_) => _loadMedicationInfo());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text('Add Information'),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _navigateToDashboard,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text('Return to Dashboard'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: _medicationInfo.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _medicationInfo.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _navigateToDashboard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: Text('Return to Dashboard'),
                            ),
                          ),
                        );
                      }
                      final info = _medicationInfo[index];
                      final diseaseCategory = info['disease_category']?.toString() ?? 'Not Categorized';
                      return Card(
                        color: Colors.white.withOpacity(0.9), // Semi-transparent for readability
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            info['disease_name'] ?? 'Unknown Disease',
                            style: TextStyle(color: Colors.black87),
                          ),
                          subtitle: Text(
                            '${info['medication_name'] ?? 'No Medication'} | Category: $diseaseCategory',
                            style: TextStyle(color: Colors.black54),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DiseaseDetailsPage(info: info),
                                    ),
                                  ).then((result) {
                                    if (result == true) {
                                      _loadMedicationInfo();
                                    }
                                  });
                                },
                                tooltip: 'View Details',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(
                                    info['id'],
                                    info['disease_name'] ?? 'Unknown Disease',
                                  );
                                },
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _medicationInfo.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InformationStoragePage(userEmail: widget.userEmail),
                  ),
                ).then((_) => _loadMedicationInfo());
              },
              backgroundColor: Colors.blue.shade600,
              child: Icon(Icons.add, color: Colors.white),
              tooltip: 'Add Information',
            )
          : null,
    );
  }
}