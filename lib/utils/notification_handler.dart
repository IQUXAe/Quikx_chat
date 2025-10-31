import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';

import 'package:quikxchat/utils/notification_background_handler.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/quikx_chat_app.dart';

class NotificationHandler {
  @pragma('vm:entry-point')
  static void onNotificationResponse(NotificationResponse response) async {
    Logs().d('Notification response received', response.notificationResponseType.name);
    
    try {
      final matrix = Matrix.of(QuikxChatApp.router.routerDelegate.navigatorKey.currentContext!);
      final client = matrix.client;
      
      await notificationTap(
        response,
        router: QuikxChatApp.router,
        client: client,
      );
    } catch (e, s) {
      Logs().e('Error handling notification response', e, s);
    }
  }
}
