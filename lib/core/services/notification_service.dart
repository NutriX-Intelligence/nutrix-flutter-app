import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'meal_reminders_channel_v2';
  static const String channelName = 'Meal Reminders';
  static const String channelDescription = 'Daily reminders to log your meals';

  bool _isInitialized = false;

  NotificationService._();

  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('[NutriX Notifications] Already initialized, skipping.');
      return;
    }

    debugPrint('[NutriX Notifications] Starting initialization...');

    // --- Timezone setup ---
    try {
      tz.initializeTimeZones();
      debugPrint('[NutriX Notifications] Timezone database loaded.');
    } catch (e) {
      debugPrint('[NutriX Notifications] ERROR loading timezone database: $e');
    }

    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final tzName = timeZoneInfo.identifier;
      debugPrint('[NutriX Notifications] Device timezone: $tzName');
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('[NutriX Notifications] Local location set to: $tzName');
    } catch (e) {
      debugPrint('[NutriX Notifications] FlutterTimezone failed: $e');
      // Fallback: use DateTime.now() offset to guess timezone
      try {
        final offset = DateTime.now().timeZoneOffset;
        debugPrint('[NutriX Notifications] Fallback: UTC offset is ${offset.inHours}:${offset.inMinutes.remainder(60)}');
        // For IST (UTC+5:30), use Asia/Kolkata
        if (offset.inMinutes == 330) {
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
          debugPrint('[NutriX Notifications] Fallback set to Asia/Kolkata');
        } else {
          // Generic fallback: just use UTC
          debugPrint('[NutriX Notifications] Unknown offset, using UTC');
        }
      } catch (e2) {
        debugPrint('[NutriX Notifications] Fallback timezone also failed: $e2');
      }
    }

    // --- Plugin initialization ---
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final bool? initResult = await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    debugPrint('[NutriX Notifications] Plugin initialize() returned: $initResult');

    // --- Channel & permissions ---
    await _createChannelAndRequestPermissions();

    _isInitialized = true;
    debugPrint('[NutriX Notifications] ✅ Initialization complete!');
  }

  Future<void> _createChannelAndRequestPermissions() async {
    if (!Platform.isAndroid) return;

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) {
      debugPrint('[NutriX Notifications] ERROR: Could not get Android implementation');
      return;
    }

    // Request notification permission (Android 13+)
    final bool? notifGranted = await androidImpl.requestNotificationsPermission();
    debugPrint('[NutriX Notifications] Notification permission granted: $notifGranted');

    // Request exact alarms permission (Android 12+)
    try {
      final bool? exactGranted = await androidImpl.requestExactAlarmsPermission();
      debugPrint('[NutriX Notifications] Exact alarm permission granted: $exactGranted');
    } catch (e) {
      debugPrint('[NutriX Notifications] Exact alarm permission failed (non-fatal): $e');
    }

    // Request ignore battery optimizations (critical for Samsung/deep sleep)
    try {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        debugPrint('[NutriX Notifications] Requesting battery optimization ignore...');
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('[NutriX Notifications] Battery optimization request failed: $e');
    }

    // Create the channel explicitly
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );
    
    await androidImpl.createNotificationChannel(channel);
    debugPrint('[NutriX Notifications] Channel "$channelId" created.');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NutriX Notifications] Notification tapped: ${response.payload}');
  }

  // ========== TEST NOTIFICATION ==========
  
  /// Fires an immediate notification (not scheduled) to prove the system works.
  Future<void> showTestNotification() async {
    debugPrint('[NutriX Notifications] Firing immediate test notification...');
    
    try {
      await _notificationsPlugin.show(
        9999,
        '🎉 NutriX Notifications Work!',
        'Your meal reminders are all set up and ready to go.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      debugPrint('[NutriX Notifications] ✅ Test notification fired successfully!');
    } catch (e) {
      debugPrint('[NutriX Notifications] ❌ Test notification FAILED: $e');
    }
  }

  /// Schedules a notification for exactly 1 minute in the future to test scheduled alarms.
  Future<void> scheduleTestNotification() async {
    debugPrint('[NutriX Notifications] Scheduling a test notification for 1 minute from now...');
    
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    
    try {
      await _notificationsPlugin.zonedSchedule(
        9998,
        '⏰ Scheduled Test Worked!',
        'This notification was scheduled 1 minute ago.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('[NutriX Notifications] ✅ Scheduled test notification for $scheduledDate');
    } catch (e) {
      debugPrint('[NutriX Notifications] ❌ Scheduled test notification FAILED: $e');
    }
  }

  // ========== SCHEDULED NOTIFICATIONS ==========

  static const int breakfastId = 1001;
  static const int lunchId = 1002;
  static const int snacksId = 1003;
  static const int dinnerId = 1004;

  /// Schedules all daily meal reminders.
  Future<void> scheduleDailyReminders() async {
    if (!_isInitialized) {
      debugPrint('[NutriX Notifications] WARNING: Not initialized, cannot schedule!');
      return;
    }
    
    debugPrint('[NutriX Notifications] Scheduling daily reminders...');
    debugPrint('[NutriX Notifications] Current local time: ${tz.TZDateTime.now(tz.local)}');

    await _scheduleDailyNotification(
      id: breakfastId,
      title: 'Time for Breakfast!',
      body: 'Don\'t forget to log your breakfast today to stay on track.',
      hour: 10,
      minute: 30,
    );

    await _scheduleDailyNotification(
      id: lunchId,
      title: 'Lunch Reminder',
      body: 'Have you had lunch? Log it now in NutriX!',
      hour: 13, // 1:00 PM
      minute: 0,
    );

    await _scheduleDailyNotification(
      id: snacksId,
      title: 'Evening Snack',
      body: 'Keep your energy up! Log your evening snacks.',
      hour: 17, // 5:00 PM
      minute: 0,
    );

    await _scheduleDailyNotification(
      id: dinnerId,
      title: 'Dinner Time',
      body: 'End the day right. Log your dinner before you sleep.',
      hour: 1, // 1:00 AM for testing
      minute: 0,
    );

    // Verify what got scheduled
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('[NutriX Notifications] ✅ ${pending.length} notifications pending:');
    for (final n in pending) {
      debugPrint('  - id=${n.id}, title="${n.title}"');
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);
    debugPrint('[NutriX Notifications] Scheduling id=$id "$title" for $scheduledDate');

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[NutriX Notifications] ✅ Scheduled id=$id successfully');
    } catch (e) {
      debugPrint('[NutriX Notifications] ❌ FAILED to schedule id=$id: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancel and reschedule a meal notification for tomorrow.
  Future<void> cancelAndRescheduleForTomorrow(String mealType) async {
    int id;
    int hour;
    int minute = 0;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        id = breakfastId;
        hour = 10;
        minute = 30;
        break;
      case 'lunch':
        id = lunchId;
        hour = 13;
        break;
      case 'snacks':
      case 'snack':
        id = snacksId;
        hour = 17;
        break;
      case 'dinner':
        id = dinnerId;
        hour = 1;
        minute = 0;
        break;
      default:
        return;
    }

    await _notificationsPlugin.cancel(id);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime tomorrowDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, hour, minute);

    await _notificationsPlugin.zonedSchedule(
      id,
      _getTitleForMeal(mealType),
      _getBodyForMeal(mealType),
      tomorrowDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  String _getTitleForMeal(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast': return 'Time for Breakfast!';
      case 'lunch': return 'Lunch Reminder';
      case 'snacks':
      case 'snack': return 'Evening Snack';
      case 'dinner': return 'Dinner Time';
      default: return 'Meal Reminder';
    }
  }

  String _getBodyForMeal(String meal) {
     switch (meal.toLowerCase()) {
      case 'breakfast': return 'Don\'t forget to log your breakfast today to stay on track.';
      case 'lunch': return 'Have you had lunch? Log it now in NutriX!';
      case 'snacks':
      case 'snack': return 'Keep your energy up! Log your evening snacks.';
      case 'dinner': return 'End the day right. Log your dinner before you sleep.';
      default: return 'Log your meal!';
    }
  }
}
