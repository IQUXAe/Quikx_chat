import 'package:matrix/matrix.dart';

class DebugPush {
  static Future<void> debugPushers(Client client) async {
    try {
      Logs().i('[DebugPush] === CURRENT PUSHERS DEBUG ===');
      
      final pushers = await client.getPushers();
      if (pushers == null || pushers.isEmpty) {
        Logs().i('[DebugPush] No pushers found');
        return;
      }
      
      Logs().i('[DebugPush] Found ${pushers.length} pusher(s):');
      for (var i = 0; i < pushers.length; i++) {
        final pusher = pushers[i];
        Logs().i('[DebugPush] Pusher $i:');
        Logs().i('[DebugPush]   - pushkey: ${pusher.pushkey}');
        Logs().i('[DebugPush]   - appId: ${pusher.appId}');
        Logs().i('[DebugPush]   - appDisplayName: ${pusher.appDisplayName}');
        Logs().i('[DebugPush]   - deviceDisplayName: ${pusher.deviceDisplayName}');
        Logs().i('[DebugPush]   - kind: ${pusher.kind}');
        Logs().i('[DebugPush]   - lang: ${pusher.lang}');
        Logs().i('[DebugPush]   - data.url: ${pusher.data.url}');
        Logs().i('[DebugPush]   - data.format: ${pusher.data.format}');
              Logs().i('[DebugPush]   ---');
      }
      
      Logs().i('[DebugPush] === END PUSHERS DEBUG ===');
    } catch (e, s) {
      Logs().e('[DebugPush] Error getting pushers', e, s);
    }
  }
  
  static Future<void> testPushNotification(Client client) async {
    try {
      Logs().i('[DebugPush] === TESTING PUSH NOTIFICATION ===');
      
      // Отправляем тестовое сообщение самому себе
      final userId = client.userID;
      if (userId == null) {
        Logs().e('[DebugPush] User ID is null');
        return;
      }
      
      // Создаем DM с самим собой для теста
      final roomId = await client.startDirectChat(userId);
      final room = client.getRoomById(roomId);
      
      if (room == null) {
        Logs().e('[DebugPush] Failed to create test room');
        return;
      }
      
      Logs().i('[DebugPush] Created test room: $roomId');
      
      // Отправляем тестовое сообщение
      await room.sendTextEvent('Test push notification - ${DateTime.now()}');
      Logs().i('[DebugPush] Test message sent');
      
      Logs().i('[DebugPush] === END PUSH TEST ===');
    } catch (e, s) {
      Logs().e('[DebugPush] Error testing push notification', e, s);
    }
  }
}