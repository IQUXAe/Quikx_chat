import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher_string.dart';

import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/client_manager.dart';


import 'package:quikxchat/utils/init_with_restore.dart';
import 'package:quikxchat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:quikxchat/utils/platform_infos.dart';
import 'package:quikxchat/utils/uia_request_manager.dart';
import 'package:quikxchat/utils/voip/enhanced_voip_plugin.dart';
import 'package:quikxchat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:quikxchat/widgets/quikx_chat_app.dart';
import 'package:quikxchat/widgets/future_loading_dialog.dart';
import '../config/app_config.dart';
import '../config/setting_keys.dart';
import '../pages/key_verification/key_verification_dialog.dart';
import '../utils/account_bundles.dart';
import '../utils/background_push.dart';
import 'local_notifications_extension.dart';

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Matrix extends StatefulWidget {
  final Widget? child;

  final List<Client> clients;

  final Map<String, String>? queryParameters;

  final SharedPreferences store;

  const Matrix({
    this.child,
    required this.clients,
    required this.store,
    this.queryParameters,
    super.key,
  });

  @override
  MatrixState createState() => MatrixState();

  /// Returns the (nearest) Client instance of your application.
  static MatrixState of(BuildContext context) =>
      Provider.of<MatrixState>(context, listen: false);
}

class MatrixState extends State<Matrix> with WidgetsBindingObserver {
  int _activeClient = -1;
  String? activeBundle;

  SharedPreferences get store => widget.store;

  XFile? loginAvatar;
  String? loginUsername;
  bool? loginRegistrationSupported;

  BackgroundPush? backgroundPush;

  Client get client {
    if (_activeClient < 0 || _activeClient >= widget.clients.length) {
      return currentBundle!.first!;
    }
    return widget.clients[_activeClient];
  }

  EnhancedVoipPlugin? voipPlugin;

  bool get isMultiAccount => widget.clients.length > 1;

  int getClientIndexByMatrixId(String matrixId) =>
      widget.clients.indexWhere((client) => client.userID == matrixId);

  late String currentClientSecret;
  RequestTokenResponse? currentThreepidCreds;

  void setActiveClient(Client? cl) {
    final i = widget.clients.indexWhere((c) => c == cl);
    if (i != -1) {
      _activeClient = i;
      // TODO: Multi-client VoiP support
      createVoipPlugin();
    } else {
      Logs().w('Tried to set an unknown client ${cl!.userID} as active');
    }
  }

  List<Client?>? get currentBundle {
    if (!hasComplexBundles) {
      return List.from(widget.clients);
    }
    final bundles = accountBundles;
    if (bundles.containsKey(activeBundle)) {
      return bundles[activeBundle];
    }
    return bundles.values.first;
  }

  Map<String?, List<Client?>> get accountBundles {
    final resBundles = <String?, List<_AccountBundleWithClient>>{};
    for (var i = 0; i < widget.clients.length; i++) {
      final bundles = widget.clients[i].accountBundles;
      for (final bundle in bundles) {
        if (bundle.name == null) {
          continue;
        }
        resBundles[bundle.name] ??= [];
        resBundles[bundle.name]!.add(
          _AccountBundleWithClient(
            client: widget.clients[i],
            bundle: bundle,
          ),
        );
      }
    }
    for (final b in resBundles.values) {
      b.sort(
        (a, b) => a.bundle!.priority == null
            ? 1
            : b.bundle!.priority == null
                ? -1
                : a.bundle!.priority!.compareTo(b.bundle!.priority!),
      );
    }
    return resBundles
        .map((k, v) => MapEntry(k, v.map((vv) => vv.client).toList()));
  }

  bool get hasComplexBundles => accountBundles.values.any((v) => v.length > 1);

  Client? _loginClientCandidate;

  AudioPlayer? audioPlayer;
  final ValueNotifier<String?> voiceMessageEventId = ValueNotifier(null);

  Future<Client> getLoginClient() async {
    if (widget.clients.isNotEmpty && !client.isLogged()) {
      return client;
    }
    if (_loginClientCandidate == null) {
      final candidate = await ClientManager.createClient(
        '${AppConfig.applicationName}-${DateTime.now().millisecondsSinceEpoch}',
        store,
      );
      _loginClientCandidate = candidate;
      candidate.onLoginStateChanged
          .stream
          .where((l) => l == LoginState.loggedIn)
          .first
          .then((_) {
        if (!widget.clients.contains(_loginClientCandidate)) {
          widget.clients.add(_loginClientCandidate!);
        }
        ClientManager.addClientNameToStore(
          _loginClientCandidate!.clientName,
          store,
        );
        _registerSubs(_loginClientCandidate!.clientName);
        _loginClientCandidate = null;
        QuikxChatApp.router.go('/rooms');
      });
    }
    if (widget.clients.isEmpty) widget.clients.add(_loginClientCandidate!);
    return _loginClientCandidate!;
  }

  Client? getClientByName(String name) =>
      widget.clients.firstWhereOrNull((c) => c.clientName == name);

  final onRoomKeyRequestSub = <String, StreamSubscription>{};
  final onKeyVerificationRequestSub = <String, StreamSubscription>{};
  final onNotification = <String, StreamSubscription>{};
  final onLoginStateChanged = <String, StreamSubscription<LoginState>>{};
  final onUiaRequest = <String, StreamSubscription<UiaRequest>>{};
  StreamSubscription<html.Event>? onFocusSub;
  StreamSubscription<html.Event>? onBlurSub;

  String? _cachedPassword;
  Timer? _cachedPasswordClearTimer;

  String? get cachedPassword => _cachedPassword;

  set cachedPassword(String? p) {
    Logs().d('Password cached');
    _cachedPasswordClearTimer?.cancel();
    _cachedPassword = p;
    _cachedPasswordClearTimer = Timer(const Duration(minutes: 10), () {
      _cachedPassword = null;
      Logs().d('Cached Password cleared');
    });
  }

  bool webHasFocus = true;

  String? get activeRoomId {
    final route = QuikxChatApp.router.routeInformationProvider.value.uri.path;
    if (!route.startsWith('/rooms/')) return null;
    return route.split('/')[2];
  }

  final linuxNotifications =
      PlatformInfos.isLinux ? NotificationsClient() : null;
  final Map<String, int> linuxNotificationIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initMatrix();

    if (PlatformInfos.isWeb) {
      initConfig().then((_) => initSettings());
    } else {
      initSettings();
    }
  }

  Future<void> initConfig() async {
    try {
      final configJsonString =
          utf8.decode((await http.get(Uri.parse('config.json'))).bodyBytes);
      final configJson = json.decode(configJsonString);
      AppConfig.loadFromJson(configJson);
    } on FormatException catch (_) {
      Logs().v('[ConfigLoader] config.json not found');
    } catch (e) {
      Logs().v('[ConfigLoader] config.json not found', e);
    }
  }

  void _registerSubs(String name) {
    final c = getClientByName(name);
    if (c == null) {
      Logs().w(
        'Attempted to register subscriptions for non-existing client $name',
      );
      return;
    }
    onRoomKeyRequestSub[name] ??=
        c.onRoomKeyRequest.stream.listen((RoomKeyRequest request) async {
      if (widget.clients.any(
        ((cl) =>
            cl.userID == request.requestingDevice.userId &&
            cl.identityKey == request.requestingDevice.curve25519Key),
      )) {
        Logs().i(
          '[Key Request] Request is from one of our own clients, forwarding the key...',
        );
        await request.forwardKey();
      }
    });
    onKeyVerificationRequestSub[name] ??= c.onKeyVerificationRequest.stream
        .listen((KeyVerification request) async {
      var hidPopup = false;
      request.onUpdate = () {
        if (!hidPopup &&
            {KeyVerificationState.done, KeyVerificationState.error}
                .contains(request.state)) {
          QuikxChatApp.router.pop('dialog');
        }
        hidPopup = true;
      };
      request.onUpdate = null;
      hidPopup = true;
      await KeyVerificationDialog(request: request).show(
        QuikxChatApp.router.routerDelegate.navigatorKey.currentContext ??
            context,
      );
    });
    onLoginStateChanged[name] ??= c.onLoginStateChanged.stream.listen((state) {
      final loggedInWithMultipleClients = widget.clients.length > 1;
      if (state == LoginState.loggedOut) {
        _cancelSubs(c.clientName);
        widget.clients.remove(c);
        ClientManager.removeClientNameFromStore(c.clientName, store);
        InitWithRestoreExtension.deleteSessionBackup(name);
      }
      if (loggedInWithMultipleClients && state != LoginState.loggedIn) {
        ScaffoldMessenger.of(
          QuikxChatApp.router.routerDelegate.navigatorKey.currentContext ??
              context,
        ).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).oneClientLoggedOut),
          ),
        );

        if (state != LoginState.loggedIn) {
          QuikxChatApp.router.go('/rooms');
        }
      } else {
        QuikxChatApp.router
            .go(state == LoginState.loggedIn ? '/rooms' : '/home');
      }
    });
    onUiaRequest[name] ??= c.onUiaRequest.stream.listen(uiaRequestHandler);
    if (PlatformInfos.isWeb || PlatformInfos.isLinux) {
      c.onSync.stream.first.then((s) {
        html.Notification.requestPermission();
        onNotification[name] ??=
            c.onNotification.stream.listen(showLocalNotification);
      });
    }
  }

  void _cancelSubs(String name) {
    onRoomKeyRequestSub[name]?.cancel();
    onRoomKeyRequestSub.remove(name);
    onKeyVerificationRequestSub[name]?.cancel();
    onKeyVerificationRequestSub.remove(name);
    onLoginStateChanged[name]?.cancel();
    onLoginStateChanged.remove(name);
    onNotification[name]?.cancel();
    onNotification.remove(name);
  }

  void initMatrix() {
    for (final c in widget.clients) {
      _registerSubs(c.clientName);
      // Принудительно обновляем профили и участников
      if (c.isLogged()) {
        Future.microtask(() async {
          try {
            await c.fetchOwnProfile();
            // Обновляем профили во всех комнатах
            for (final room in c.rooms) {
              room.requestParticipants().catchError((_) {});
            }
          } catch (_) {}
        });
      }
    }

    if (kIsWeb) {
      onFocusSub = html.window.onFocus.listen((_) => webHasFocus = true);
      onBlurSub = html.window.onBlur.listen((_) => webHasFocus = false);
    }

    if (PlatformInfos.isMobile) {
      backgroundPush = BackgroundPush(
        this,
        onFcmError: (errorMsg, {Uri? link}) async {
          final result = await showOkCancelAlertDialog(
            context: QuikxChatApp
                    .router.routerDelegate.navigatorKey.currentContext ??
                context,
            title: L10n.of(context).pushNotificationsNotAvailable,
            message: errorMsg,
            okLabel:
                link == null ? L10n.of(context).ok : L10n.of(context).learnMore,
            cancelLabel: L10n.of(context).doNotShowAgain,
          );
          if (result == OkCancelResult.ok && link != null) {
            launchUrlString(
              link.toString(),
              mode: LaunchMode.externalApplication,
            );
          }
          if (result == OkCancelResult.cancel) {
            await store.setBool(SettingKeys.showNoGoogle, true);
          }
        },
      );
    }

    createVoipPlugin();
    _scheduleUpdateCheck();
  }

  Timer? _updateCheckTimer;
  
  void _scheduleUpdateCheck() async {
    final lastCheck = store.getString('last_update_check');
    final now = DateTime.now();
    
    // Проверяем не чаще раза в 3 дня (оптимизация)
    if (lastCheck == null || 
        now.difference(DateTime.parse(lastCheck)).inDays >= 3) {
      
      // Отложенная проверка через 5 минут после запуска
      _updateCheckTimer = Timer(const Duration(minutes: 5), () async {
        await _checkForUpdatesBackground();
        await store.setString('last_update_check', DateTime.now().toIso8601String());
      });
    }
  }

  Future<void> _checkForUpdatesBackground() async {
    try {
      const currentVersion = '0.2.1';
      final uri = Uri.parse('https://iquxae.pythonanywhere.com/api/updates')
          .replace(queryParameters: {'version': currentVersion});
      
      final response = await http.get(uri, headers: {
        'Accept-Language': 'ru-RU,ru;q=0.9,en;q=0.8',
      },);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final needsUpdate = data['needs_update'] ?? false;
        final forceUpdate = data['force_update'] ?? false;
        
        if (needsUpdate || forceUpdate) {
          _showUpdateNotification(data);
        }
      }
    } catch (e) {
      // Silently fail background update check
    }
  }

  bool _isVersionLower(String current, String minimum) {
    final currentParts = current.split('.').map(int.parse).toList();
    final minimumParts = minimum.split('.').map(int.parse).toList();
    
    for (var i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minimumPart = i < minimumParts.length ? minimumParts[i] : 0;
      
      if (currentPart < minimumPart) return true;
      if (currentPart > minimumPart) return false;
    }
    return false;
  }

  void _showUpdateNotification(Map<String, dynamic> data) {
    final context = QuikxChatApp.router.routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context).newVersionAvailable(data['latest_version'])),
          action: SnackBarAction(
            label: L10n.of(context).learnMore,
            onPressed: () {
              // Show update dialog
            },
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  void createVoipPlugin() async {
    if (store.getBool(SettingKeys.experimentalVoip) == false) {
      voipPlugin?.dispose();
      voipPlugin = null;
      return;
    }
    voipPlugin?.dispose();
    voipPlugin = EnhancedVoipPlugin(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused;
    for (final client in widget.clients) {
      client.syncPresence =
          state == AppLifecycleState.resumed ? null : PresenceType.unavailable;
      if (PlatformInfos.isMobile) {
        // Всегда оставляем background sync включенным для push-уведомлений
        client.backgroundSync = true;
        client.requestHistoryOnLimitedTimeline = !foreground;
        Logs().v('Set background sync to - true (forced for push notifications)');
      }
    }
  }

  void initSettings() {
    AppConfig.fontSizeFactor =
        double.tryParse(store.getString(SettingKeys.fontSizeFactor) ?? '') ??
            AppConfig.fontSizeFactor;

    AppConfig.renderHtml =
        store.getBool(SettingKeys.renderHtml) ?? AppConfig.renderHtml;

    AppConfig.swipeRightToLeftToReply =
        store.getBool(SettingKeys.swipeRightToLeftToReply) ??
            AppConfig.swipeRightToLeftToReply;

    AppConfig.hideRedactedEvents =
        store.getBool(SettingKeys.hideRedactedEvents) ??
            AppConfig.hideRedactedEvents;

    AppConfig.hideUnknownEvents =
        store.getBool(SettingKeys.hideUnknownEvents) ??
            AppConfig.hideUnknownEvents;

    AppConfig.separateChatTypes =
        store.getBool(SettingKeys.separateChatTypes) ??
            AppConfig.separateChatTypes;

    AppConfig.autoplayImages =
        store.getBool(SettingKeys.autoplayImages) ?? AppConfig.autoplayImages;

    AppConfig.sendTypingNotifications =
        store.getBool(SettingKeys.sendTypingNotifications) ??
            AppConfig.sendTypingNotifications;

    AppConfig.sendPublicReadReceipts =
        store.getBool(SettingKeys.sendPublicReadReceipts) ??
            AppConfig.sendPublicReadReceipts;

    AppConfig.sendOnEnter =
        store.getBool(SettingKeys.sendOnEnter) ?? AppConfig.sendOnEnter;

    AppConfig.experimentalVoip = store.getBool(SettingKeys.experimentalVoip) ??
        AppConfig.experimentalVoip;

    AppConfig.showPresences =
        store.getBool(SettingKeys.showPresences) ?? AppConfig.showPresences;

    AppConfig.displayNavigationRail =
        store.getBool(SettingKeys.displayNavigationRail) ??
            AppConfig.displayNavigationRail;

    AppConfig.showLinkPreviews =
        AppSettings.showLinkPreviews.getItem(store);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    onRoomKeyRequestSub.values.map((s) => s.cancel());
    onKeyVerificationRequestSub.values.map((s) => s.cancel());
    onLoginStateChanged.values.map((s) => s.cancel());
    onNotification.values.map((s) => s.cancel());
    client.httpClient.close();
    onFocusSub?.cancel();
    onBlurSub?.cancel();
    _updateCheckTimer?.cancel();

    linuxNotifications?.close();
    voipPlugin?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => this,
      child: widget.child,
    );
  }

  Future<void> dehydrateAction(BuildContext context) async {
    final response = await showOkCancelAlertDialog(
      context: context,
      isDestructive: true,
      title: L10n.of(context).dehydrate,
      message: L10n.of(context).dehydrateWarning,
    );
    if (response != OkCancelResult.ok) {
      return;
    }
    final result = await showFutureLoadingDialog(
      context: context,
      future: client.exportDump,
    );
    final export = result.result;
    if (export == null) return;

    final exportBytes = Uint8List.fromList(
      const Utf8Codec().encode(export),
    );

    final exportFileName =
        'fluffychat-export-${DateFormat(DateFormat.YEAR_MONTH_DAY).format(DateTime.now())}.fluffybackup';

    final file = MatrixFile(bytes: exportBytes, name: exportFileName);
    file.save(context);
  }
}

class _AccountBundleWithClient {
  final Client? client;
  final AccountBundle? bundle;

  _AccountBundleWithClient({this.client, this.bundle});
}
