import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:my_health_companion/database.dart';

class BootReceiver {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> onBoot() async {
    try {
      // Set timezone to Asia/Kathmandu
      try {
        final kathmandu = tz.getLocation('Asia/Kathmandu');
        tz.setLocalLocation(kathmandu);
        print('BootReceiver: Timezone set to ${tz.local.name}');
      } catch (e, stackTrace) {
        print('BootReceiver: Failed to set Asia/Kathmandu: $e');
        print(stackTrace);
        // Fallback: Set UTC timezone
        try {
          final utc = tz.getLocation('UTC');
          tz.setLocalLocation(utc);
          print('BootReceiver: Fallback to UTC timezone');
        } catch (fallbackError) {
          print('BootReceiver: Fallback timezone failed: $fallbackError');
          return; // Exit if timezone cannot be set
        }
      }

      // Initialize notifications
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _notificationsPlugin.initialize(initializationSettings);
      print('BootReceiver: Notifications initialized');

      // Create notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'medication_reminder_channel',
        'Medication Reminders',
        description: 'Notifications for medication reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      print('BootReceiver: Notification channel created');

      // Fetch all reminders from database
      final db = await DatabaseHelper.instance.database;
      final reminders = await db.query('medication_reminders');
      final medications = await db.query('user_medication_info');
      print('BootReceiver: Fetched ${reminders.length} reminders and ${medications.length} medications');

      for (var reminder in reminders) {
        final medication = medications.firstWhere(
          (m) => m['disease_name'] == reminder['disease_name'] && m['user_id'] == reminder['user_id'],
          orElse: () => <String, dynamic>{},
        );
        if (medication.isEmpty) {
          print('BootReceiver: No matching medication found for reminder: ${reminder['disease_name']}');
          continue;
        }

        // Check for valid reminder_time
        final reminderTime = reminder['reminder_time'] as String?;
        if (reminderTime == null || reminderTime.isEmpty) {
          print('BootReceiver: Invalid or null reminder_time for ${reminder['disease_name']}');
          continue;
        }

        try {
          final timeParts = reminderTime.split(':');
          if (timeParts.length != 2) {
            print('BootReceiver: Invalid time format for ${reminder['disease_name']}: $reminderTime');
            continue;
          }
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            print('BootReceiver: Invalid time values for ${reminder['disease_name']}: $reminderTime');
            continue;
          }

          final now = tz.TZDateTime.now(tz.local);
          var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(Duration(days: 1));
          }

          const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'medication_reminder_channel',
            'Medication Reminders',
            channelDescription: 'Notifications for medication reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
          );
          const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

          final notificationId = '${reminder['user_id']}_${reminder['disease_name']}'.hashCode;
          await _notificationsPlugin.zonedSchedule(
            notificationId,
            'Time to take your medicine',
            'Medication: ${medication['medication_name']} for ${reminder['disease_name']}',
            scheduledTime,
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          print('BootReceiver: Rescheduled notification for ${reminder['disease_name']} at $scheduledTime with ID: $notificationId');
        } catch (e, stackTrace) {
          print('BootReceiver: Error scheduling notification for ${reminder['disease_name']}: $e');
          print(stackTrace);
        }
      }
    } catch (e, stackTrace) {
      print('BootReceiver: General error in onBoot: $e');
      print(stackTrace);
    }
  }
}