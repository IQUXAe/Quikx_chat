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
import 'package:quikxchat/utils/file_logger.dart';
import 'package:quikxchat/utils/memory_manager.dart';
import 'package:quikxchat/utils/notification_service.dart';
import 'package:quikxchat/utils/optimized_message_translator.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'config/setting_keys.dart';
import 'utils/background_push.dart';
import 'widgets/quikx_chat_app.dart';



void main() async {
  Logs().i('Welcome to ${AppConfig.applicationName} <3');
  await _initializeApp();

  final store = await SharedPreferences.getInstance();
  final clients = await ClientManager.getClients(store: store);

  if (_isBackgroundFetch()) {
    _runInBackgroundFetchMode(clients, store);
  } else {
    await _runInForegroundMode(clients, store);
  }
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FileLogger.init();
  OptimizedHttpClient().initialize();
  if (!PlatformInfos.isWeb) {
    await WebRTC.initialize();
  }
  await vod.init(wasmPath: './assets/assets/vodozemac/');
  Logs().nativeColors = !PlatformInfos.isIOS;
}

bool _isBackgroundFetch() {
  return PlatformInfos.isAndroid &&
      AppLifecycleState.detached == WidgetsBinding.instance.lifecycleState;
}

void _runInBackgroundFetchMode(List<Client> clients, SharedPreferences store) {
  for (final client in clients) {
    client.backgroundSync = false;
    client.syncPresence = PresenceType.offline;
  }
  BackgroundPush.clientOnly(clients.first);
  WidgetsBinding.instance.addObserver(AppStarter(clients, store));
  Logs().i(
    '${AppConfig.applicationName} started in background-fetch mode. No GUI will be created unless the app is no longer detached.',
  );
}

Future<void> _runInForegroundMode(List<Client> clients, SharedPreferences store) async {
  Logs().i(
    '${AppConfig.applicationName} started in foreground mode. Rendering GUI...',
  );
  await _startGui(clients, store);
}

Future<void> _startGui(List<Client> clients, SharedPreferences store) async {
  final pin = await _getAppLockPin();
  await _preloadFirstClient(clients);

  MemoryManager().initialize();
  OptimizedMessageTranslator.initialize();

  try {
    await NotificationService.instance.initialize();
    NotificationService.instance.processPendingActions(clients.firstOrNull);
  } catch (e, s) {
    Logs().w('Failed to initialize push notification manager', e, s);
  }

  runApp(QuikxChatApp(clients: clients, pincode: pin, store: store));
}

Future<String?> _getAppLockPin() async {
  if (PlatformInfos.isAndroid) {
    try {
      return await const FlutterSecureStorage().read(key: SettingKeys.appLockKey);
    } catch (e, s) {
      Logs().d('Unable to read PIN from Secure storage', e, s);
    }
  }
  return null;
}

Future<void> _preloadFirstClient(List<Client> clients) async {
  final firstClient = clients.firstOrNull;
  if (firstClient != null) {
    final futures = <Future>[];
    if (firstClient.roomsLoading != null) {
      futures.add(firstClient.roomsLoading!);
    }
    if (firstClient.accountDataLoading != null) {
      futures.add(firstClient.accountDataLoading!);
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
}

/// Watches the lifecycle changes to start the application when it
/// is no longer detached.
class AppStarter with WidgetsBindingObserver {
  final List<Client> clients;
  final SharedPreferences store;
  bool _guiStarted = false;

  AppStarter(this.clients, this.store);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_guiStarted || state == AppLifecycleState.detached) return;

    Logs().i(
      '${AppConfig.applicationName} switches from detached to ${state.name} mode. Rendering GUI...',
    );

    for (final client in clients) {
      client.backgroundSync = true;
      client.syncPresence = PresenceType.online;
    }

    _startGui(clients, store);
    _guiStarted = true;
  }
}
