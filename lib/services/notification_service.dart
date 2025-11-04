import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:lube_logger_companion_app/core/constants/app_constants.dart';
import 'package:lube_logger_companion_app/data/models/reminder.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Note: We use UTC directly, which doesn't require timezone database initialization
    // The tz.UTC constant is always available without initialization
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    _initialized = true;
  }
  
  static Future<bool> requestPermissions() async {
    if (!_initialized) {
      await initialize();
    }
    
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    
    bool? androidPermission = await android?.requestNotificationsPermission();
    bool? iosPermission = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    final androidGranted = androidPermission ?? false;
    final iosGranted = iosPermission ?? false;
    
    return androidGranted || iosGranted;
  }
  
  static Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_initialized) {
      await initialize();
    }
    
    final now = DateTime.now();
    final reminderDate = reminder.date;
    
    // Don't schedule if already past
    if (reminderDate.isBefore(now)) {
      return;
    }
    
    // Schedule notification based on urgency
    DateTime notificationTime;
    switch (reminder.urgency) {
      case ReminderUrgency.pastDue:
      case ReminderUrgency.veryUrgent:
        // Schedule immediately if past due or very urgent
        notificationTime = now.add(const Duration(seconds: 5));
        break;
      case ReminderUrgency.urgent:
        // Schedule 1 day before
        notificationTime = reminderDate.subtract(const Duration(days: 1));
        if (notificationTime.isBefore(now)) {
          notificationTime = now.add(const Duration(seconds: 5));
        }
        break;
      case ReminderUrgency.notUrgent:
        // Schedule 3 days before
        notificationTime = reminderDate.subtract(const Duration(days: 3));
        if (notificationTime.isBefore(now)) {
          notificationTime = reminderDate.subtract(const Duration(days: 1));
          if (notificationTime.isBefore(now)) {
            notificationTime = now.add(const Duration(seconds: 5));
          }
        }
        break;
    }
    
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Use zonedSchedule with UTC timezone
    await _notifications.zonedSchedule(
      reminder.id,
      'Reminder: ${reminder.title}',
      'Due: ${_formatDate(reminderDate)}',
      tz.TZDateTime.from(notificationTime, tz.UTC),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
  
  static Future<void> cancelReminderNotification(int reminderId) async {
    await _notifications.cancel(reminderId);
  }
  
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to reminder
    // This will be handled by the app's navigation system
  }
}
