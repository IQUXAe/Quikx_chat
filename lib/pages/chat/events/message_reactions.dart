import 'package:flutter/material.dart';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:matrix/matrix.dart';


import 'package:quikxchat/widgets/avatar.dart';
import 'package:quikxchat/widgets/future_loading_dialog.dart';
import 'package:quikxchat/widgets/matrix.dart';
import 'package:quikxchat/widgets/mxc_image.dart';
import 'package:quikxchat/utils/message_translator.dart';
import 'message.dart';

class MessageReactions extends StatefulWidget {
  final Event event;
  final Timeline timeline;
  final bool showTranslateButton;

  const MessageReactions(
    this.event,
    this.timeline, {
    this.showTranslateButton = false,
    super.key,
  });

  @override
  State<MessageReactions> createState() => _MessageReactionsState();
}

class _MessageReactionsState extends State<MessageReactions> {
  bool _shouldShowTranslate = false;

  @override
  void initState() {
    super.initState();
    if (widget.showTranslateButton) _checkLanguage();
  }

  void _checkLanguage() async {
    final isEnabled = await MessageTranslator.isEnabled;
    if (!isEnabled) return;
    
    final detected = MessageTranslator.detectLanguage(widget.event.body);
    if (detected == 'auto') return;
    
    final targetLang = await MessageTranslator.targetLanguage;
    final systemLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final actualTarget = targetLang == 'auto' ? systemLang : targetLang;
    
    if (detected != actualTarget && mounted) {
      setState(() => _shouldShowTranslate = true);
      
      // Автоперевод если включен
      final autoTranslate = await MessageTranslator.autoTranslateEnabled;
      if (autoTranslate) {
        _autoTranslate(actualTarget);
      }
    }
  }
  
  Future<void> _autoTranslate(String targetLang) async {
    final eventId = widget.event.eventId;
    if (messageTranslations.containsKey(eventId)) return;
    
    try {
      final translation = await MessageTranslator.translateMessage(
        widget.event.body,
        targetLang,
      );
      
      if (translation != null && translation.isNotEmpty && mounted) {
        messageTranslations[eventId] = translation;
        notifyTranslationChanged();
      }
    } catch (e) {
      Logs().w('[MessageReactions] Auto-translate error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allReactionEvents =
        widget.event.aggregatedEvents(widget.timeline, RelationshipTypes.reaction);
    final reactionMap = <String, _ReactionEntry>{};
    final client = Matrix.of(context).client;

    for (final e in allReactionEvents) {
      final key = e.content
          .tryGetMap<String, dynamic>('m.relates_to')
          ?.tryGet<String>('key');
      if (key != null) {
        if (!reactionMap.containsKey(key)) {
          reactionMap[key] = _ReactionEntry(
            key: key,
            count: 0,
            reacted: false,
            reactors: [],
          );
        }
        reactionMap[key]!.count++;
        reactionMap[key]!.reactors!.add(e.senderFromMemoryOrFallback);
        reactionMap[key]!.reacted |= e.senderId == e.room.client.userID;
      }
    }

    final reactionList = reactionMap.values.toList();
    reactionList.sort((a, b) => b.count - a.count > 0 ? 1 : -1);
    final ownMessage = widget.event.senderId == widget.event.room.client.userID;
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      alignment: ownMessage ? WrapAlignment.end : WrapAlignment.start,
      children: [
        if (widget.showTranslateButton &&
            _shouldShowTranslate &&
            (widget.event.messageType == MessageTypes.Text ||
                widget.event.messageType == MessageTypes.Notice ||
                widget.event.messageType == MessageTypes.Emote))
          FutureBuilder<bool>(
            future: MessageTranslator.isEnabled,
            builder: (context, snapshot) {
              if (!(snapshot.data ?? false)) return const SizedBox.shrink();
              return _TranslateReactionButton(event: widget.event);
            },
          ),
        ...reactionList.map(
          (r) => _Reaction(
            reactionKey: r.key,
            count: r.count,
            reacted: r.reacted,
            reactors: r.reactors,
            onTap: () {
              if (r.reacted) {
                final evt = allReactionEvents.firstWhereOrNull(
                  (e) =>
                      e.senderId == e.room.client.userID &&
                      e.content.tryGetMap('m.relates_to')?['key'] == r.key,
                );
                if (evt != null) {
                  showFutureLoadingDialog(
                    context: context,
                    future: () => evt.redactEvent(),
                  );
                }
              } else {
                widget.event.room.sendReaction(widget.event.eventId, r.key);
              }
            },
            onLongPress: () async => await _AdaptableReactorsDialog(
              client: client,
              reactionEntry: r,
            ).show(context),
          ),
        ),
        if (allReactionEvents.any((e) => e.status.isSending))
          const SizedBox(
            width: 24,
            height: 24,
            child: Padding(
              padding: EdgeInsets.all(4.0),
              child: CircularProgressIndicator.adaptive(strokeWidth: 1),
            ),
          ),
      ],
    );
  }
}

class _Reaction extends StatefulWidget {
  final String reactionKey;
  final int count;
  final bool? reacted;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final List<User>? reactors;

  const _Reaction({
    required this.reactionKey,
    required this.count,
    required this.reacted,
    required this.onTap,
    required this.onLongPress,
    this.reactors,
  });

  @override
  State<_Reaction> createState() => _ReactionState();
}

class _ReactionState extends State<_Reaction> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = Matrix.of(context).client;

    Widget emojiContent;
    if (widget.reactionKey.startsWith('mxc://')) {
      emojiContent = MxcImage(
        uri: Uri.parse(widget.reactionKey),
        width: 16,
        height: 16,
        animated: false,
        isThumbnail: false,
      );
    } else {
      var renderKey = Characters(widget.reactionKey);
      if (renderKey.length > 10) {
        renderKey = renderKey.getRange(0, 9) + Characters('…');
      }
      emojiContent = Text(
        renderKey.toString(),
        style: const TextStyle(fontSize: 14),
      );
    }

    final showAvatars = widget.count <= 3 && widget.reactors != null;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return InkWell(
            onTap: () => widget.onTap != null ? widget.onTap!() : null,
            onLongPress: () => widget.onLongPress != null ? widget.onLongPress!() : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: widget.reacted == true
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHigh,
                border: widget.reacted == true
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: widget.reacted == true ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: emojiContent,
                  ),
                  if (showAvatars) ...[
                    const SizedBox(width: 4),
                    ...List.generate(
                      widget.reactors!.length > 3 ? 3 : widget.reactors!.length,
                      (i) => AnimatedScale(
                        scale: widget.reacted == true ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Transform.translate(
                          offset: Offset(i * -6.0, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 1.5,
                              ),
                            ),
                            child: Avatar(
                              mxContent: widget.reactors![i].avatarUrl,
                              name: widget.reactors![i].displayName,
                              size: 16,
                              client: client,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else if (widget.count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      widget.count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.reacted == true
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReactionEntry {
  String key;
  int count;
  bool reacted;
  List<User>? reactors;

  _ReactionEntry({
    required this.key,
    required this.count,
    required this.reacted,
    this.reactors,
  });
}

class _AdaptableReactorsDialog extends StatelessWidget {
  final Client? client;
  final _ReactionEntry? reactionEntry;

  const _AdaptableReactorsDialog({
    this.client,
    this.reactionEntry,
  });

  Future<bool?> show(BuildContext context) => showAdaptiveDialog(
        context: context,
        builder: (context) => this,
        barrierDismissible: true,
        useRootNavigator: false,
      );

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: <Widget>[
          for (final reactor in reactionEntry!.reactors!)
            Chip(
              avatar: Avatar(
                mxContent: reactor.avatarUrl,
                name: reactor.displayName,
                client: client,
                presenceUserId: reactor.stateKey,
              ),
              label: Text(reactor.displayName!),
            ),
        ],
      ),
    );

    final title = Center(child: Text(reactionEntry!.key));

    return AlertDialog.adaptive(
      title: title,
      content: body,
    );
  }
}

class _TranslateReactionButton extends StatefulWidget {
  final Event event;

  const _TranslateReactionButton({required this.event});

  @override
  State<_TranslateReactionButton> createState() => _TranslateReactionButtonState();
}

class _TranslateReactionButtonState extends State<_TranslateReactionButton> {
  bool _isLoading = false;

  bool get _isTranslated => messageTranslations.containsKey(widget.event.eventId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: _isLoading ? null : _toggleTranslation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _isTranslated
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          border: _isTranslated
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isTranslated ? Icons.translate : Icons.translate_outlined,
                size: 16,
                color: _isTranslated
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
      ),
    );
  }

  Future<void> _toggleTranslation() async {
    final eventId = widget.event.eventId;

    if (_isTranslated) {
      if (mounted) {
        setState(() {
          messageTranslations.remove(eventId);
        });
        notifyTranslationChanged();
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final targetLang = await MessageTranslator.targetLanguage;
      final systemLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final actualTarget = targetLang == 'auto' ? systemLang : targetLang;

      final translation = await MessageTranslator.translateMessage(
        widget.event.body,
        actualTarget,
      );

      if (translation != null && translation.isNotEmpty && mounted) {
        setState(() {
          messageTranslations[eventId] = translation;
        });
        notifyTranslationChanged();
      }
    } catch (e) {
      Logs().w('[TranslateReactionButton] Translation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
