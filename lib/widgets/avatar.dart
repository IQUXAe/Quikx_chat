import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:quikxchat/utils/string_color.dart';
import 'package:quikxchat/widgets/mxc_image.dart';
import 'package:quikxchat/widgets/presence_builder.dart';

class Avatar extends StatefulWidget {
  final Uri? mxContent;
  final String? name;
  final double size;
  final void Function()? onTap;
  static const double defaultSize = 44;
  final Client? client;
  final String? presenceUserId;
  final Color? presenceBackgroundColor;
  final BorderRadius? borderRadius;
  final IconData? icon;
  final BorderSide? border;

  const Avatar({
    this.mxContent,
    this.name,
    this.size = defaultSize,
    this.onTap,
    this.client,
    this.presenceUserId,
    this.presenceBackgroundColor,
    this.borderRadius,
    this.border,
    this.icon,
    super.key,
  });

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  @override
  void initState() {
    super.initState();
    // Асинхронное обновление при синхронизации
    widget.client?.onSync.stream.listen((_) async {
      if (mounted) {
        // Принудительно обновляем профили
        try {
          await widget.client?.fetchOwnProfile();
        } catch (_) {}
        if (mounted) setState(() {});
      }
    });
    
    // Немедленное обновление при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          await widget.client?.fetchOwnProfile();
          if (mounted) setState(() {});
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = widget.name;
    final fallbackLetters =
        name == null || name.isEmpty ? '@' : name.substring(0, 1);

    final noPic = widget.mxContent == null ||
        widget.mxContent.toString().isEmpty ||
        widget.mxContent.toString() == 'null';
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(widget.size / 2);
    final presenceUserId = widget.presenceUserId;
    
    Widget avatarContent;
    if (noPic) {
      avatarContent = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: name?.lightColorAvatar,
          borderRadius: borderRadius,
          border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          fallbackLetters,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (widget.size / 2.5).roundToDouble(),
          ),
        ),
      );
    } else {
      avatarContent = SizedBox(
        width: widget.size,
        height: widget.size,
        child: Material(
          color: theme.brightness == Brightness.light
              ? Colors.white
              : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: widget.border ?? BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: MxcImage(
            client: widget.client,
            borderRadius: borderRadius,
            key: ValueKey(widget.mxContent.toString()),
            cacheKey: '${widget.mxContent}_${widget.size}',
            uri: widget.mxContent,
            fit: BoxFit.cover,
            width: widget.size,
            height: widget.size,
            placeholder: (_) => Center(
              child: Icon(
                Icons.person_2,
                color: theme.colorScheme.tertiary,
                size: widget.size / 1.5,
              ),
            ),
          ),
        ),
      );
    }
    
    final container = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarContent,
          if (presenceUserId != null)
            PresenceBuilder(
              client: widget.client,
              userId: presenceUserId,
              builder: (context, presence) {
                if (presence == null ||
                    (presence.presence == PresenceType.offline &&
                        presence.lastActiveTimestamp == null)) {
                  return const SizedBox.shrink();
                }
                final dotColor = presence.presence.isOnline
                    ? Colors.green
                    : presence.presence.isUnavailable
                        ? Colors.orange
                        : Colors.grey;
                
                final hasStatusMsg = presence.statusMsg?.isNotEmpty == true;
                
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Status message border (синий круг)
                    if (hasStatusMsg)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            border: Border.all(
                              color: Colors.blue,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    // Presence dot
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: widget.presenceBackgroundColor ?? theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
    if (widget.onTap == null && presenceUserId == null) return container;
    
    return GestureDetector(
      onTap: widget.onTap ?? (presenceUserId != null ? () => _showStatusMessage(context, presenceUserId) : null),
      child: container,
    );
  }
  
  void _showStatusMessage(BuildContext context, String userId) async {
    final client = widget.client;
    if (client == null) return;
    
    try {
      final presence = await client.fetchCurrentPresence(userId);
      final statusMsg = presence.statusMsg;
      
      if (statusMsg?.isNotEmpty == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusMsg!),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
