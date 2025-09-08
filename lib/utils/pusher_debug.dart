import 'package:matrix/matrix.dart';

class PusherDebug {
  static Future<void> debugPushers(Client client) async {
    try {
      final pushers = await client.getPushers();
      Logs().i('[PusherDebug] === CURRENT PUSHERS ===');
      
      if (pushers == null || pushers.isEmpty) {
        Logs().i('[PusherDebug] No pushers found!');
        return;
      }
      
      for (final pusher in pushers) {
        Logs().i('[PusherDebug] Pusher:');
        Logs().i('[PusherDebug]   - pushkey: ${pusher.pushkey}');
        Logs().i('[PusherDebug]   - appId: ${pusher.appId}');
        Logs().i('[PusherDebug]   - gateway: ${pusher.data.url}');
        Logs().i('[PusherDebug]   - format: ${pusher.data.format}');
        Logs().i('[PusherDebug]   - kind: ${pusher.kind}');
      }
    } catch (e) {
      Logs().e('[PusherDebug] Error: $e');
    }
  }
}