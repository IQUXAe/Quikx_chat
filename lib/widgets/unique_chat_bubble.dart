import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import '../config/unique_themes.dart';

/// Уникальный пузырь сообщения с градиентами и анимациями
class UniqueChatBubble extends StatefulWidget {
  final Widget child;
  final bool isOwnMessage;
  final Event? event;
  final String colorPalette;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const UniqueChatBubble({
    super.key,
    required this.child,
    required this.isOwnMessage,
    this.event,
    this.colorPalette = 'cosmic',
    this.onTap,
    this.onLongPress,
  });

  @override
  State<UniqueChatBubble> createState() => _UniqueChatBubbleState();
}

class _UniqueChatBubbleState extends State<UniqueChatBubble>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: UniqueQuikxThemes.mediumAnimation,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: UniqueQuikxThemes.shortAnimation,
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: UniqueQuikxThemes.extraLongAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isOwnMessage ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: UniqueQuikxThemes.bouncyCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: UniqueQuikxThemes.fastCurve,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: UniqueQuikxThemes.slowCurve,
    ));

    // Запускаем анимацию появления
    _slideController.forward();
    
    // Запускаем shimmer эффект для собственных сообщений
    if (widget.isOwnMessage) {
      _shimmerController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onLongPress: widget.onLongPress,
          child: AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Stack(
                  children: [
                    // Основной пузырь
                    Container(
                      decoration: UniqueQuikxThemes.createMessageBubbleDecoration(
                        context: context,
                        isOwnMessage: widget.isOwnMessage,
                        colorPalette: widget.colorPalette,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: widget.child,
                    ),
                    
                    // Shimmer эффект для собственных сообщений
                    if (widget.isOwnMessage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              UniqueQuikxThemes.borderRadiusL,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment(-1.0 + _shimmerAnimation.value * 2, 0.0),
                              end: Alignment(-0.5 + _shimmerAnimation.value * 2, 0.0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Индикатор нажатия
                    if (_isPressed)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              UniqueQuikxThemes.borderRadiusL,
                            ),
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Уникальный виджет для группировки сообщений
class UniqueMessageGroup extends StatelessWidget {
  final List<Widget> messages;
  final bool isOwnMessage;
  final String senderName;
  final String? avatarUrl;
  final String colorPalette;

  const UniqueMessageGroup({
    super.key,
    required this.messages,
    required this.isOwnMessage,
    required this.senderName,
    this.avatarUrl,
    this.colorPalette = 'cosmic',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            // Анимированный аватар отправителя
            UniqueAnimatedAvatar(
              name: senderName,
              avatarUrl: avatarUrl,
              colorPalette: colorPalette,
            ),
            const SizedBox(width: 8),
          ],
          
          // Группа сообщений
          Expanded(
            child: Column(
              crossAxisAlignment: isOwnMessage 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: UniqueQuikxThemes.colorPalettes[colorPalette]![0],
                      ),
                    ),
                  ),
                ...messages,
              ],
            ),
          ),
          
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            // Индикатор статуса для собственных сообщений
            const UniqueMessageStatusIndicator(),
          ],
        ],
      ),
    );
  }
}

/// Уникальный анимированный аватар
class UniqueAnimatedAvatar extends StatefulWidget {
  final String name;
  final String? avatarUrl;
  final String colorPalette;
  final double size;

  const UniqueAnimatedAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.colorPalette = 'cosmic',
    this.size = 40,
  });

  @override
  State<UniqueAnimatedAvatar> createState() => _UniqueAnimatedAvatarState();
}

class _UniqueAnimatedAvatarState extends State<UniqueAnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotationController);

    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: UniqueQuikxThemes.createAvatarDecoration(
            context: context,
            colorPalette: widget.colorPalette,
            animationValue: _rotationAnimation.value,
          ),
          child: Center(
            child: Container(
              width: widget.size - 4,
              height: widget.size - 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ClipOval(
                child: widget.avatarUrl != null
                    ? Image.network(
                        widget.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitials();
                        },
                      )
                    : _buildInitials(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitials() {
    final initials = widget.name.isNotEmpty 
        ? widget.name.substring(0, 1).toUpperCase()
        : '?';
    
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: widget.size * 0.4,
          fontWeight: FontWeight.w700,
          color: UniqueQuikxThemes.colorPalettes[widget.colorPalette]![0],
        ),
      ),
    );
  }
}

/// Уникальный индикатор статуса сообщения
class UniqueMessageStatusIndicator extends StatefulWidget {
  final MessageStatus status;

  const UniqueMessageStatusIndicator({
    super.key,
    this.status = MessageStatus.sent,
  });

  @override
  State<UniqueMessageStatusIndicator> createState() => _UniqueMessageStatusIndicatorState();
}

class _UniqueMessageStatusIndicatorState extends State<UniqueMessageStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.status == MessageStatus.sending) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.status == MessageStatus.sending 
              ? _pulseAnimation.value 
              : 1.0,
          child: _buildStatusIcon(),
        );
      },
    );
  }

  Widget _buildStatusIcon() {
    switch (widget.status) {
      case MessageStatus.sending:
        return Container(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              UniqueQuikxThemes.colorPalettes['cosmic']![0],
            ),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        );
      case MessageStatus.delivered:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            Transform.translate(
              offset: const Offset(-4, 0),
              child: Icon(
                Icons.check,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        );
      case MessageStatus.read:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check,
              size: 14,
              color: UniqueQuikxThemes.colorPalettes['cosmic']![2].withOpacity(0.8),
            ),
            Transform.translate(
              offset: const Offset(-4, 0),
              child: Icon(
                Icons.check,
                size: 16,
                color: UniqueQuikxThemes.colorPalettes['cosmic']![2],
              ),
            ),
          ],
        );
      case MessageStatus.error:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: Theme.of(context).colorScheme.error,
        );
    }
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  error,
}
