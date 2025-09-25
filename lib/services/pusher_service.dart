import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/config/setting_keys.dart';
import 'package:quikxchat/utils/network_error_handler.dart';
import 'package:quikxchat/utils/platform_infos.dart';

class PusherService {
  final Client _client;

  PusherService(this._client);

  Future<void> setupPusher({
    String? gatewayUrl,
    String? token,
    Set<String?>? oldTokens,
    bool useDeviceSpecificAppId = false,
  }) async {
    if (kDebugMode) {
      Logs().i('[PusherService] === STARTING PUSHER SETUP ===');
      Logs().i('[PusherService] Gateway: ${gatewayUrl != null ? '${gatewayUrl.substring(0, 50)}...' : 'null'}');
      Logs().i('[PusherService] Token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
      Logs().i('[PusherService] UseDeviceSpecificAppId: $useDeviceSpecificAppId');
    }

    if (!_client.isLogged()) {
      Logs().w('[PusherService] Client not logged in, skipping pusher setup');
      return;
    }

    if (!await NetworkErrorHandler.isNetworkAvailable()) {
      Logs().w('[PusherService] Network not available, waiting for connection');
      try {
        await NetworkErrorHandler.waitForNetwork(timeout: const Duration(minutes: 1));
      } catch (e) {
        Logs().e('[PusherService] Network timeout during pusher setup: $e');
        throw Exception('Network not available for pusher setup');
      }
    }

    final clientName = PlatformInfos.clientName;
    oldTokens ??= <String>{};

    List<Pusher> pushers;
    try {
      pushers = await _client.getPushers() ?? [];
      Logs().i('[PusherService] Current pushers count: ${pushers.length}');
    } catch (e, s) {
      Logs().w('[PusherService] Unable to request pushers', e, s);
      pushers = [];
    }

    const appId = AppConfig.pushNotificationsAppId;
    if (appId.isEmpty) {
      throw Exception('Push notifications app ID is not configured');
    }

    var deviceAppId = '$appId.${_client.deviceID}';

    if (deviceAppId.length > 64) {
      const maxDeviceIdLength = 64 - appId.length - 1;
      if (maxDeviceIdLength > 0) {
        final truncatedDeviceId = _client.deviceID!.substring(0, maxDeviceIdLength);
        deviceAppId = '$appId.$truncatedDeviceId';
      } else {
        deviceAppId = appId;
      }
    }

    final thisAppId = useDeviceSpecificAppId ? deviceAppId : appId;

    final pushersToRemove = <Pusher>[];
    for (final pusher in pushers) {
      final shouldRemove = oldTokens.contains(pusher.pushkey) ||
          (token != null && pusher.pushkey != token && pusher.appId.startsWith(AppConfig.pushNotificationsAppId)) ||
          pusher.appId.startsWith(AppConfig.pushNotificationsAppId);
      if (shouldRemove) {
        pushersToRemove.add(pusher);
      }
    }

    Logs().i('[PusherService] Found ${pushersToRemove.length} pushers to remove');

    for (final pusher in pushersToRemove) {
      try {
        Logs().i('[PusherService] Removing pusher: ${pusher.pushkey.length > 20 ? '${pusher.pushkey.substring(0, 20)}...' : pusher.pushkey} (${pusher.appId})');
        await NetworkErrorHandler.retryOnNetworkError(
          () => _client.deletePusher(pusher),
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 800),
        );
        Logs().i('[PusherService] Successfully removed pusher');
      } catch (e, s) {
        Logs().w('[PusherService] Failed to remove pusher after retries: ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
      }
    }

    if (gatewayUrl != null && token != null) {
      try {
        final gatewayUri = Uri.tryParse(gatewayUrl);
        if (gatewayUri == null || !gatewayUri.hasScheme || !gatewayUri.hasAuthority) {
          throw Exception('Invalid gateway URL: $gatewayUrl');
        }

        if (token.length < 10 || token.length > 512) {
          throw Exception('Invalid token length: ${token.length}');
        }

        final pusherFormat = AppSettings.pushNotificationsPusherFormat.getItem(_client.store);
        final actualFormat = pusherFormat ?? 'event_id_only';

        final newPusher = Pusher(
          pushkey: token,
          appId: thisAppId,
          appDisplayName: clientName,
          deviceDisplayName: _client.deviceName ?? 'Unknown Device',
          lang: 'en',
          data: PusherData(
            url: gatewayUri,
            format: actualFormat,
          ),
          kind: 'http',
        );

        Logs().i('[PusherService] Creating new pusher with format: $actualFormat');
        await NetworkErrorHandler.retryOnNetworkError(
          () => _client.postPusher(newPusher, append: false),
          maxRetries: 3,
          initialDelay: const Duration(seconds: 1),
        );
        Logs().i('[PusherService] ✅ PUSHER CREATED SUCCESSFULLY');

        await _verifyPusherCreation(thisAppId, token);
      } catch (e, s) {
        Logs().e('[PusherService] ❌ FAILED TO CREATE PUSHER: ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
        throw Exception('Failed to setup pusher: ${NetworkErrorHandler.getErrorDescription(e)}');
      }
    } else {
      Logs().w('[PusherService] Missing required push credentials (gatewayUrl: ${gatewayUrl != null ? 'present' : 'null'}, token: ${token != null ? 'present' : 'null'})');
      if (gatewayUrl == null && token == null) {
        Logs().i('[PusherService] No credentials provided - this is expected for pusher cleanup');
      }
    }
    Logs().i('[PusherService] === PUSHER SETUP COMPLETED ===');
  }

  Future<void> _verifyPusherCreation(String appId, String token) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final pushers = await NetworkErrorHandler.retryOnNetworkError(
        () => _client.getPushers(),
        maxRetries: 2,
      );
      if (pushers != null) {
        final ourPusher = pushers.where((p) => p.appId == appId && p.pushkey == token).firstOrNull;
        if (ourPusher != null) {
          Logs().i('[PusherService] ✅ Pusher verified: ${ourPusher.appId}');
          final data = ourPusher.data;
          if (data.url == null || data.format == null) {
            Logs().w('[PusherService] Pusher has incomplete configuration');
          } else {
            Logs().i('[PusherService] Pusher configuration: format=${data.format}, url=${data.url}');
          }
        } else {
          throw Exception('Pusher not found after creation');
        }
      } else {
        throw Exception('Failed to retrieve pushers for verification');
      }
    } catch (e, s) {
      Logs().w('[PusherService] Pusher verification failed (non-critical): ${NetworkErrorHandler.getErrorDescription(e)}', e, s);
    }
  }
}