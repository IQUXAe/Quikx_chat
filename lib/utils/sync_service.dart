import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:matrix/matrix.dart';

class SyncService {
  static Future<void> startSyncService(Client client) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sync_service',
        channelName: 'Matrix Sync',
        channelDescription: 'Синхронизация сообщений',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,

      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.once(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      notificationTitle: 'Синхронизация',
      notificationText: 'Получение новых сообщений...',
      callback: _syncCallback,
    );
  }

  @pragma('vm:entry-point')
  static void _syncCallback() {
    FlutterForegroundTask.setTaskHandler(SyncTaskHandler());
  }
}

class SyncTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    Logs().i('[SyncService] Foreground sync started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Sync is performed once
    FlutterForegroundTask.stopService();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool killProcess) async {
    Logs().i('[SyncService] Foreground sync completed');
  }
}