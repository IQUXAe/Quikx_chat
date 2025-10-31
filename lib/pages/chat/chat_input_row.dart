import 'package:flutter/material.dart';


import 'package:matrix/matrix.dart';

import 'package:quikxchat/config/app_config.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/pages/chat/recording_input_row.dart';
import 'package:quikxchat/pages/chat/recording_view_model.dart';
import 'package:quikxchat/utils/other_party_can_receive.dart';
import 'package:quikxchat/utils/platform_infos.dart';
import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/matrix.dart';
import '../../config/themes.dart';
import 'chat.dart';
import 'input_bar.dart';

class ChatInputRow extends StatelessWidget {
  final ChatController controller;

  const ChatInputRow(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const height = 48.0;

    if (!controller.room.otherPartyCanReceiveMessages) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            L10n.of(context).otherPartyNotLoggedIn,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final selectedTextButtonStyle = TextButton.styleFrom(
      foregroundColor: theme.colorScheme.onTertiaryContainer,
    );

    return RecordingViewModel(
      builder: (context, recordingViewModel) {
        if (recordingViewModel.isRecording) {
          return RecordingInputRow(
            state: recordingViewModel,
            onSend: controller.onVoiceMessageSend,
            onSendText: controller.onVoiceToTextSend,
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: controller.selectMode
          ? <Widget>[
              if (controller.selectedEvents
                  .every((event) => event.status == EventStatus.error))
                SizedBox(
                  height: height,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                    onPressed: controller.deleteErrorEventsAction,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.delete),
                        Text(L10n.of(context).delete),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: height,
                  child: TextButton(
                    style: selectedTextButtonStyle,
                    onPressed: controller.forwardEventsAction,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.keyboard_arrow_left_outlined),
                        Text(L10n.of(context).forward),
                      ],
                    ),
                  ),
                ),
              controller.selectedEvents.length == 1
                  ? controller.selectedEvents.first
                          .getDisplayEvent(controller.timeline!)
                          .status
                          .isSent
                      ? SizedBox(
                          height: height,
                          child: TextButton(
                            style: selectedTextButtonStyle,
                            onPressed: controller.replyAction,
                            child: Row(
                              children: <Widget>[
                                Text(L10n.of(context).reply),
                                const Icon(Icons.keyboard_arrow_right),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          height: height,
                          child: TextButton(
                            style: selectedTextButtonStyle,
                            onPressed: controller.sendAgainAction,
                            child: Row(
                              children: <Widget>[
                                Text(L10n.of(context).tryToSendAgain),
                                const SizedBox(width: 4),
                                const Icon(Icons.send_outlined, size: 16),
                              ],
                            ),
                          ),
                        )
                  : const SizedBox.shrink(),
            ]
          : <Widget>[
              const SizedBox(width: 4),
              AnimatedContainer(
                duration: QuikxChatThemes.animationDuration,
                curve: QuikxChatThemes.animationCurve,
                width: controller.sendController.text.isNotEmpty ? 0 : height,
                height: height,
                alignment: Alignment.center,
                decoration: const BoxDecoration(),
                clipBehavior: Clip.hardEdge,
                child: PopupMenuButton<String>(
                  useRootNavigator: true,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onSelected: controller.onAddPopupMenuButtonSelected,
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    if (PlatformInfos.isMobile)
                      PopupMenuItem<String>(
                        value: 'location',
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.my_location_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(L10n.of(context).shareLocation),
                          contentPadding: const EdgeInsets.all(0),
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'image',
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.photo_library_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        title: Text(L10n.of(context).sendImage),
                        contentPadding: const EdgeInsets.all(0),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'video',
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.play_circle_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        title: Text(L10n.of(context).sendVideo),
                        contentPadding: const EdgeInsets.all(0),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'file',
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.insert_drive_file_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        title: Text(L10n.of(context).sendFile),
                        contentPadding: const EdgeInsets.all(0),
                      ),
                    ),
                  ],
                ),
              ),
              if (PlatformInfos.isMobile)
                AnimatedContainer(
                  duration: QuikxChatThemes.animationDuration,
                  curve: QuikxChatThemes.animationCurve,
                  width: controller.sendController.text.isNotEmpty ? 0 : height,
                  height: height,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(),
                  clipBehavior: Clip.hardEdge,
                  child: PopupMenuButton(
                    useRootNavigator: true,
                    icon: const Icon(Icons.photo_camera_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSelected: controller.onAddPopupMenuButtonSelected,
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'camera-video',
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.video_camera_front_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(L10n.of(context).recordAVideo),
                          contentPadding: const EdgeInsets.all(0),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'camera',
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.camera_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(L10n.of(context).takeAPhoto),
                          contentPadding: const EdgeInsets.all(0),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                height: height,
                width: height,
                alignment: Alignment.center,
                child: IconButton(
                  tooltip: L10n.of(context).emojis,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: AnimatedSwitcher(
                    duration: QuikxChatThemes.fastAnimationDuration,
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      controller.showEmojiPicker
                          ? Icons.keyboard_rounded
                          : Icons.emoji_emotions_rounded,
                      key: ValueKey(controller.showEmojiPicker),
                    ),
                  ),
                  onPressed: controller.emojiPickerAction,
                ),
              ),
              if (Matrix.of(context).isMultiAccount &&
                  Matrix.of(context).hasComplexBundles &&
                  Matrix.of(context).currentBundle!.length > 1)
                Container(
                  width: height,
                  height: height,
                  alignment: Alignment.center,
                  child: _ChatAccountPicker(controller),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (controller.inputLinkPreview != null && AppConfig.showLinkPreviews)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: controller.inputLinkPreview!,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0),
                      child: InputBar(
                        room: controller.room,
                        minLines: 1,
                        maxLines: 8,
                        autofocus: !PlatformInfos.isMobile,
                        keyboardType: TextInputType.multiline,
                        textInputAction:
                            AppConfig.sendOnEnter == true && PlatformInfos.isMobile
                                ? TextInputAction.send
                                : null,
                        onSubmitted: controller.onInputBarSubmitted,
                        onSubmitImage: controller.sendImageFromClipBoard,
                        focusNode: controller.inputFocus,
                        controller: controller.sendController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          counter: const SizedBox.shrink(),
                          hintText: L10n.of(context).writeAMessage,
                          hintMaxLines: 1,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: controller.onInputBarChanged,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: height,
                width: height,
                alignment: Alignment.center,
                child: PlatformInfos.platformCanRecord &&
                        controller.sendController.text.isEmpty
                    ? IconButton(
                        tooltip: L10n.of(context).voiceMessage,
                        onPressed: PlatformInfos.isLinux
                            ? () => recordingViewModel.startRecording(controller.room)
                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Hold to record voice message',
                                  ),
                                ),
                              ),
                        onLongPress: PlatformInfos.isMobile
                            ? () => recordingViewModel.startRecording(controller.room)
                            : null,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.mic_rounded, size: 20),
                        iconSize: 20,
                      )
                    : _SendButton(
                        onPressed: controller.send,
                        tooltip: L10n.of(context).send,
                      ),
              ),
            ],
        );
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _SendButton({required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      icon: const Icon(Icons.arrow_upward_rounded, size: 20),
      iconSize: 20,
    );
  }
}

class _ChatAccountPicker extends StatelessWidget {
  final ChatController controller;

  const _ChatAccountPicker(this.controller);

  void _popupMenuButtonSelected(String mxid, BuildContext context) {
    final client = Matrix.of(context)
        .currentBundle!
        .firstWhere((cl) => cl!.userID == mxid, orElse: () => null);
    if (client == null) {
      Logs().w('Attempted to switch to a non-existing client $mxid');
      return;
    }
    controller.setSendingClient(client);
  }

  @override
  Widget build(BuildContext context) {
    final clients = controller.currentRoomBundle;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<Profile>(
        future: controller.sendingClient.fetchOwnProfile(),
        builder: (context, snapshot) => PopupMenuButton<String>(
          useRootNavigator: true,
          onSelected: (mxid) => _popupMenuButtonSelected(mxid, context),
          itemBuilder: (BuildContext context) => clients
              .map(
                (client) => PopupMenuItem<String>(
                  value: client!.userID,
                  child: FutureBuilder<Profile>(
                    future: client.fetchOwnProfile(),
                    builder: (context, snapshot) => ListTile(
                      leading: Avatar(
                        mxContent: snapshot.data?.avatarUrl,
                        name: snapshot.data?.displayName ??
                            client.userID!.localpart,
                        size: 20,
                      ),
                      title: Text(snapshot.data?.displayName ?? client.userID!),
                      contentPadding: const EdgeInsets.all(0),
                    ),
                  ),
                ),
              )
              .toList(),
          child: Avatar(
            mxContent: snapshot.data?.avatarUrl,
            name: snapshot.data?.displayName ??
                Matrix.of(context).client.userID!.localpart,
            size: 20,
          ),
        ),
      ),
    );
  }
}
