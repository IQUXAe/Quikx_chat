import 'package:matrix/matrix.dart';
import 'background_push.dart';

class PushDebug {
  static Future<void> recreatePusher(BackgroundPush backgroundPush) async {
    try {
      Logs().i('[PushDebug] Recreating pusher...');
      await backgroundPush.recreatePushSetup();
      Logs().i('[PushDebug] Pusher recreated successfully');
    } catch (e, s) {
      Logs().e('[PushDebug] Failed to recreate pusher', e, s);
    }
  }
}