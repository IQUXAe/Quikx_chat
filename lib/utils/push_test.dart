import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';
import '../config/app_config.dart';

class PushTest {
  static Future<void> showTestNotification(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    try {
      await plugin.show(
        999999,
        'Test Notification',
        'Push notifications are working! Tap to dismiss.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConfig.pushNotificationsChannelId,
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.high,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'test_ok',
                'OK',
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                'test_dismiss',
                'Dismiss',
                showsUserInterface: false,
              ),
            ],
          ),

        ),
      );
      Logs().i('[PushTest] Test notification shown with actions');
    } catch (e) {
      Logs().e('[PushTest] Failed to show test notification: $e');
    }
  }
}