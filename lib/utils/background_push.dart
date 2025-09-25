/*
 *   Famedly
 *   Copyright (C) 2020, 2021 Famedly GmbH
 *   Copyright (C) 2021 Fluffychat
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:unifiedpush_ui/unifiedpush_ui.dart';

import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/services/message_handler.dart';
import 'package:quikxchat/services/pusher_service.dart';
import 'package:quikxchat/utils/push_helper.dart';
import 'package:quikxchat/utils/notification_service.dart';
import 'package:quikxchat/utils/file_logger.dart';
import 'package:quikxchat/utils/network_error_handler.dart';
import 'package:quikxchat/widgets/quikx_chat_app.dart';
import '../config/app_config.dart';
import '../config/setting_keys.dart';
import '../widgets/matrix.dart';
import 'platform_infos.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  print('[Push] ==> Background tap: action=${response.actionId}, payload=${response.payload}');
}

class BackgroundPush {
  static BackgroundPush? _instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Getter для доступа к плагину уведомлений из main.dart
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _flutterLocalNotificationsPlugin;
  Client client;
  MatrixState? matrix;
  void Function(String errorMsg, {Uri? link})? onFcmError;
  L10n? l10n;

  Future<void> loadLocale() async {
    final context = matrix?.context;
    // inspired by _lookupL10n in .dart_tool/flutter_gen/gen_l10n/l10n.dart
    l10n ??= (context != null ? L10n.of(context) : null) ??
        (await L10n.delegate.load(PlatformDispatcher.instance.locale));
  }

  final pendingTests = <String, Completer<void>>{};
  
  // Кэш для проверок gateway
  static final Map<String, bool> _gatewayCache = {};

  DateTime? lastReceivedPush;

  bool upAction = false;

  late final PusherService _pusherService;
  late final MessageHandler _messageHandler;

  void _init() async {
    _pusherService = PusherService(client);
    _messageHandler = MessageHandler(client, l10n: l10n, matrix: matrix);
    try {
      // Запрашиваем разрешения на уведомления сразу при инициализации
      if (Platform.isAndroid) {
        await _requestNotificationPermissions();
      }
      
      // Используем уже инициализированный экземпляр из PushNotificationManager
      Logs().i('[BackgroundPush] Using PushNotificationManager instance');
      
      // Создаем канал уведомлений для Android
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          AppConfig.pushNotificationsChannelId,
          'Incoming Messages',
          description: 'Notifications for incoming messages',
          importance: Importance.high,
        );
        
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
        
        Logs().i('[BackgroundPush] Android notification channel created');
      }
      
      // Initialize UnifiedPush for Android
      if (Platform.isAndroid) {
        try {
          await UnifiedPush.initialize(
            onNewEndpoint: _newUpEndpoint,
            onRegistrationFailed: (reason, i) {
              FileLogger.log('[BackgroundPush] UnifiedPush registration failed: ${reason.name}');
              _upUnregistered(i);
            },
            onUnregistered: _upUnregistered,
            onMessage: _onUpMessage,
          );
          Logs().i('[BackgroundPush] UnifiedPush initialized successfully');
        } catch (e, s) {
          Logs().w('[BackgroundPush] Failed to initialize UnifiedPush', e, s);
        }
      }
      
      // PushNotificationManager инициализируется в main.dart, здесь не дублируем
      
    } catch (e, s) {
      Logs().e('[BackgroundPush] Critical error during initialization', e, s);
    }
  }

  BackgroundPush._(this.client) {
    _init();
  }

  factory BackgroundPush.clientOnly(Client client) {
    return _instance ??= BackgroundPush._(client);
  }

  factory BackgroundPush(
    MatrixState matrix, {
    final void Function(String errorMsg, {Uri? link})? onFcmError,
  }) {
    final instance = BackgroundPush.clientOnly(matrix.client);
    instance.matrix = matrix;
    instance.onFcmError = onFcmError;
    return instance;
  }

  Future<void> cancelNotification(String roomId) async {
    Logs().v('Cancel notification for room', roomId);
    await NotificationService.instance.localNotifications.cancel(roomId.hashCode);
  }

  static bool _wentToRoomOnStartup = false;

  Future<void> setupPush() async {
    Logs().i('[BackgroundPush] Starting push setup');
    
    // Проверяем основные условия
    if (client.onLoginStateChanged.value != LoginState.loggedIn) {
      Logs().w('[BackgroundPush] Client not logged in, skipping push setup');
      return;
    }
    
    if (!PlatformInfos.isMobile) {
      Logs().i('[BackgroundPush] Not a mobile platform, skipping push setup');
      return;
    }
    
    if (matrix == null) {
      Logs().w('[BackgroundPush] Matrix state is null, skipping push setup');
      return;
    }
    
    // Не настраиваем UnifiedPush, если он уже инициализирован
    if (upAction) {
      Logs().i('[BackgroundPush] UnifiedPush action already in progress, skipping setup');
      return;
    }
    
    // Проверяем статус уведомлений
    try {
      final status = await NotificationService.instance.checkStatus();
      Logs().i('[BackgroundPush] Current push notification status: ${status.name}');
      
      // Автоматически настраиваем, если нужно
      if (status == PushNotificationStatus.setupRequired ||
          status == PushNotificationStatus.disabled ||
          status == PushNotificationStatus.noDistributor) {
        Logs().i('[BackgroundPush] Attempting automatic push setup');
        try {
          await _autoSetupUnifiedPush();
          Logs().i('[BackgroundPush] Automatic push setup completed');
        } catch (e, s) {
          Logs().w('[BackgroundPush] Failed to auto-setup push notifications', e, s);
        }
      } else if (status == PushNotificationStatus.enabled) {
        Logs().i('[BackgroundPush] Push notifications already enabled');
      }
    } catch (e, s) {
      Logs().w('[BackgroundPush] Error checking push notification status', e, s);
    }

    // Обрабатываем запуск приложения по уведомлению
    try {
      final details = await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && 
          details.didNotificationLaunchApp && 
          !_wentToRoomOnStartup &&
          details.notificationResponse != null) {
        _wentToRoomOnStartup = true;
        Logs().i('[BackgroundPush] App launched from notification, navigating to room');
        await goToRoom(details.notificationResponse);
      }
    } catch (e, s) {
      Logs().w('[BackgroundPush] Error handling notification app launch', e, s);
    }
    
    Logs().i('[BackgroundPush] Push setup completed');
  }

  Future<void> _noUpWarning() async {
    if (matrix == null) {
      return;
    }
    if ((matrix?.store.getBool(SettingKeys.showNoGoogle) ?? false) == true) {
      return;
    }
    await loadLocale();
    
    // Проверяем доступность UnifiedPush перед показом предупреждения
    try {
      final distributors = await UnifiedPush.getDistributors([]);
      if (distributors.isNotEmpty) {
        return; // UnifiedPush доступен, предупреждение не нужно
      }
    } catch (e) {
      // Игнорируем ошибки проверки UnifiedPush
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onFcmError?.call(
        l10n!.noGoogleServicesWarning,
        link: Uri.parse(
          AppConfig.enablePushTutorial,
        ),
      );
    });
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    print('[Push] HANDLER CALLED: ${response.actionId}');
    Logs().i('[Push] HANDLER CALLED: actionId=${response.actionId}, payload=${response.payload}, input=${response.input}');
    
    final actionId = response.actionId;
    final payload = response.payload;
    final input = response.input;
    
    try {
      if (actionId != null) {
        print('[Push] Processing action: $actionId');
        
        if (actionId.startsWith('reply_')) {
          final roomId = actionId.substring('reply_'.length);
          print('[Push] Reply to room: $roomId, message: $input');
          await handleReplyAction(roomId, input);
          return;
        } else if (actionId.startsWith('mark_read_')) {
          final roomId = actionId.substring('mark_read_'.length);
          print('[Push] Mark read room: $roomId');
          await handleMarkAsReadAction(roomId);
          return;
        }
      }
      
      print('[Push] Opening room: $payload');
      await goToRoom(response);
    } catch (e, s) {
      print('[Push] Handler error: $e');
      Logs().e('[Push] Error handling notification response', e, s);
    }
  }
  
  Future<void> handleReplyAction(String roomId, String? message) async {
    Logs().i('[Push] Handling reply action for room $roomId');
    
    if (message == null || message.trim().isEmpty) {
      Logs().w('[Push] Empty message for reply, ignoring');
      return;
    }
    
    final trimmedMessage = message.trim();
    Logs().i('[Push] Reply message: "$trimmedMessage"');
    
    try {
      // Убираем уведомление
      await _flutterLocalNotificationsPlugin.cancel(roomId.hashCode);
      
      // Проверяем состояние клиента
      if (client.onLoginStateChanged.value != LoginState.loggedIn) {
        Logs().w('[Push] Client not logged in, cannot send reply');
        return;
      }
      
      // Обеспечиваем синхронизацию
      if (client.roomsLoading != null) {
        Logs().i('[Push] Waiting for rooms to load...');
        await client.roomsLoading!.timeout(const Duration(seconds: 10));
      }
      
      // Проверяем состояние синхронизации
      if (client.onSyncStatus.value == SyncStatus.error) {
        Logs().i('[Push] Sync in error state, attempting one-shot sync');
        await client.oneShotSync().timeout(const Duration(seconds: 15));
      }
      
      final room = client.getRoomById(roomId);
      if (room == null) {
        Logs().w('[Push] Room $roomId not found, attempting to wait for it');
        try {
          await client.waitForRoomInSync(roomId).timeout(const Duration(seconds: 10));
          final roomAfterWait = client.getRoomById(roomId);
          if (roomAfterWait == null) {
            Logs().e('[Push] Room $roomId still not found after waiting');
            return;
          }
        } catch (e) {
          Logs().e('[Push] Failed to wait for room $roomId', e);
          return;
        }
      }
      
      final finalRoom = client.getRoomById(roomId)!;
      Logs().i('[Push] Sending reply to room "${finalRoom.displayname}"');
      
      await finalRoom.sendTextEvent(trimmedMessage).timeout(const Duration(seconds: 20));
      Logs().i('[Push] ✓ Reply sent successfully to room $roomId');
      
    } catch (e, s) {
      Logs().e('[Push] ✗ Failed to send reply to room $roomId', e, s);
      
      // Показываем уведомление об ошибке
      await _showErrorNotification('Failed to send reply: ${e.toString()}');
    }
  }
  
  Future<void> _showErrorNotification(String error) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        999998,
        'Error',
        error,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'errors',
            'Error Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      Logs().e('[Push] Failed to show error notification', e);
    }
  }
  
  Future<void> handleMarkAsReadAction(String roomId) async {
    Logs().i('[Push] Handling mark as read action for room $roomId');
    
    try {
      // Убираем уведомление сразу
      await _flutterLocalNotificationsPlugin.cancel(roomId.hashCode);
      
      // Проверяем состояние клиента
      if (client.onLoginStateChanged.value != LoginState.loggedIn) {
        Logs().w('[Push] Client not logged in, cannot mark as read');
        return;
      }
      
      // Обеспечиваем синхронизацию
      if (client.roomsLoading != null) {
        Logs().i('[Push] Waiting for rooms to load...');
        await client.roomsLoading!.timeout(const Duration(seconds: 10));
      }
      
      final room = client.getRoomById(roomId);
      if (room == null) {
        Logs().w('[Push] Room $roomId not found for mark as read');
        return;
      }
      
      Logs().i('[Push] Marking room "${room.displayname}" as read');
      
      // Отмечаем как прочитанное
      if (room.lastEvent != null) {
        await room.setReadMarker(
          room.lastEvent!.eventId,
          mRead: room.lastEvent!.eventId,
        ).timeout(const Duration(seconds: 10));
      } else {
        await room.markUnread(false).timeout(const Duration(seconds: 10));
      }
      
      Logs().i('[Push] ✓ Room $roomId marked as read successfully');
      
    } catch (e, s) {
      Logs().e('[Push] ✗ Failed to mark room $roomId as read', e, s);
    }
  }

  Future<void> goToRoom(NotificationResponse? response) async {
    try {
      final roomId = response?.payload;
      Logs().v('[Push] Attempting to go to room $roomId...');
      if (roomId == null) {
        return;
      }
      await client.roomsLoading;
      await client.accountDataLoading;
      if (client.getRoomById(roomId) == null) {
        await client
            .waitForRoomInSync(roomId)
            .timeout(const Duration(seconds: 30));
      }
      QuikxChatApp.router.go(
        client.getRoomById(roomId)?.membership == Membership.invite
            ? '/rooms'
            : '/rooms/$roomId',
      );
    } catch (e, s) {
      Logs().e('[Push] Failed to open room', e, s);
    }
  }

  Future<void> recreatePushSetup() async {
    Logs().i('[BackgroundPush] === RECREATING PUSH SETUP ===');
    
    try {
      // Удаляем все старые pusher'ы
      final pushers = await client.getPushers();
      if (pushers != null) {
        for (final pusher in pushers) {
          if (pusher.appId.startsWith(AppConfig.pushNotificationsAppId)) {
            try {
              await client.deletePusher(pusher);
              Logs().i('[BackgroundPush] Deleted old pusher: ${pusher.appId}');
            } catch (e) {
              Logs().w('[BackgroundPush] Failed to delete pusher: $e');
            }
          }
        }
      }
      
      // Очищаем локальные настройки
      await matrix?.store.setBool(SettingKeys.unifiedPushRegistered, false);
      await matrix?.store.remove(SettingKeys.unifiedPushEndpoint);
      
      // Перерегистрируем UnifiedPush
      try {
        await UnifiedPush.unregister();
        await Future.delayed(const Duration(seconds: 1));
        await UnifiedPush.register(instance: 'default', features: ['bytes_message']);
        Logs().i('[BackgroundPush] UnifiedPush re-registered');
      } catch (e, s) {
        Logs().e('[BackgroundPush] Failed to re-register UnifiedPush', e, s);
      }
      
    } catch (e, s) {
      Logs().e('[BackgroundPush] Error recreating push setup', e, s);
    }
    
    Logs().i('[BackgroundPush] === PUSH SETUP RECREATION COMPLETE ===');
  }

  Future<void> _autoSetupUnifiedPush() async {
    try {
      // Проверяем доступные дистрибьюторы
      final distributors = await UnifiedPush.getDistributors(['bytes_message']);
      
      if (distributors.isNotEmpty) {
        // Автоматически выбираем первый доступный дистрибьютор
        await UnifiedPush.saveDistributor(distributors.first);
        await UnifiedPush.register(instance: 'default', features: ['bytes_message']);
        Logs().i('[BackgroundPush] Auto-selected distributor: ${distributors.first}');
      } else {
        Logs().w('[BackgroundPush] No UnifiedPush distributors available for auto-setup');
      }
    } catch (e, s) {
      Logs().e('[BackgroundPush] Auto UnifiedPush setup failed', e, s);
      // Падбэк к ручной настройке
      await setupUp();
    }
  }

  Future<void> setupUp() async {
    try {
      Logs().i('[BackgroundPush] Setting up UnifiedPush UI');
      
      if (matrix?.context == null) {
        Logs().w('[BackgroundPush] Matrix context is null, cannot show UnifiedPush UI');
        return;
      }
      
      final upFunctions = UPFunctions();
      final unifiedPushUi = UnifiedPushUi(
        matrix!.context, 
        ["default"], 
        upFunctions,
      );
      
      await unifiedPushUi.registerAppWithDialog();
      Logs().i('[BackgroundPush] UnifiedPush UI setup completed');
      
    } catch (e, s) {
      Logs().e('[BackgroundPush] Error setting up UnifiedPush UI', e, s);
      // Пытаемся настроить без UI
      try {
        Logs().i('[BackgroundPush] Attempting fallback UnifiedPush setup');
        final distributors = await UnifiedPush.getDistributors(['bytes_message']);
        if (distributors.isNotEmpty) {
          await UnifiedPush.saveDistributor(distributors.first);
          await UnifiedPush.register(instance: 'default', features: ['bytes_message']);
          Logs().i('[BackgroundPush] Fallback UnifiedPush setup completed');
        } else {
          Logs().w('[BackgroundPush] No UnifiedPush distributors available');
        }
      } catch (fallbackError, fallbackStack) {
        Logs().e('[BackgroundPush] Fallback UnifiedPush setup also failed', fallbackError, fallbackStack);
      }
    }
  }

  Future<void> _newUpEndpoint(PushEndpoint newPushEndpoint, String i) async {
    final newEndpoint = newPushEndpoint.url;
    upAction = true;
    
    Logs().i('[Push] New UnifiedPush endpoint received: $newEndpoint');
    
    if (newEndpoint.isEmpty) {
      Logs().w('[Push] Empty endpoint received, unregistering');
      await _upUnregistered(i);
      return;
    }
    
    // По умолчанию используем официальный gateway
    var endpoint = 'https://matrix.gateway.unifiedpush.org/_matrix/push/v1/notify';
    
    // Проверяем, есть ли собственный Matrix gateway (но не ntfy.sh)
    if (!newEndpoint.contains('ntfy.sh')) {
      final testUrl = Uri.parse(newEndpoint).replace(
        path: '/_matrix/push/v1/notify',
        query: '',
      );
      final testUrlString = testUrl.toString();
      
      // Проверяем кэш
      if (_gatewayCache.containsKey(testUrlString)) {
        if (_gatewayCache[testUrlString] == true) {
          endpoint = testUrlString;
          Logs().i('[Push] Using cached self-hosted Matrix gateway: $endpoint');
        }
      } else {
        try {
          Logs().i('[Push] Testing gateway at: $testUrl');
          
          final response = await http.get(testUrl).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200 || response.statusCode == 405) {
            try {
              final responseBody = utf8.decode(response.bodyBytes);
              final res = json.decode(responseBody);
              
              if (res['gateway'] == 'matrix' ||
                  (res['unifiedpush'] is Map &&
                      res['unifiedpush']['gateway'] == 'matrix')) {
                endpoint = testUrlString;
                _gatewayCache[testUrlString] = true;
                Logs().i('[Push] Using self-hosted Matrix gateway: $endpoint');
              } else {
                _gatewayCache[testUrlString] = false;
              }
            } catch (e) {
              // Ошибка парсинга JSON, но сервер отвечает
              _gatewayCache[testUrlString] = false;
              Logs().i('[Push] Gateway responds but no valid JSON, using default');
            }
          } else {
            _gatewayCache[testUrlString] = false;
          }
        } catch (e) {
          _gatewayCache[testUrlString] = false;
          Logs().i('[Push] No self-hosted unified push gateway present: $newEndpoint', e);
        }
      }
    } else {
      Logs().i('[Push] Using ntfy.sh, forcing official Matrix gateway');
    }
    
    Logs().i('[Push] Final gateway URL: $endpoint');
    
    // Проверяем, что gateway URL доступен
    try {
      final testResponse = await http.head(Uri.parse(endpoint)).timeout(const Duration(seconds: 5));
      Logs().i('[Push] Gateway accessibility test: ${testResponse.statusCode}');
    } catch (e) {
      Logs().w('[Push] Gateway may not be accessible: $e');
      // Не блокируем настройку, если gateway недоступен для тестирования
    }
    
    // Получаем старые токены для удаления
    final oldTokens = <String?>{};
    final oldEndpoint = matrix?.store.getString(SettingKeys.unifiedPushEndpoint);
    if (oldEndpoint != null && oldEndpoint != newEndpoint) {
      oldTokens.add(oldEndpoint);
      Logs().i('[Push] Will remove old endpoint: $oldEndpoint');
    }
    
    // Настраиваем pusher
    await _pusherService.setupPusher(
      gatewayUrl: endpoint,
      token: newEndpoint,
      oldTokens: oldTokens,
      useDeviceSpecificAppId: true,
    );
    
    // Принудительно синхронизируемся для получения обновлений
    try {
      await NetworkErrorHandler.retryOnNetworkError(
        () => client.oneShotSync(),
        maxRetries: 1,
        initialDelay: const Duration(milliseconds: 500),
      );
      Logs().i('[Push] One-shot sync completed after pusher setup');
    } catch (e, s) {
      Logs().w('[Push] One-shot sync failed after pusher setup: ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
    }
    
    // Сохраняем новые настройки
    await matrix?.store.setString(SettingKeys.unifiedPushEndpoint, newEndpoint);
    await matrix?.store.setBool(SettingKeys.unifiedPushRegistered, true);
    
    Logs().i('[Push] UnifiedPush endpoint setup completed successfully');
  }

  Future<void> _upUnregistered(String i) async {
    upAction = true;
    Logs().i('[Push] Removing UnifiedPush endpoint...');
    final oldEndpoint =
        matrix?.store.getString(SettingKeys.unifiedPushEndpoint);
    await matrix?.store.setBool(SettingKeys.unifiedPushRegistered, false);
    await matrix?.store.remove(SettingKeys.unifiedPushEndpoint);
    if (oldEndpoint?.isNotEmpty ?? false) {
      // remove the old pusher
      await _pusherService.setupPusher(
        oldTokens: {oldEndpoint},
      );
    }
  }

  static int _activeSyncs = 0;
  static const int _maxConcurrentSyncs = 2;
  
  Future<void> _performReliableSyncWithService() async {
    if (_activeSyncs >= _maxConcurrentSyncs) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }
    
    _activeSyncs++;
    try {
      await _performReliableSync();
    } finally {
      _activeSyncs--;
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Запрашиваем только разрешения на уведомления
        final granted = await androidPlugin.requestNotificationsPermission();
        Logs().i('[BackgroundPush] Notification permission granted: $granted');
      }
    } catch (e, s) {
      Logs().w('[BackgroundPush] Failed to request notification permissions', e, s);
    }
  }

  Future<void> _performReliableSync() async {
    var attempts = 0;
    const maxAttempts = 3; // Уменьшено для производительности
    
    while (attempts < maxAttempts) {
      try {
        if (client.onLoginStateChanged.value == LoginState.loggedIn) {
          // Проверяем сеть только при первой попытке
          if (attempts == 0 && !await NetworkErrorHandler.isNetworkAvailable()) {
            await NetworkErrorHandler.waitForNetwork(timeout: const Duration(seconds: 10));
          }
          
          // Легкое переподключение только при ошибках
          if (client.onSyncStatus.value == SyncStatus.error && attempts > 0) {
            try {
              await client.checkHomeserver(client.homeserver!).timeout(const Duration(seconds: 8));
            } catch (_) {}
          }
          
          // Оптимизированная синхронизация
          await client.oneShotSync().timeout(const Duration(seconds: 20));
          
          if (client.onSyncStatus.value == SyncStatus.finished) {
            return;
          }
        }
      } catch (e) {
        attempts++;
        
        // Оптимизированная задержка
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(seconds: [1, 3, 5][attempts - 1]));
        }
      }
    }
    
    await _showFallbackNotification('Sync failed');
  }
  


  Future<void> _onUpMessage(PushMessage pushMessage, String i) async {
    upAction = true;
    await _messageHandler.onUpMessage(pushMessage, i);
  }
}

class UPFunctions extends UnifiedPushFunctions {
  final List<String> features = [
    /*list of features*/
  ];

  @override
  Future<String?> getDistributor() async {
    return await UnifiedPush.getDistributor();
  }

  @override
  Future<List<String>> getDistributors() async {
    return await UnifiedPush.getDistributors(features);
  }

  @override
  Future<void> registerApp(String instance) async {
    await UnifiedPush.register(instance: instance, features: features);
  }

  @override
  Future<void> saveDistributor(String distributor) async {
    await UnifiedPush.saveDistributor(distributor);
  }
}