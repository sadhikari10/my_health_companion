import 'package:flutter/material.dart';
import 'package:my_health_companion/database.dart';
import 'information_storage.dart';
import 'disease_details.dart';

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
    final results = await db.query(
      'user_medication_info',
      where: 'user_id = ?',
      whereArgs: [_userId],
    );
    setState(() {
      _medicationInfo = results;
    });
  }

  Future<void> _deleteMedicationInfo(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'user_medication_info',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadMedicationInfo(); // Refresh the list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Information deleted successfully')),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Information List')),
      body: _medicationInfo.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No information stored yet.'),
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
                    child: Text('Add Information'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                    ),
                    child: Text(
                      "Return to Dashboard",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                        ),
                        child: Text(
                          "Return to Dashboard",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
                final info = _medicationInfo[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(info['disease_name'] ?? 'Unknown Disease'),
                    subtitle: Text(info['medication_name'] ?? 'No Medication'),
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
              child: Icon(Icons.add),
              tooltip: 'Add Information',
            )
          : null,
    );
  }
}