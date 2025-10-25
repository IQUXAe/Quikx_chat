import 'package:flutter/widgets.dart';

import 'package:matrix/matrix.dart';

import 'package:quikxchat/l10n/l10n.dart';
import '../config/app_config.dart';

extension RoomStatusExtension on Room {
  String getLocalizedTypingText(BuildContext context) {
    final typingUsers = this.typingUsers.where((u) => u.id != client.userID).toList();
    if (typingUsers.isEmpty) return '';

    final l10n = L10n.of(context);
    final isDirect = typingUsers.first.id == directChatMatrixID;

    if (AppConfig.hideTypingUsernames) {
      return isDirect ? l10n.isTyping : l10n.numUsersTyping(typingUsers.length);
    }

    if (typingUsers.length == 1) {
      return isDirect ? l10n.isTyping : l10n.userIsTyping(typingUsers.first.calcDisplayname());
    }

    if (typingUsers.length == 2) {
      return l10n.userAndUserAreTyping(
        typingUsers[0].calcDisplayname(),
        typingUsers[1].calcDisplayname(),
      );
    }

    return l10n.userAndOthersAreTyping(
      typingUsers.first.calcDisplayname(),
      typingUsers.length - 1,
    );
  }

  List<User> getSeenByUsers(Timeline timeline, {String? eventId}) {
    if (timeline.events.isEmpty) return [];
    
    final targetEvent = timeline.events.firstWhere(
      (e) => e.eventId == (eventId ?? timeline.events.first.eventId),
      orElse: () => timeline.events.first,
    );
    
    return targetEvent.receipts
        .map((r) => r.user)
        .where((u) => u.id != client.userID && u.id != targetEvent.senderId)
        .toList();
  }
}
