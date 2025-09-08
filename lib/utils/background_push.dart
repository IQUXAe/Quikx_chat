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
import 'package:flutter_new_badger/flutter_new_badger.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:unifiedpush_ui/unifiedpush_ui.dart';

import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/utils/push_helper.dart';
import 'package:simplemessenger/utils/push_notification_manager.dart';
import 'package:simplemessenger/utils/file_logger.dart';
import 'package:simplemessenger/utils/network_error_handler.dart';
import 'package:simplemessenger/widgets/simple_messenger_app.dart';
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

  void _init() async {
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
    await PushNotificationManager.instance.localNotifications.cancel(roomId.hashCode);

    // Workaround for app icon badge not updating
    if (Platform.isIOS) {
      final unreadCount = client.rooms
          .where((room) => room.isUnreadOrInvited && room.id != roomId)
          .length;
      if (unreadCount == 0) {
        FlutterNewBadger.removeBadge();
      } else {
        FlutterNewBadger.setBadge(unreadCount);
      }
      return;
    }
  }

  Future<void> setupPusher({
    String? gatewayUrl,
    String? token,
    Set<String?>? oldTokens,
    bool useDeviceSpecificAppId = false,
  }) async {
    if (kDebugMode) {
      Logs().i('[Push] === STARTING PUSHER SETUP ===');
      Logs().i('[Push] Gateway: ${gatewayUrl != null ? '${gatewayUrl.substring(0, 50)}...' : 'null'}');
      Logs().i('[Push] Token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
      Logs().i('[Push] UseDeviceSpecificAppId: $useDeviceSpecificAppId');
    }
    
    if (!client.isLogged()) {
      Logs().w('[Push] Client not logged in, skipping pusher setup');
      return;
    }
    
    // Проверяем состояние сети перед настройкой
    if (!await NetworkErrorHandler.isNetworkAvailable()) {
      Logs().w('[Push] Network not available, waiting for connection');
      try {
        await NetworkErrorHandler.waitForNetwork(timeout: const Duration(minutes: 1));
      } catch (e) {
        Logs().e('[Push] Network timeout during pusher setup: $e');
        throw Exception('Network not available for pusher setup');
      }
    }
    
    final clientName = PlatformInfos.clientName;
    oldTokens ??= <String>{};
    
    // Получаем список текущих pusher'ов
    List<Pusher> pushers;
    try {
      pushers = await client.getPushers() ?? [];
      Logs().i('[Push] Current pushers count: ${pushers.length}');
    } catch (e, s) {
      Logs().w('[Push] Unable to request pushers', e, s);
      pushers = [];
    }
    
    // Настраиваем app ID с валидацией
    const appId = AppConfig.pushNotificationsAppId;
    if (appId.isEmpty) {
      throw Exception('Push notifications app ID is not configured');
    }
    
    var deviceAppId = '$appId.${client.deviceID}';
    
    // Ограничиваем длину согласно спецификации Matrix (64 символа)
    if (deviceAppId.length > 64) {
      // Сохраняем префикс и сокращаем device ID
      const maxDeviceIdLength = 64 - appId.length - 1; // -1 для точки
      if (maxDeviceIdLength > 0) {
        final truncatedDeviceId = client.deviceID!.substring(0, maxDeviceIdLength);
        deviceAppId = '$appId.$truncatedDeviceId';
      } else {
        deviceAppId = appId; // Падбэк к базовому ID
      }
    }
    
    final thisAppId = useDeviceSpecificAppId ? deviceAppId : appId;
    
    if (kDebugMode) {
      Logs().i('[Push] useDeviceSpecificAppId: $useDeviceSpecificAppId');
      Logs().i('[Push] Original appId: $appId');
      Logs().i('[Push] Device appId: $deviceAppId');
      Logs().i('[Push] Final appId: $thisAppId');
    }
    
    // Удаляем старые pusher'ы с retry логикой
    final pushersToRemove = <Pusher>[];
    
    for (final pusher in pushers) {
      final shouldRemove = oldTokens.contains(pusher.pushkey) ||
          (token != null && pusher.pushkey != token && pusher.appId.startsWith(AppConfig.pushNotificationsAppId)) ||
          // Удаляем все pusher'ы с нашим app ID для перенастройки
          pusher.appId.startsWith(AppConfig.pushNotificationsAppId);
      
      if (shouldRemove) {
        pushersToRemove.add(pusher);
      }
    }
    
    Logs().i('[Push] Found ${pushersToRemove.length} pushers to remove');
    
    // Удаляем pusher'ы с retry логикой
    for (final pusher in pushersToRemove) {
      try {
        Logs().i('[Push] Removing pusher: ${pusher.pushkey.length > 20 ? '${pusher.pushkey.substring(0, 20)}...' : pusher.pushkey} (${pusher.appId})');
        
        await NetworkErrorHandler.retryOnNetworkError(
          () => client.deletePusher(pusher),
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 800),
        );
        
        Logs().i('[Push] Successfully removed pusher');
      } catch (e, s) {
        Logs().w('[Push] Failed to remove pusher after retries: ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
        // Продолжаем, не блокируем настройку нового pusher'а
      }
    }
    
    // Устанавливаем новый pusher с валидацией и retry
    if (gatewayUrl != null && token != null) {
      try {
        // Проверяем валидность URL
        final gatewayUri = Uri.tryParse(gatewayUrl);
        if (gatewayUri == null || !gatewayUri.hasScheme || !gatewayUri.hasAuthority) {
          throw Exception('Invalid gateway URL: $gatewayUrl');
        }
        
        // Проверяем длину токена
        if (token.length < 10 || token.length > 512) {
          throw Exception('Invalid token length: ${token.length}');
        }
        
        final pusherFormat = AppSettings.pushNotificationsPusherFormat.getItem(matrix!.store);
        final actualFormat = pusherFormat ?? 'event_id_only'; // Падбэк к стандартному формату
        
        final newPusher = Pusher(
          pushkey: token,
          appId: thisAppId,
          appDisplayName: clientName,
          deviceDisplayName: client.deviceName ?? 'Unknown Device',
          lang: 'en',
          data: PusherData(
            url: gatewayUri,
            format: actualFormat,
          ),
          kind: 'http',
        );
        
        Logs().i('[Push] Creating new pusher with format: $actualFormat');
        
        await NetworkErrorHandler.retryOnNetworkError(
          () => client.postPusher(newPusher, append: false),
          maxRetries: 3,
          initialDelay: const Duration(seconds: 1),
        );
        
        Logs().i('[Push] ✅ PUSHER CREATED SUCCESSFULLY');
        
        // Проверяем, что pusher действительно создан
        await _verifyPusherCreation(thisAppId, token);
        
      } catch (e, s) {
        Logs().e('[Push] ❌ FAILED TO CREATE PUSHER: ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
        throw Exception('Failed to setup pusher: ${NetworkErrorHandler.getErrorDescription(e)}');
      }
    } else {
      Logs().w('[Push] Missing required push credentials (gatewayUrl: ${gatewayUrl != null ? 'present' : 'null'}, token: ${token != null ? 'present' : 'null'})');
      if (gatewayUrl == null && token == null) {
        Logs().i('[Push] No credentials provided - this is expected for pusher cleanup');
      }
    }
    
    Logs().i('[Push] === PUSHER SETUP COMPLETED ===');
      }
  
  /// Проверяет, что pusher был успешно создан
  Future<void> _verifyPusherCreation(String appId, String token) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final pushers = await NetworkErrorHandler.retryOnNetworkError(
        () => client.getPushers(),
        maxRetries: 2,
      );
      
      if (pushers != null) {
        final ourPusher = pushers.where(
          (p) => p.appId == appId && p.pushkey == token,
        ).firstOrNull;
        
        if (ourPusher != null) {
          Logs().i('[Push] ✅ Pusher verified: ${ourPusher.appId}');
          
          // Проверяем конфигурацию pusher'а
          final data = ourPusher.data;
          if (data?.url == null || data?.format == null) {
            Logs().w('[Push] Pusher has incomplete configuration');
          } else {
            Logs().i('[Push] Pusher configuration: format=${data!.format}, url=${data.url}');
          }
        } else {
          throw Exception('Pusher not found after creation');
        }
      } else {
        throw Exception('Failed to retrieve pushers for verification');
      }
    } catch (e, s) {
      Logs().w('[Push] Pusher verification failed (non-critical): ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
    }
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
      final status = await PushNotificationManager.instance.checkStatus();
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
      SimpleMessengerApp.router.go(
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
    await setupPusher(
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
      await setupPusher(
        oldTokens: {oldEndpoint},
      );
    }
  }

  Future<void> _performReliableSyncWithService() async {
    try {
      // Запускаем синхронизацию с повышенным приоритетом
      await _performReliableSync();
      
      // Дополнительная проверка состояния после синхронизации
      await Future.delayed(const Duration(seconds: 2));
      
      if (client.onSyncStatus.value != SyncStatus.finished) {
        Logs().w('[Push] Sync status not finished after completion, retrying once');
        await _performReliableSync();
      }
      
    } catch (e) {
      Logs().e('[Push] Sync service failed: $e');
      
      // Последняя попытка с минимальными настройками
      try {
        await client.oneShotSync().timeout(const Duration(seconds: 60));
      } catch (finalError) {
        Logs().e('[Push] Final sync attempt failed: $finalError');
        await _showFallbackNotification('All sync attempts failed');
      }
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
    const maxAttempts = 7;
    
    while (attempts < maxAttempts) {
      try {
        if (client.onLoginStateChanged.value == LoginState.loggedIn) {
          // Проверяем и восстанавливаем сетевое соединение
          if (!await NetworkErrorHandler.isNetworkAvailable()) {
            Logs().w('[Push] Network not available, waiting...');
            await NetworkErrorHandler.waitForNetwork(timeout: const Duration(seconds: 15));
          }
          
          // Агрессивное переподключение при ошибках
          if (client.onSyncStatus.value == SyncStatus.error || attempts > 0) {
            Logs().i('[Push] Connection issue detected, attempting lightweight reconnect (attempt ${attempts + 1})');
            try {
              // Легкое переподключение без разлогина: проверяем доступность homeserver
              await client.checkHomeserver(client.homeserver!).timeout(const Duration(seconds: 15));
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (e) {
              Logs().w('[Push] Lightweight reconnect failed: $e');
            }
          }
          
          // Синхронизация с увеличенным таймаутом
          await client.oneShotSync().timeout(const Duration(seconds: 45));
          Logs().i('[Push] Sync successful on attempt ${attempts + 1}');
          
          // Проверяем результат синхронизации
          await Future.delayed(const Duration(milliseconds: 500));
          if (client.onSyncStatus.value == SyncStatus.finished) {
            Logs().i('[Push] Sync confirmed successful');
            return;
          }
        }
      } catch (e) {
        attempts++;
        
        // Специальная обработка сетевых ошибок
        if (NetworkErrorHandler.isNetworkError(e)) {
          Logs().w('[Push] Network error: ${NetworkErrorHandler.getErrorDescription(e)}');
          
          // Агрессивное восстановление соединения
          for (int i = 0; i < 3; i++) {
            try {
              await Future.delayed(Duration(seconds: 2 + i));
              await client.checkHomeserver(client.homeserver!).timeout(const Duration(seconds: 10));
              break;
            } catch (reconnectError) {
              Logs().w('[Push] Reconnect attempt ${i + 1} failed: $reconnectError');
            }
          }
        }
        
        // Экспоненциальная задержка с джиттером
        final baseDelay = [2, 5, 10, 20, 40, 60, 120][attempts - 1];
        final jitter = (baseDelay * 0.1 * (DateTime.now().millisecond % 100) / 100).round();
        final delay = Duration(seconds: baseDelay + jitter);
        
        Logs().w('[Push] Sync failed (attempt $attempts/$maxAttempts): $e. Retrying in ${delay.inSeconds}s');
        
        if (attempts < maxAttempts) {
          await Future.delayed(delay);
        }
      }
    }
    
    Logs().e('[Push] All sync attempts failed after $maxAttempts tries');
    await _showFallbackNotification('Sync failed after $maxAttempts attempts');
  }
  


  Future<void> _onUpMessage(PushMessage pushMessage, String i) async {
    final message = pushMessage.content;
    upAction = true;
    final messageStr = utf8.decode(message);
    
    if (kDebugMode) {
      Logs().i('[Push] === RECEIVED UP MESSAGE ===');
      Logs().i('[Push] Message length: ${message.length} bytes');
    }
    FileLogger.log('[Push] Received UP message: $messageStr');
    
    try {
      // Проверяем, является ли сообщение валидным JSON
      dynamic jsonData;
      try {
        jsonData = json.decode(messageStr);
      } catch (e) {
        Logs().w('[Push] Message is not valid JSON: ${e.toString()}');
        Logs().w('[Push] Raw message (first 200 chars): ${messageStr.length > 200 ? '${messageStr.substring(0, 200)}...' : messageStr}');
        
        // Проверяем, не является ли это тестовым сообщением
        if (messageStr.toLowerCase().contains('test') || messageStr.toLowerCase().contains('ping')) {
          Logs().i('[Push] Detected test message, showing test notification');
          await _showTestNotification(messageStr);
        }
        return;
      }
      
      // Проверяем структуру JSON
      if (jsonData is! Map<String, dynamic>) {
        Logs().w('[Push] JSON is not a map: ${jsonData.runtimeType}');
        return;
      }
      
      if (kDebugMode) {
        Logs().i('[Push] Parsed JSON keys: ${jsonData.keys.toList()}');
      }
      
      // Проверяем наличие поля notification
      if (!jsonData.containsKey('notification')) {
        Logs().w('[Push] JSON does not contain notification field');
        // Проверяем альтернативные поля
        if (jsonData.containsKey('data') || jsonData.containsKey('message')) {
          if (kDebugMode) {
            Logs().i('[Push] Found alternative data structure, attempting to process');
          }
          // Можно добавить обработку альтернативных форматов
        }
        return;
      }
      
      final data = Map<String, dynamic>.from(jsonData['notification']);
      // UP may strip the devices list
      data['devices'] ??= [];
      
      if (kDebugMode) {
        Logs().i('[Push] Processing notification data with keys: ${data.keys.toList()}');
        Logs().i('[Push] Room ID: ${data['room_id']}, Event ID: ${data['event_id']}');
      }
      
      // Проверяем обязательные поля
      if (data['room_id'] == null) {
        Logs().w('[Push] Missing room_id in notification data');
        return;
      }
      
      // Обрабатываем уведомление с улучшенной retry логикой
      await NetworkErrorHandler.retryOnNetworkError(
        () => _processNotificationData(data),
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
      );
      
      // Запускаем надежную синхронизацию в фоне
      unawaited(_performReliableSyncWithService());
      
      // Дополнительная проверка через некоторое время
      Timer(const Duration(seconds: 30), () async {
        if (client.onSyncStatus.value == SyncStatus.error) {
          Logs().w('[Push] Sync still in error state after 30s, forcing retry');
          unawaited(_performReliableSync());
        }
      });
      
      Logs().i('[Push] === NOTIFICATION PROCESSED SUCCESSFULLY ===');
      
    } catch (e, s) {
      Logs().e('[Push] Error processing UP message: ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
      
      // Показываем fallback уведомление при ошибке
      await _showFallbackNotification(e);
    }
  }
  
  /// Обрабатывает данные уведомления
  Future<void> _processNotificationData(Map<String, dynamic> data) async {
    // Получаем ID активной комнаты из MatrixState
    final activeRoomId = matrix?.activeRoomId;
    
    await pushHelper(
      PushNotification.fromJson(data),
      client: client,
      l10n: l10n,
      activeRoomId: activeRoomId,
      flutterLocalNotificationsPlugin: PushNotificationManager.instance.localNotifications,
    );
  }
  
  /// Показывает тестовое уведомление
  Future<void> _showTestNotification(String message) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        999999,
        'UnifiedPush Test',
        'Test message received: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notifications',
            'Test Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      Logs().e('[Push] Failed to show test notification', e);
    }
  }
  
  /// Показывает fallback уведомление при ошибке
  Future<void> _showFallbackNotification(dynamic error) async {
    try {
      await loadLocale();
      
      await _flutterLocalNotificationsPlugin.show(
        999997,
        l10n?.newMessageInFluffyChat ?? 'New Message',
        l10n?.openAppToReadMessages ?? 'Open app to read messages',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConfig.pushNotificationsChannelId,
            'Incoming Messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      Logs().e('[Push] Failed to show fallback notification', e);
    }
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