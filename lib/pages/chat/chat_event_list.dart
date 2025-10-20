import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:quikxchat/config/themes.dart';
import 'package:quikxchat/pages/chat/chat.dart';
import 'package:quikxchat/pages/chat/events/message.dart';
import 'package:quikxchat/pages/chat/seen_by_row.dart';
import 'package:quikxchat/pages/chat/typing_indicators.dart';
import 'package:quikxchat/utils/account_config.dart';
import 'package:quikxchat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';

class ChatEventList extends StatelessWidget {
  final ChatController controller;

  const ChatEventList({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final timeline = controller.timeline;

    if (timeline == null) {
      return const Center(child: CupertinoActivityIndicator());
    }
    final theme = Theme.of(context);

    final colors = [
      theme.secondaryBubbleColor,
      theme.bubbleColor,
    ];

    final horizontalPadding = QuikxChatThemes.isColumnMode(context) ? 8.0 : 0.0;

    final events = timeline.events.filterByVisibleInGui();
    final animateInEventIndex = controller.animateInEventIndex;

    // create a map of eventId --> index to greatly improve performance of
    // ListView's findChildIndexCallback
    final thisEventsKeyMap = <String, int>{};
    for (var i = 0; i < events.length; i++) {
      thisEventsKeyMap[events[i].eventId] = i;
    }

    final hasWallpaper =
        controller.room.client.applicationAccountConfig.wallpaperUrl != null;

    return SelectionArea(
      child: ListView.custom(
        padding: EdgeInsets.only(
          top: 16,
          bottom: 8,
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        reverse: true,
        controller: controller.scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        childrenDelegate: SliverChildBuilderDelegate(
          (BuildContext context, int i) {
            // Footer to display typing indicator and read receipts:
            if (i == 0) {
              if (timeline.isRequestingFuture) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                );
              }
              if (timeline.canRequestFuture) {
                return Center(
                  child: IconButton(
                    onPressed: controller.requestFuture,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SeenByRow(controller),
                  TypingIndicators(controller),
                ],
              );
            }

            // Request history button or progress indicator:
            if (i == events.length + 1) {
              if (timeline.isRequestingHistory) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                );
              }
              // Fix infinite scroll bug - check if we can actually request more history
              if (timeline.canRequestHistory && timeline.events.isNotEmpty) {
                // Check if we have reached the beginning by comparing event count
                final hasReachedStart = timeline.events.length < 50 && !timeline.canRequestHistory;
                if (!hasReachedStart) {
                  return Builder(
                    builder: (context) {
                      WidgetsBinding.instance
                          .addPostFrameCallback(controller.requestHistory);
                      return Center(
                        child: IconButton(
                          onPressed: controller.requestHistory,
                          icon: const Icon(Icons.refresh_outlined),
                        ),
                      );
                    },
                  );
                }
              }
              // Show "Beginning of conversation" indicator when no more history
              if (!timeline.canRequestHistory && events.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Начало беседы',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(128),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }
            i--;

            // The message at this index:
            final event = events[i];
            final animateIn = animateInEventIndex != null &&
                timeline.events.length > animateInEventIndex &&
                event == timeline.events[animateInEventIndex];

            final nextEvent = i + 1 < events.length ? events[i + 1] : null;
            final previousEvent = i > 0 ? events[i - 1] : null;

            // Collapsed state event
            final canExpand = event.isCollapsedState &&
                nextEvent?.isCollapsedState == true &&
                previousEvent?.isCollapsedState != true;
            final isCollapsed = event.isCollapsedState &&
                previousEvent?.isCollapsedState == true &&
                !controller.expandedEventIds.contains(event.eventId);

            return AutoScrollTag(
              key: ValueKey(event.eventId),
              index: i,
              controller: controller.scrollController,
              child: Message(
                event,
                animateIn: animateIn,
                resetAnimateIn: () {
                  controller.animateInEventIndex = null;
                },
                onSwipe: () => controller.replyAction(replyTo: event),
                onInfoTab: controller.showEventInfo,
                onMention: () => controller.sendController.text +=
                    '${event.senderFromMemoryOrFallback.mention} ',
                highlightMarker:
                    controller.scrollToEventIdMarker == event.eventId,
                onSelect: controller.onSelectMessage,
                scrollToEventId: (String eventId) =>
                    controller.scrollToEventId(eventId),
                longPressSelect: controller.selectedEvents.isNotEmpty,
                selected: controller.selectedEvents
                    .any((e) => e.eventId == event.eventId),
                singleSelected:
                    controller.selectedEvents.singleOrNull?.eventId ==
                        event.eventId,
                onEdit: () => controller.editSelectedEventAction(),
                timeline: timeline,
                displayReadMarker:
                    i > 0 && controller.readMarkerEventId == event.eventId,
                nextEvent: nextEvent,
                previousEvent: previousEvent,
                wallpaperMode: hasWallpaper,
                scrollController: controller.scrollController,
                colors: colors,
                isCollapsed: isCollapsed,
                onExpand: canExpand
                    ? () => controller.expandEventsFrom(
                          event,
                          !controller.expandedEventIds.contains(event.eventId),
                        )
                    : null,
              ),
            );
          },
          childCount: events.length + 2,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          findChildIndexCallback: (key) =>
              controller.findChildIndexCallback(key, thisEventsKeyMap),
        ),
      ),
    );
  }
}