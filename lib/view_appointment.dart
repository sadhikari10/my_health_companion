import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:my_health_companion/database.dart';
import 'dashboard.dart';

class ViewAppointmentPage extends StatefulWidget {
  final int userId;

  ViewAppointmentPage({required this.userId});

  @override
  _ViewAppointmentPageState createState() => _ViewAppointmentPageState();
}

class _ViewAppointmentPageState extends State<ViewAppointmentPage> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointments = await DatabaseHelper.instance.getAppointments(widget.userId);
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching appointments: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching appointments: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAppointment(int id, String appointmentType) async {
    try {
      await DatabaseHelper.instance.deleteAppointment(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$appointmentType deleted successfully')),
      );
      await _fetchAppointments(); // Refresh the appointments list and calendar
    } catch (e, stackTrace) {
      print('Error deleting appointment: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting appointment: $e')),
      );
    }
  }

  void _showDeleteConfirmDialog(int id, String appointmentType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this $appointmentType?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deleteAppointment(id, appointmentType); // Delete the appointment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _getEventsForDay() {
    final events = <DateTime, List<Map<String, dynamic>>>{};
    final dateFormatter = DateFormat('yyyy-MM-dd');
    for (var appointment in _appointments) {
      final date = DateTime.parse(appointment['appointment_date']);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (!events.containsKey(normalizedDate)) {
        events[normalizedDate] = [];
      }
      events[normalizedDate]!.add(appointment);
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay();
    // Compute the event list for the selected or focused day
    final eventList = _selectedDay != null
        ? events[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? []
        : events[DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day)] ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('View Appointments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.blue.shade50,
          ),
          Positioned.fill(
            child: Builder(
              builder: (context) {
                try {
                  return Image.asset(
                    'assets/images/medical_image.jpg',
                    fit: BoxFit.cover,
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
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 1,
                  color: Colors.grey.shade400,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _appointments.isEmpty
                          ? const Center(
                              child: Text(
                                'No appointments found. Add some in the Appointments page.',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Card(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: TableCalendar(
                                      firstDay: DateTime(2000),
                                      lastDay: DateTime(2100),
                                      focusedDay: _focusedDay,
                                      calendarFormat: _calendarFormat,
                                      selectedDayPredicate: (day) {
                                        return isSameDay(_selectedDay, day);
                                      },
                                      onDaySelected: (selectedDay, focusedDay) {
                                        setState(() {
                                          _selectedDay = selectedDay;
                                          _focusedDay = focusedDay;
                                        });
                                      },
                                      onFormatChanged: (format) {
                                        setState(() {
                                          _calendarFormat = format;
                                        });
                                      },
                                      eventLoader: (day) {
                                        final normalizedDay = DateTime(day.year, day.month, day.day);
                                        return events[normalizedDay] ?? [];
                                      },
                                      calendarStyle: CalendarStyle(
                                        todayDecoration: BoxDecoration(
                                          color: Colors.blue.shade300,
                                          shape: BoxShape.circle,
                                        ),
                                        selectedDecoration: BoxDecoration(
                                          color: Colors.blue.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                        markerDecoration: BoxDecoration(
                                          color: Colors.blue.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      calendarBuilders: CalendarBuilders(
                                        markerBuilder: (context, date, events) {
                                          if (events.isNotEmpty) {
                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: events.map((event) {
                                                final mapEvent = event as Map<String, dynamic>;
                                                final color = mapEvent['appointment_type'] == 'last_appointment'
                                                    ? Colors.blue
                                                    : Colors.green;
                                                return Container(
                                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Generate Card widgets directly in the for loop
                                  for (var event in eventList)
                                    Card(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    event['appointment_type'] == 'last_appointment'
                                                        ? 'Last Appointment'
                                                        : 'Follow-Up Appointment',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      color: event['appointment_type'] == 'last_appointment'
                                                          ? Colors.blue.shade600
                                                          : Colors.green.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Date: ${event['appointment_date']}',
                                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                  ),
                                                  Text(
                                                    'Time: ${event['appointment_time']}',
                                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                  ),
                                                  Text(
                                                    'Day: ${event['appointment_day']}',
                                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red.shade600),
                                              onPressed: () {
                                                _showDeleteConfirmDialog(
                                                  event['id'],
                                                  event['appointment_type'] == 'last_appointment'
                                                      ? 'Last Appointment'
                                                      : 'Follow-Up Appointment',
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 20),
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