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
                  icon: const Icon(Icons.add_circle_outline),
                  iconColor: theme.colorScheme.onPrimaryContainer,
                  onSelected: controller.onAddPopupMenuButtonSelected,
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    if (PlatformInfos.isMobile)
                      PopupMenuItem<String>(
                        value: 'location',
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            foregroundColor: theme.colorScheme.primaryContainer,
                            child: const Icon(Icons.gps_fixed_outlined),
                          ),
                          title: Text(L10n.of(context).shareLocation),
                          contentPadding: const EdgeInsets.all(0),
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'image',
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.onPrimaryContainer,
                          foregroundColor: theme.colorScheme.primaryContainer,
                          child: const Icon(Icons.photo_outlined),
                        ),
                        title: Text(L10n.of(context).sendImage),
                        contentPadding: const EdgeInsets.all(0),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'video',
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.onPrimaryContainer,
                          foregroundColor: theme.colorScheme.primaryContainer,
                          child: const Icon(Icons.video_camera_back_outlined),
                        ),
                        title: Text(L10n.of(context).sendVideo),
                        contentPadding: const EdgeInsets.all(0),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'file',
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.onPrimaryContainer,
                          foregroundColor: theme.colorScheme.primaryContainer,
                          child: const Icon(Icons.attachment_outlined),
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
                    icon: const Icon(Icons.camera_alt_outlined),
                    onSelected: controller.onAddPopupMenuButtonSelected,
                    iconColor: theme.colorScheme.onPrimaryContainer,
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'camera-video',
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            foregroundColor: theme.colorScheme.primaryContainer,
                            child: const Icon(Icons.videocam_outlined),
                          ),
                          title: Text(L10n.of(context).recordAVideo),
                          contentPadding: const EdgeInsets.all(0),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'camera',
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            foregroundColor: theme.colorScheme.primaryContainer,
                            child: const Icon(Icons.camera_alt_outlined),
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
                  color: theme.colorScheme.onPrimaryContainer,
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
                          ? Icons.keyboard
                          : Icons.add_reaction_outlined,
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
                          contentPadding: const EdgeInsets.only(
                            left: 6.0,
                            right: 6.0,
                            bottom: 6.0,
                            top: 3.0,
                          ),
                          counter: const SizedBox.shrink(),
                          hintText: L10n.of(context).writeAMessage,
                          hintMaxLines: 1,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
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
                          backgroundColor: theme.bubbleColor,
                          foregroundColor: theme.onBubbleColor,
                        ),
                        icon: const Icon(Icons.mic_none_outlined),
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

class _SendButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _SendButton({required this.onPressed, required this.tooltip});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: -0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: _isPressed
                        ? []
                        : [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha(100),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
      ),
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