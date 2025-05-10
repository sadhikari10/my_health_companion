import 'dart:async';
import 'package:intl/intl.dart';
import 'package:my_health_companion/database.dart';

class Scheduler {
  static final Scheduler instance = Scheduler._init();
  Timer? _timer;
  String? _lastDate;

  Scheduler._init();

  void startScheduler(int userId) {
    print('Starting scheduler for user ID: $userId');
    _lastDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(minutes: 60), (timer) async {
      try {
        final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (currentDate != _lastDate) {
          print('New day detected: $currentDate');
          await DatabaseHelper.instance.initializeDailyDoses(userId, currentDate);
          _lastDate = currentDate;
        } else {
          print('No new day, current date: $currentDate');
        }
      } catch (e, stackTrace) {
        print('Error in scheduler: $e');
        print(stackTrace);
      }
    });
  }

  void stopScheduler() {
    print('Stopping scheduler');
    _timer?.cancel();
    _timer = null;
    _lastDate = null;
  }
}