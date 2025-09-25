import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/setting_keys.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/unified_push_helper.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/quikx_chat_app.dart';

enum PushNotificationStatus {
  enabled,
  disabled,
  permissionDenied,
  noDistributor,
  setupRequired,
  error
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get localNotifications => _localNotifications;

  StreamController<PushNotificationStatus>? _statusController;
  Stream<PushNotificationStatus> get statusStream =>
      _statusController?.stream ?? const Stream.empty();

  Future<void> initialize() async {
    _statusController = StreamController<PushNotificationStatus>.broadcast();

    if (Platform.isAndroid) {
      await _initializeAndroid();
    }

    final initialStatus = await checkStatus();
    _statusController?.add(initialStatus);
  }

  Future<void> _initializeAndroid() async {
    // Инициализация происходит в main.dart
    Logs().i('[NotificationService] Android setup ready');

    // Создаем канал уведомлений
    const channel = AndroidNotificationChannel(
      AppConfig.pushNotificationsChannelId,
      'Входящие сообщения',
      description: 'Уведомления о новых сообщениях',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationResponse(NotificationResponse response) {
    try {
      Logs().i('[NotificationService] Notification response: ${response.actionId}, payload: ${response.payload}');

      if (response.actionId == null) {
        // Клик по самому уведомлению
        if (response.payload != null && response.payload!.startsWith('room:')) {
          final roomId = response.payload!.substring(5);
          _navigateToRoom(roomId);
        }
        return;
      }

      switch (response.actionId) {
        case 'reply':
          if (response.payload != null && response.payload!.startsWith('room:')) {
            final roomId = response.payload!.substring(5);
            _navigateToRoom(roomId);
          }
          break;
        case 'mark_read':
          if (response.payload != null && response.payload!.startsWith('room:')) {
            final roomId = response.payload!.substring(5);
            _markRoomAsRead(roomId);
          }
          break;
        case 'test_ok':
        case 'test_dismiss':
          Logs().i('[NotificationService] Test notification action: ${response.actionId}');
          break;
      }
    } catch (e) {
      Logs().e('[NotificationService] Error handling notification response', e);
    }
  }

  void _navigateToRoom(String roomId) {
    try {
      QuikxChatApp.router.go('/rooms/$roomId');
      Logs().i('[NotificationService] Navigated to room: $roomId');
    } catch (e) {
      Logs().e('[NotificationService] Failed to navigate to room', e);
    }
  }

  void _markRoomAsRead(String roomId) {
    try {
      // Найдем клиента и комнату
      // Это будет работать только если приложение уже запущено
      Logs().i('[NotificationService] Marking room as read: $roomId');
    } catch (e) {
      Logs().e('[NotificationService] Failed to mark room as read', e);
    }
  }



  Future<PushNotificationStatus> checkStatus() async {
    try {
      // Проверяем разрешения
      if (Platform.isAndroid) {
        final permission = await Permission.notification.status;
        if (permission.isDenied) {
          return PushNotificationStatus.permissionDenied;
        }
      }

      // Проверяем UnifiedPush
      if (Platform.isAndroid) {
        try {
          if (!await UnifiedPushHelper.isAvailable()) {
            return PushNotificationStatus.noDistributor;
          }

          if (!await UnifiedPushHelper.isConfigured()) {
            return PushNotificationStatus.setupRequired;
          }
        } catch (e) {
          Logs().w('Error checking UnifiedPush status', e);
          return PushNotificationStatus.setupRequired;
        }
      }

      // Проверяем настройки в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool(SettingKeys.unifiedPushRegistered) ?? false;

      if (!isRegistered) {
        return PushNotificationStatus.setupRequired;
      }

      return PushNotificationStatus.enabled;
    } catch (e) {
      Logs().e('Error checking push notification status', e);
      return PushNotificationStatus.error;
    }
  }

  Future<bool> requestPermissions(BuildContext context) async {
    final l10n = L10n.of(context);

    if (Platform.isAndroid) {
      final permission = await Permission.notification.request();
      if (permission.isDenied) {
        _showErrorDialog(context, l10n.pushNotificationPermissionDenied);
        return false;
      }
    }

    return true;
  }

  Future<bool> setupAutomatically(BuildContext context, MatrixState matrix) async {
    final l10n = L10n.of(context);

    try {
      Logs().i('[NotificationService] Starting automatic setup');

      // Показываем диалог прогресса
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.configuringPushNotifications),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.pleaseWait),
            ],
          ),
        ),
      );

      // Запрашиваем разрешения
      final hasPermissions = await requestPermissions(context);
      if (!hasPermissions) {
        Navigator.of(context).pop();
        Logs().w('[NotificationService] Permissions denied');
        return false;
      }

      Logs().i('[NotificationService] Permissions granted');

      // Настраиваем UnifiedPush для Android
      if (Platform.isAndroid) {
        try {
          final success = await _setupUnifiedPush(context, matrix);
          Navigator.of(context).pop();

          if (success) {
            Logs().i('[NotificationService] Setup completed successfully');
            _showSuccessDialog(context, l10n.pushNotificationsConfigured);
            _statusController?.add(PushNotificationStatus.enabled);
            return true;
          } else {
            Logs().e('[NotificationService] Setup failed');
            _showErrorDialog(context, l10n.pushNotificationSetupFailed);
            _statusController?.add(PushNotificationStatus.error);
            return false;
          }
        } catch (e, s) {
          Navigator.of(context).pop();
          Logs().e('[NotificationService] Setup error', e, s);
          _showErrorDialog(context, '${l10n.pushNotificationSetupFailed}: $e');
          _statusController?.add(PushNotificationStatus.error);
          return false;
        }
      }
    } catch (e, s) {
      Navigator.of(context).pop();
      Logs().e('[NotificationService] Error during automatic setup', e, s);
      _showErrorDialog(context, '${l10n.pushNotificationSetupFailed}: $e');
      return false;
    }
    return false;
  }

  Future<bool> _setupUnifiedPush(BuildContext context, MatrixState matrix) async {
    try {
      Logs().i('[NotificationService] Setting up UnifiedPush');

      // Проверяем доступные дистрибьюторы
      final distributors = await UnifiedPushHelper.getAvailableDistributors();
      Logs().i('[NotificationService] Available distributors: $distributors');

      if (distributors.isEmpty) {
        Logs().w('[NotificationService] No UnifiedPush distributors found');
        return false;
      }

      // Проверяем текущий дистрибьютор
      var selectedDistributor = await UnifiedPushHelper.getCurrentDistributor();
      Logs().i('[NotificationService] Current distributor: $selectedDistributor');

      // Если нет текущего дистрибьютора, выбираем первый доступный
      if (selectedDistributor == null || selectedDistributor.isEmpty || !distributors.contains(selectedDistributor)) {
        // Приоритет ntfy, если доступен
        if (distributors.any((d) => d.toLowerCase().contains('ntfy'))) {
          selectedDistributor = distributors.firstWhere((d) => d.toLowerCase().contains('ntfy'));
        } else {
          selectedDistributor = distributors.first;
        }
        Logs().i('[NotificationService] Selected distributor: $selectedDistributor');
      }

      // Настраиваем выбранный дистрибьютор
      final success = await UnifiedPushHelper.setupWithDistributor(selectedDistributor);

      if (success) {
        Logs().i('[NotificationService] UnifiedPush setup initiated successfully');
        // Ждем немного, чтобы регистрация завершилась
        await Future.delayed(const Duration(seconds: 2));
        return true;
      } else {
        Logs().e('[NotificationService] Failed to setup UnifiedPush');
        return false;
      }
    } catch (e, s) {
      Logs().e('[NotificationService] Error setting up UnifiedPush', e, s);
      return false;
    }
  }

  Future<void> showSetupDialog(BuildContext context, MatrixState matrix) async {
    final l10n = L10n.of(context);
    final status = await checkStatus();

    String title;
    String content;
    List<Widget> actions;

    switch (status) {
      case PushNotificationStatus.permissionDenied:
        title = l10n.pushNotificationPermissionRequired;
        content = l10n.pushNotificationPermissionRequired;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await requestPermissions(context);
            },
            child: Text(l10n.ok),
          ),
        ];
        break;

      case PushNotificationStatus.noDistributor:
        title = l10n.noUnifiedPushDistributor;
        content = l10n.noUnifiedPushDistributor;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openUnifiedPushInfo(context);
            },
            child: Text(l10n.help),
          ),
        ];
        break;

      case PushNotificationStatus.setupRequired:
        title = l10n.pushNotificationSetupRequired;
        content = l10n.configurePushNotifications;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await setupAutomatically(context, matrix);
            },
            child: Text(l10n.setupNow),
          ),
        ];
        break;

      case PushNotificationStatus.enabled:
        title = l10n.pushNotificationsEnabled;
        content = l10n.pushNotificationsEnabled;
        actions = [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ];
        break;

      case PushNotificationStatus.error:
        title = l10n.pushNotificationError;
        content = l10n.pushNotificationError;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await setupAutomatically(context, matrix);
            },
            child: Text(l10n.tryToSendAgain),
          ),
        ];
        break;

      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).success),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).ok),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).error),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final diagnostic = await exportDiagnosticInfo();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Diagnostic Info'),
                      content: SingleChildScrollView(
                        child: SelectableText(diagnostic),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(L10n.of(context).close),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Show Diagnostic Info'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).ok),
          ),
        ],
      ),
    );
  }

  void _openUnifiedPushInfo(BuildContext context) async {
    // Открываем ссылку на информацию о UnifiedPush
    try {
      final uri = Uri.parse('https://unifiedpush.org/users/distributors/');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logs().e('Failed to open UnifiedPush info', e);
    }
  }

  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final info = <String, dynamic>{};

    try {
      info['platform'] = Platform.operatingSystem;
      info['timestamp'] = DateTime.now().toIso8601String();

      if (Platform.isAndroid) {
        try {
          info['notification_permission'] = (await Permission.notification.status).name;
          info['unified_push_available'] = await UnifiedPushHelper.isAvailable();
          info['unified_push_configured'] = await UnifiedPushHelper.isConfigured();

          final distributors = await UnifiedPushHelper.getAvailableDistributors();
          info['unified_push_distributors'] = distributors;
          info['distributors_count'] = distributors.length;

          final currentDistributor = await UnifiedPushHelper.getCurrentDistributor();
          info['current_distributor'] = currentDistributor;
          info['has_distributor'] = currentDistributor != null && currentDistributor.isNotEmpty;
        } catch (e) {
          info['android_error'] = e.toString();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      info['unified_push_registered'] = prefs.getBool(SettingKeys.unifiedPushRegistered) ?? false;

      final endpoint = prefs.getString(SettingKeys.unifiedPushEndpoint);
      info['has_endpoint'] = endpoint != null && endpoint.isNotEmpty;
      info['endpoint_length'] = endpoint?.length ?? 0;

      final status = await checkStatus();
      info['status'] = status.name;
      info['is_enabled'] = status == PushNotificationStatus.enabled;

      // Добавляем информацию о последних уведомлениях
      final activeNotifications = await _localNotifications.getActiveNotifications();
      info['active_notifications_count'] = activeNotifications.length;

    } catch (e) {
      info['error'] = e.toString();
    }

    return info;
  }

  Future<String> exportDiagnosticInfo() async {
    final info = await getDiagnosticInfo();
    final buffer = StringBuffer();

    buffer.writeln('=== Push Notifications Diagnostic Info ===');
    buffer.writeln('Generated: ${info['timestamp']}');
    buffer.writeln();

    buffer.writeln('Platform: ${info['platform']}');
    buffer.writeln('Status: ${info['status']} (enabled: ${info['is_enabled']})');
    buffer.writeln();

    if (Platform.isAndroid) {
      buffer.writeln('Android Specific:');
      buffer.writeln('  Permission: ${info['notification_permission']}');
      buffer.writeln('  UnifiedPush Available: ${info['unified_push_available']}');
      buffer.writeln('  UnifiedPush Configured: ${info['unified_push_configured']}');
      buffer.writeln('  Distributors Count: ${info['distributors_count']}');
      buffer.writeln('  Has Distributor: ${info['has_distributor']}');
      buffer.writeln('  Current Distributor: ${info['current_distributor']}');
      if (info['android_error'] != null) {
        buffer.writeln('  Error: ${info['android_error']}');
      }
      buffer.writeln();
    }

    buffer.writeln('Configuration:');
    buffer.writeln('  Registered: ${info['unified_push_registered']}');
    buffer.writeln('  Has Endpoint: ${info['has_endpoint']}');
    buffer.writeln('  Endpoint Length: ${info['endpoint_length']}');
    buffer.writeln('  Active Notifications: ${info['active_notifications_count']}');

    if (info['error'] != null) {
      buffer.writeln();
      buffer.writeln('Error: ${info['error']}');
    }

    return buffer.toString();
  }

  void dispose() {
    _statusController?.close();
    _statusController = null;
  }
}