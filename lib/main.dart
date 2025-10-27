import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/utils/client_manager.dart';
import 'package:quikxchat/utils/optimized_http_client.dart';
import 'package:quikxchat/utils/platform_infos.dart';
import 'package:quikxchat/utils/notification_service.dart';
import 'package:quikxchat/utils/file_logger.dart';
import 'package:quikxchat/utils/memory_manager.dart';
import 'package:quikxchat/utils/optimized_message_translator.dart';
import 'package:quikxchat/utils/notification_handler.dart';
import 'package:quikxchat/utils/image_cache_manager.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'config/setting_keys.dart';
import 'utils/background_push.dart';
import 'widgets/quikx_chat_app.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  Logs().i('Welcome to ${AppConfig.applicationName} <3');

  // Our background push shared isolate accesses flutter-internal things very early in the startup proccess
  // To make sure that the parts of flutter needed are started up already, we need to ensure that the
  // widget bindings are initialized already.
  WidgetsFlutterBinding.ensureInitialized();

  // Параллельная инициализация для ускорения запуска
  Logs().nativeColors = true;
  
  final initFutures = <Future>[
    if (!PlatformInfos.isWeb) FileLogger.init(),
    SharedPreferences.getInstance(),
    if (!PlatformInfos.isWeb) vod.init(wasmPath: 'assets/assets/vodozemac/'),
  ];
  
  // WebRTC инициализируем асинхронно, не блокируя старт
  if (!PlatformInfos.isWeb) {
    WebRTC.initialize().catchError((e) => Logs().w('WebRTC init failed', e));
  }
  
  // Инициализируем сервисы синхронно (быстро)
  MemoryManager().initialize();
  OptimizedHttpClient().initialize();
  ImageCacheManager().configure();
  
  final results = await Future.wait(initFutures);
  final store = results[PlatformInfos.isWeb ? 0 : 1] as SharedPreferences;
  final clients = await ClientManager.getClients(store: store);

  // If the app starts in detached mode, we assume that it is in
  // background fetch mode for processing push notifications. This is
  // currently only supported on Android.
  if (PlatformInfos.isAndroid &&
      AppLifecycleState.detached == WidgetsBinding.instance.lifecycleState) {
    // Do not send online presences when app is in background fetch mode.
    for (final client in clients) {
      client.backgroundSync = false;
      client.syncPresence = PresenceType.offline;
    }

    // In the background fetch mode we do not want to waste ressources with
    // starting the Flutter engine but process incoming push notifications.
    BackgroundPush.clientOnly(clients.first);
    // To start the flutter engine afterwards we add an custom observer.
    WidgetsBinding.instance.addObserver(AppStarter(clients, store));
    Logs().i(
      '${AppConfig.applicationName} started in background-fetch mode. No GUI will be created unless the app is no longer detached.',
    );
    return;
  }

  // Started in foreground mode.
  Logs().i(
    '${AppConfig.applicationName} started in foreground mode. Rendering GUI...',
  );
  await startGui(clients, store);
}

/// Fetch the pincode for the applock and start the flutter engine.
Future<void> startGui(List<Client> clients, SharedPreferences store) async {
  // Fetch the pin for the applock if existing for Android applications.
  String? pin;
  if (PlatformInfos.isAndroid) {
    try {
      pin =
          await const FlutterSecureStorage().read(key: SettingKeys.appLockKey);
    } catch (e, s) {
      Logs().d('Unable to read PIN from Secure storage', e, s);
    }
  }

  // Инициализируем переводчик синхронно
  OptimizedMessageTranslator.initialize();
  
  // Запускаем GUI сразу, остальное грузим асинхронно
  runApp(QuikxChatApp(clients: clients, pincode: pin, store: store));
  
  // Фоновая инициализация после старта GUI
  _initializeInBackground(clients);

}

Future<void> _initializeInBackground(List<Client> clients) async {
  // Предзагрузка данных клиента
  final firstClient = clients.firstOrNull;
  if (firstClient != null) {
    final futures = <Future>[];
    if (firstClient.roomsLoading != null) futures.add(firstClient.roomsLoading!);
    if (firstClient.accountDataLoading != null) futures.add(firstClient.accountDataLoading!);
    if (futures.isNotEmpty) {
      Future.wait(futures).catchError((e) {
        Logs().w('Client preload failed', e);
        return <dynamic>[];
      });
    }
  }
  
  // Инициализация уведомлений в фоне
  try {
    await NotificationService.instance.initialize();
    
    await NotificationService.instance.localNotifications.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('notifications_icon'),
        linux: PlatformInfos.isLinux ? const LinuxInitializationSettings(
          defaultActionName: 'Open notification',
        ) : null,
      ),
      onDidReceiveNotificationResponse: NotificationHandler.onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: NotificationHandler.onNotificationResponse,
    );
    
    NotificationHandler.processPendingNotificationActions(clients.firstOrNull);
  } catch (e, s) {
    Logs().w('Background init failed', e, s);
  }
}

/// Watches the lifecycle changes to start the application when it
/// is no longer detached.
class AppStarter with WidgetsBindingObserver {
  final List<Client> clients;
  final SharedPreferences store;
  bool guiStarted = false;

  AppStarter(this.clients, this.store);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (guiStarted) return;
    if (state == AppLifecycleState.detached) return;

    Logs().i(
      '${AppConfig.applicationName} switches from the detached background-fetch mode to ${state.name} mode. Rendering GUI...',
    );
    // Switching to foreground mode needs to reenable send online sync presence.
    for (final client in clients) {
      client.backgroundSync = true;
      client.syncPresence = PresenceType.online;
    }
    startGui(clients, store);
    // We must make sure that the GUI is only started once.
    guiStarted = true;
  }
}
