import 'dart:async';
import 'package:matrix/matrix.dart';

/// Throttler для presence запросов чтобы избежать rate limiting
class PresenceThrottler {
  static final PresenceThrottler _instance = PresenceThrottler._internal();
  factory PresenceThrottler() => _instance;
  PresenceThrottler._internal();

  Timer? _presenceTimer;
  PresenceType? _pendingPresence;
  String? _pendingStatusMsg;
  Client? _client;

  static const Duration throttleDuration = Duration(seconds: 30);

  void setPresence(
    Client client,
    PresenceType presence, {
    String? statusMsg,
  }) {
    _client = client;
    _pendingPresence = presence;
    _pendingStatusMsg = statusMsg;

    // Отменяем предыдущий таймер если есть
    _presenceTimer?.cancel();

    // Устанавливаем новый таймер
    _presenceTimer = Timer(throttleDuration, _executePresenceUpdate);
  }

  void _executePresenceUpdate() async {
    if (_client == null || _pendingPresence == null) return;

    try {
      await _client!.setPresence(
        _client!.userID!,
        _pendingPresence!,
        statusMsg: _pendingStatusMsg,
      );
      Logs().d('[PresenceThrottler] Presence updated to $_pendingPresence');
    } catch (e) {
      if (e.toString().contains('M_LIMIT_EXCEEDED')) {
        Logs().w('[PresenceThrottler] Rate limited, will retry later');
        // Увеличиваем интервал при rate limiting
        _presenceTimer = Timer(
          const Duration(minutes: 2),
          _executePresenceUpdate,
        );
        return;
      }
      Logs().w('[PresenceThrottler] Failed to set presence: $e');
    }

    // Очищаем состояние
    _pendingPresence = null;
    _pendingStatusMsg = null;
    _presenceTimer = null;
  }

  void dispose() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _pendingPresence = null;
    _pendingStatusMsg = null;
    _client = null;
  }
}
