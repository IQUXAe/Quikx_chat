import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:simplemessenger/config/themes.dart';
import 'package:simplemessenger/l10n/l10n.dart';
import 'package:simplemessenger/pages/chat/chat.dart';
import 'package:simplemessenger/utils/date_time_extension.dart';
import 'package:simplemessenger/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:simplemessenger/utils/sync_status_localization.dart';
import 'package:simplemessenger/widgets/avatar.dart';
import 'package:simplemessenger/widgets/presence_builder.dart';
import 'package:simplemessenger/widgets/matrix.dart';

class ChatAppBarTitle extends StatelessWidget {
  final ChatController controller;
  const ChatAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final room = controller.room;
    if (controller.selectedEvents.isNotEmpty) {
      return Text(
        controller.selectedEvents.length.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
      );
    }
    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: controller.isArchived
          ? null
          : () => SimpleMessengerThemes.isThreeColumnMode(context)
              ? controller.toggleDisplayChatDetailsColumn()
              : context.go('/rooms/${room.id}/details'),
      child: Row(
        children: [
          Hero(
            tag: 'content_banner',
            child: Avatar(
              mxContent: room.avatar,
              name: room.getLocalizedDisplayname(
                MatrixLocals(L10n.of(context)),
              ),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.getLocalizedDisplayname(MatrixLocals(L10n.of(context))),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                StreamBuilder(
                  stream: room.client.onSyncStatus.stream,
                  builder: (context, snapshot) {
                    final status = room.client.onSyncStatus.value ??
                        const SyncStatusUpdate(SyncStatus.waitingForResponse);
                    final hide = SimpleMessengerThemes.isColumnMode(context) ||
                        (room.client.onSync.value != null &&
                            status.status != SyncStatus.error &&
                            room.client.prevBatch != null);
                    return AnimatedSize(
                      duration: SimpleMessengerThemes.animationDuration,
                      child: hide
                          ? PresenceBuilder(
                              userId: room.directChatMatrixID,
                              builder: (context, presence) {
                                final lastActiveTimestamp =
                                    presence?.lastActiveTimestamp;
                                final style =
                                    Theme.of(context).textTheme.bodySmall;
                                if (presence?.currentlyActive == true) {
                                  return Text(
                                    L10n.of(context).currentlyActive,
                                    style: style,
                                  );
                                }
                                if (lastActiveTimestamp != null) {
                                  return Text(
                                    L10n.of(context).lastActiveAgo(
                                      lastActiveTimestamp
                                          .localizedTimeShort(context),
                                    ),
                                    style: style,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            )
                          : Row(
                              children: [
                                SizedBox.square(
                                  dimension: 10,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 1,
                                    value: status.progress,
                                    valueColor: status.error != null
                                        ? AlwaysStoppedAnimation<Color>(
                                            Theme.of(context).colorScheme.error,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    status.calcLocalizedString(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: status.error != null
                                          ? Theme.of(context).colorScheme.error
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
          // VoIP call buttons
          if (room.isDirectChat && Matrix.of(context).voipPlugin != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.videocam, size: 20),
              onPressed: () => _makeCall(context, CallType.kVideo),
              tooltip: '🚧 Видео звонок (БЕТА)',
            ),
            IconButton(
              icon: const Icon(Icons.call, size: 20),
              onPressed: () => _makeCall(context, CallType.kVoice),
              tooltip: '🚧 Голосовой звонок (БЕТА)',
            ),
          ],
        ],
      ),
    );
  }

  void _makeCall(BuildContext context, CallType type) async {
    final client = Matrix.of(context).client;
    
    // Show beta warning
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚧 Звонки (БЕТА)'),
        content: const Text(
          'Функция звонков находится в стадии бета-тестирования. '
          'Возможны ошибки и нестабильная работа. Продолжить?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    
    if (shouldProceed != true) return;
    
    try {
      // Force flush any pending events first
      if (controller.room.sendingQueue.isNotEmpty) {
        Logs().i('Waiting for ${controller.room.sendingQueue.length} pending events to be sent');
        
        // Wait up to 10 seconds for queue to clear
        var waitTime = 0;
        while (controller.room.sendingQueue.isNotEmpty && waitTime < 10000) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitTime += 100;
        }
        
        if (controller.room.sendingQueue.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось отправить все сообщения. Попробуйте позже.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
      
      // Wait for sync to complete
      var syncAttempts = 0;
      while (client.onSyncStatus.value?.status == SyncStatus.processing && syncAttempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        syncAttempts++;
      }
      
      // Additional delay to ensure everything is settled
      await Future.delayed(const Duration(milliseconds: 500));
      
      await Matrix.of(context).voipPlugin!.voip.inviteToCall(
        controller.room,
        type,
      );
    } catch (e) {
      var errorMessage = 'Звонок не удался (БЕТА)';
      
      if (e.toString().contains('Event blocked by other events')) {
        errorMessage = 'Система занята отправкой данных. Подождите 5-10 секунд и попробуйте снова.';
      } else if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        errorMessage = 'Таймаут соединения. Проверьте интернет.';
      } else if (e.toString().contains('Failed to send invite')) {
        errorMessage = 'Не удалось отправить приглашение. Попробуйте перезапустить приложение.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }
}
