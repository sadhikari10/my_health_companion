import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as Notifications;
import 'package:my_health_companion/database.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:platform/platform.dart';
import 'dashboard.dart';
import 'dart:async';

class MedicationReminderPage extends StatefulWidget {
  final int userId;

  MedicationReminderPage({required this.userId});

  @override
  _MedicationReminderPageState createState() => _MedicationReminderPageState();
}

class _MedicationReminderPageState extends State<MedicationReminderPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  bool _isTimeMatch = false;
  final Notifications.FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      Notifications.FlutterLocalNotificationsPlugin();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flutterLocalNotificationsPlugin.cancelAll().then((_) {
      print('Cleared all existing notifications');
    });
    _initializeNotifications();
    _requestPermissions();
    _requestBatteryOptimizationExemption();
    _fetchData();
    _startTimeCheck();
  }

  void _startTimeCheck() {
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      _checkReminders();
    });
  }

  Future<void> _checkReminders() async {
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      print('Checking reminders at $currentTime');
      final reminders = await DatabaseHelper.instance.getMedicationReminders(widget.userId);
      bool foundMatch = false;

      for (var reminder in reminders) {
        if (reminder['reminder_time'] == currentTime) {
          foundMatch = true;
          final medication = _medications.firstWhere(
            (m) => m['disease_name'] == reminder['disease_name'],
            orElse: () => <String, dynamic>{},
          );
          if (medication.isNotEmpty) {
            print('Time match for ${reminder['disease_name']} at $currentTime');
            setState(() {
              _isTimeMatch = true;
            });
            await _triggerImmediateNotification(reminder['disease_name'], medication['medication_name']);
          }
        }
      }

      if (!foundMatch) {
        setState(() {
          _isTimeMatch = false;
        });
        print('No time match found at $currentTime');
      }
    } catch (e, stackTrace) {
      print('Error checking reminders: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error checking reminders: $e')));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('App resumed, re-checking notifications');
      _fetchData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      tz.initializeTimeZones();
      final kathmandu = tz.getLocation('Asia/Kathmandu');
      tz.setLocalLocation(kathmandu);
      print('Local timezone set to: ${tz.local.name}');

      const Notifications.AndroidInitializationSettings initializationSettingsAndroid =
          Notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
      const Notifications.InitializationSettings initializationSettings = Notifications.InitializationSettings(
        android: initializationSettingsAndroid,
      );
      final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (Notifications.NotificationResponse response) {
          print('Notification received: ID=${response.id}, Payload=${response.payload}');
        },
      );
      print('Notification initialization: ${initialized == true ? 'Success' : 'Failed'}');
      if (initialized != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to initialize notifications')),
          );
        }
        return;
      }

      const Notifications.AndroidNotificationChannel channel = Notifications.AndroidNotificationChannel(
        'medication_reminder_channel',
        'Medication Reminders',
        description: 'Notifications for medication reminders',
        importance: Notifications.Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        groupId: 'medication_group',
      );
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<Notifications.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      print('Notification channel created: medication_reminder_channel');

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<Notifications.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannelGroup(
            const Notifications.AndroidNotificationChannelGroup(
              'medication_group',
              'Medication Reminders Group',
            ),
          );
      print('Notification channel group created: medication_group');
    } catch (e, stackTrace) {
      print('Error initializing notifications: $e');
      print(stackTrace);
      if (e is MissingPluginException) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Notification plugin not found. Please restart the app.')),
          );
        }
      }
    }
  }

  Future<void> _requestPermissions() async {
    final notificationStatus = await Permission.notification.request();
    print('Notification permission: $notificationStatus');
    if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifications are required for reminders. Please enable in settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }

    final alarmStatus = await Permission.scheduleExactAlarm.request();
    print('Exact alarm permission: $alarmStatus');
    if (alarmStatus.isDenied || alarmStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exact alarms are required for timely reminders. Please enable in settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                if (const LocalPlatform().isAndroid) {
                  final intent = AndroidIntent(
                    action: 'android.settings.APP_NOTIFICATION_SETTINGS',
                    data: 'package:com.example.my_health_companion',
                  );
                  await intent.launch();
                } else {
                  openAppSettings();
                }
              },
            ),
          ),
        );
      }
    }

    if (const LocalPlatform().isAndroid) {
      final fullScreenStatus = await Permission.systemAlertWindow.status;
      print('Full-screen intent permission: $fullScreenStatus');
      if (fullScreenStatus.isDenied && !fullScreenStatus.isPermanentlyDenied) {
        final newStatus = await Permission.systemAlertWindow.request();
        print('Full-screen intent permission after request: $newStatus');
        if (newStatus.isDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Full-screen notifications are recommended. Please enable in settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () async {
                  final intent = AndroidIntent(
                    action: 'android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION',
                    data: 'package:com.example.my_health_companion',
                  );
                  await intent.launch();
                },
              ),
            ),
          );
        }
      }

      final dndStatus = await Permission.accessNotificationPolicy.status;
      print('Do Not Disturb permission: $dndStatus');
      if (dndStatus.isDenied && !dndStatus.isPermanentlyDenied) {
        final newDndStatus = await Permission.accessNotificationPolicy.request();
        print('Do Not Disturb permission after request: $newDndStatus');
        if (newDndStatus.isDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Do Not Disturb access is recommended. Please enable in settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () async {
                  final intent = AndroidIntent(
                    action: 'android.settings.NOTIFICATION_POLICY_ACCESS_SETTINGS',
                  );
                  await intent.launch();
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    if (const LocalPlatform().isAndroid) {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      print('Battery optimization status: $batteryStatus');
      if (batteryStatus.isDenied) {
        final intent = AndroidIntent(
          action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          data: 'package:com.example.my_health_companion',
        );
        try {
          await intent.launch();
          print('Battery optimization exemption requested');
        } catch (e, stackTrace) {
          print('Failed to request battery optimization exemption: $e');
          print(stackTrace);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to open battery optimization settings')),
            );
          }
        }
      }
    }
  }

  Future<void> _fetchData() async {
    try {
      final medications = await DatabaseHelper.instance.getUserMedications(widget.userId);
      final reminders = await DatabaseHelper.instance.getMedicationReminders(widget.userId);
      setState(() {
        _medications = medications;
        _reminders = reminders;
        _isLoading = false;
      });
      print('Fetched ${medications.length} medications and ${reminders.length} reminders');

      for (var reminder in reminders) {
        final medication = medications.firstWhere(
          (m) => m['disease_name'] == reminder['disease_name'],
          orElse: () => <String, dynamic>{},
        );
        if (medication.isNotEmpty) {
          final timeParts = reminder['reminder_time'].split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final now = tz.TZDateTime.now(tz.local);
          var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(Duration(days: 1));
          }
          print('Scheduling notification for ${reminder['disease_name']} at $scheduledTime');
          await _scheduleNotification(reminder['disease_name'], medication['medication_name'], scheduledTime);
        }
      }
    } catch (e, stackTrace) {
      print('Error fetching data: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setReminder(Map<String, dynamic> medication) async {
    final notificationStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final fullScreenStatus = const LocalPlatform().isAndroid
        ? await Permission.systemAlertWindow.status
        : PermissionStatus.granted;
    if (!notificationStatus.isGranted || !alarmStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please grant notification and exact alarm permissions.'),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
      return;
    }
    if (!batteryStatus.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disable battery optimization for reliable reminders.'),
          action: SnackBarAction(label: 'Disable', onPressed: _requestBatteryOptimizationExemption),
        ),
      );
    }
    if (!fullScreenStatus.isGranted && const LocalPlatform().isAndroid && !fullScreenStatus.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enable full-screen notifications for reminders.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () async {
              final intent = AndroidIntent(
                action: 'android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION',
                data: 'package:com.example.my_health_companion',
              );
              await intent.launch();
            },
          ),
        ),
      );
    }

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      final reminderTimeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
      }

      final reminder = {
        'user_id': widget.userId,
        'disease_name': medication['disease_name'],
        'reminder_time': reminderTimeStr,
      };

      print('Attempting to set reminder: $reminder at $scheduledTime');
      try {
        await DatabaseHelper.instance.insertMedicationReminder(reminder);
        print('Reminder inserted into database');

        await _scheduleNotification(medication['disease_name'], medication['medication_name'], scheduledTime);
        await _scheduleDebugNotification(scheduledTime);
        await _fetchData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reminder set for ${medication['disease_name']} at ${selectedTime.format(context)} daily')),
          );
        }
      } catch (e, stackTrace) {
        print('Error setting reminder: $e');
        print(stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error setting reminder: $e')));
        }
      }
    } else {
      print('No time selected');
    }
  }

  Future<void> _deleteReminder(int reminderId, String diseaseName) async {
    print('Deleting reminder ID: $reminderId for $diseaseName');
    try {
      await DatabaseHelper.instance.deleteMedicationReminder(reminderId);
      final notificationId = '${widget.userId}_$diseaseName'.hashCode;
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      print('Cancelled notification with ID: $notificationId');
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder for $diseaseName deleted')),
        );
      }
    } catch (e, stackTrace) {
      print('Error deleting reminder: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting reminder: $e')));
      }
    }
  }

  Future<void> _scheduleNotification(String diseaseName, String medicationName, tz.TZDateTime scheduledTime) async {
    print('Scheduling daily notification for $diseaseName at $scheduledTime');
    print('Current device time: ${DateTime.now()}');

    final now = tz.TZDateTime.now(tz.local);
    if (scheduledTime.difference(now).inSeconds < 5) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
      print('Adjusted scheduled time to next day: $scheduledTime');
    }

    const Notifications.AndroidNotificationDetails androidDetails = Notifications.AndroidNotificationDetails(
      'medication_reminder_channel',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Notifications.Importance.max,
      priority: Notifications.Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      visibility: Notifications.NotificationVisibility.public,
      fullScreenIntent: true,
      ticker: 'Medication Reminder',
      groupKey: 'medication_group',
    );
    const Notifications.NotificationDetails platformDetails = Notifications.NotificationDetails(android: androidDetails);

    final notificationId = '${widget.userId}_$diseaseName'.hashCode;
    try {
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        print('Notification permission not granted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification permission required. Please enable in settings.'),
              action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
            ),
          );
        }
        return;
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Time to take your medicine',
        'Medication: $medicationName for $diseaseName',
        scheduledTime,
        platformDetails,
        androidScheduleMode: Notifications.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: Notifications.UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: Notifications.DateTimeComponents.time,
        payload: 'medication_$diseaseName',
      );
      print('Daily notification scheduled for ID: $notificationId at $scheduledTime with payload: medication_$diseaseName');
    } catch (e, stackTrace) {
      print('Error scheduling notification: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule notification: $e')));
      }
    }
  }

  Future<void> _scheduleDebugNotification(tz.TZDateTime scheduledTime) async {
    print('Scheduling debug notification for $scheduledTime');
    const Notifications.AndroidNotificationChannel debugChannel = Notifications.AndroidNotificationChannel(
      'debug_channel',
      'Debug Notifications',
      description: 'Debug notifications for testing',
      importance: Notifications.Importance.low,
      showBadge: false,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<Notifications.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(debugChannel);

    const Notifications.AndroidNotificationDetails androidDetails = Notifications.AndroidNotificationDetails(
      'debug_channel',
      'Debug Notifications',
      channelDescription: 'Debug notifications for testing',
      importance: Notifications.Importance.low,
      priority: Notifications.Priority.low,
      visibility: Notifications.NotificationVisibility.public,
    );
    const Notifications.NotificationDetails platformDetails = Notifications.NotificationDetails(android: androidDetails);

    final debugId = 'debug_${scheduledTime.millisecondsSinceEpoch}'.hashCode;
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        debugId,
        'Debug: Notification Check',
        'Scheduled time: $scheduledTime',
        scheduledTime.add(Duration(seconds: 10)),
        platformDetails,
        androidScheduleMode: Notifications.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: Notifications.UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'debug_$debugId',
      );
      print('Debug notification scheduled for ID: $debugId at ${scheduledTime.add(Duration(seconds: 10))} with payload: debug_$debugId');
    } catch (e, stackTrace) {
      print('Error scheduling debug notification: $e');
      print(stackTrace);
    }
  }

  Future<void> _triggerImmediateNotification(String diseaseName, String medicationName) async {
    if (!_isTimeMatch) {
      print('No time match, skipping immediate notification for $diseaseName');
      return;
    }

    print('Triggering immediate notification for $diseaseName');
    const Notifications.AndroidNotificationDetails androidDetails = Notifications.AndroidNotificationDetails(
      'medication_reminder_channel',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Notifications.Importance.max,
      priority: Notifications.Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      visibility: Notifications.NotificationVisibility.public,
      fullScreenIntent: true,
      ticker: 'Medication Reminder',
    );
    const Notifications.NotificationDetails platformDetails = Notifications.NotificationDetails(android: androidDetails);

    final notificationId = '${widget.userId}_$diseaseName'.hashCode;
    try {
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        'Time to take your medicine',
        'Medication: $medicationName for $diseaseName',
        platformDetails,
      );
      print('Immediate notification triggered for $diseaseName with ID: $notificationId');
    } catch (e, stackTrace) {
      print('Error triggering immediate notification: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to trigger notification: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show background
      extendBodyBehindAppBar: true, // Extend image under AppBar
      appBar: AppBar(
        title: const Text('Medication Reminders'),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _medications.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No medications found. Add from Information Storage Page.',
                                      style: TextStyle(fontSize: 16, color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _medications.length,
                                    itemBuilder: (context, index) {
                                      final medication = _medications[index];
                                      final medicationReminders = _reminders
                                          .where((r) => r['disease_name'] == medication['disease_name'])
                                          .toList();
                                      return Card(
                                        color: Colors.white.withOpacity(0.9), // Semi-transparent
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                medication['disease_name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Medication: ${medication['medication_name']}',
                                                style: const TextStyle(color: Colors.black54),
                                              ),
                                              Text(
                                                'Dosage: ${medication['dosage']}',
                                                style: const TextStyle(color: Colors.black54),
                                              ),
                                              const SizedBox(height: 8),
                                              if (medicationReminders.isNotEmpty)
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Reminders:',
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    ...medicationReminders.map((reminder) => Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              reminder['reminder_time'],
                                                              style: const TextStyle(color: Colors.blue),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete, color: Colors.red),
                                                              onPressed: () => _deleteReminder(
                                                                reminder['id'],
                                                                reminder['disease_name'],
                                                              ),
                                                            ),
                                                          ],
                                                        )),
                                                  ],
                                                ),
                                              const SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: () => _setReminder(medication),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue.shade600,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: const Text('Add Reminder'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              final user = await DatabaseHelper.instance.getUserById(widget.userId);
                              if (user != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => DashboardPage(user: user)),
                                );
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: User not found')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: const Text('Return to Dashboard', style: TextStyle(fontSize: 16)),
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