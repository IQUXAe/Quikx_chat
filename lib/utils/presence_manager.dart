import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class PresenceManager {
  static final PresenceManager _instance = PresenceManager._();
  factory PresenceManager() => _instance;
  PresenceManager._();

  Future<void> updatePresence(
    Client client,
    SharedPreferences store,
    AppLifecycleState state,
  ) async {
    if (!client.isLogged() || !AppConfig.showPresences) return;

    final statusMsg = store.getString('user_status_msg');
    final msg = statusMsg?.isEmpty == true ? null : statusMsg;

    try {
      switch (state) {
        case AppLifecycleState.resumed:
          await client.setPresence(client.userID!, PresenceType.online, statusMsg: msg);
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          await client.setPresence(client.userID!, PresenceType.unavailable, statusMsg: msg);
        case AppLifecycleState.detached:
          await client.setPresence(client.userID!, PresenceType.offline, statusMsg: msg);
        case AppLifecycleState.hidden:
          break;
      }
    } catch (e) {
      Logs().w('Failed to update presence', e);
    }
  }

  Future<void> restorePresence(Client client, SharedPreferences store) async {
    if (!client.isLogged() || !AppConfig.showPresences) return;

    try {
      final statusMsg = store.getString('user_status_msg');
      final presenceType = PresenceType.values.firstWhere(
        (p) => p.name == store.getString('user_presence_type'),
        orElse: () => PresenceType.online,
      );
      await client.setPresence(
        client.userID!,
        presenceType,
        statusMsg: statusMsg?.isEmpty == true ? null : statusMsg,
      );
    } catch (e) {
      Logs().w('Failed to restore presence', e);
    }
  }
}
