import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quikxchat/config/routes.dart';
import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/optimized_http_client.dart';
import 'package:quikxchat/utils/memory_manager.dart';
import 'package:quikxchat/widgets/app_lock.dart';
import 'package:quikxchat/widgets/theme_builder.dart';
import '../config/app_config.dart';
import '../utils/custom_scroll_behaviour.dart';
import 'matrix.dart';

class QuikxChatApp extends StatefulWidget {
  final Widget? testWidget;
  final List<Client> clients;
  final String? pincode;
  final SharedPreferences store;

  const QuikxChatApp({
    super.key,
    this.testWidget,
    required this.clients,
    required this.store,
    this.pincode,
  });

  // Статический геттер для доступа к роутеру
  static GoRouter get router => _QuikxChatAppState.appRouter;

  @override
  State<QuikxChatApp> createState() => _QuikxChatAppState();
}

class _QuikxChatAppState extends State<QuikxChatApp> with WidgetsBindingObserver {

  /// getInitialLink may rereturn the value multiple times if this view is
  /// opened multiple times for example if the user logs out after they logged
  /// in with qr code or magic link.

  // Router must be outside of build method so that hot reload does not reset
  // the current path.
  static final GoRouter router = GoRouter(
    routes: AppRoutes.routes,
    debugLogDiagnostics: true,
  );

  // Статический геттер для доступа к роутеру из других классов
  static GoRouter get appRouter => router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OptimizedHttpClient().dispose();
    MemoryManager().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      OptimizedHttpClient().dispose();
    }
    
    // Обновляем статус присутствия при изменении состояния приложения
    if (AppConfig.showPresences) {
      for (final client in widget.clients) {
        if (client.isLogged()) {
          try {
            switch (state) {
              case AppLifecycleState.resumed:
                client.setPresence(client.userID!, PresenceType.online);
                break;
              case AppLifecycleState.paused:
              case AppLifecycleState.inactive:
                client.setPresence(client.userID!, PresenceType.unavailable);
                break;
              case AppLifecycleState.detached:
                client.setPresence(client.userID!, PresenceType.offline);
                break;
              case AppLifecycleState.hidden:
                break;
            }
          } catch (e) {
            Logs().w('Failed to update presence for ${client.userID}', e);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, primaryColor, useAmoled) => MaterialApp.router(
        title: AppConfig.applicationName,
        themeMode: themeMode,
        theme: QuikxChatThemes.buildTheme(context, Brightness.light, primaryColor),
        darkTheme:
            QuikxChatThemes.buildTheme(context, Brightness.dark, primaryColor, useAmoled),
        scrollBehavior: CustomScrollBehavior(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        routerConfig: router,
        builder: (context, child) => AppLockWidget(
          pincode: widget.pincode,
          clients: widget.clients,
          // Need a navigator above the Matrix widget for
          // displaying dialogs
          child: Matrix(
            clients: widget.clients,
            store: widget.store,
            child: widget.testWidget ?? child,
          ),
        ),
      ),
    );
  }
}