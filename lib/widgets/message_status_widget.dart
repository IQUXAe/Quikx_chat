import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  error,
}

class MessageStatusWidget extends StatefulWidget {
  final Event event;
  final Color textColor;
  final double size;
  final bool showAnimation;

  const MessageStatusWidget({
    super.key,
    required this.event,
    required this.textColor,
    this.size = 16,
    this.showAnimation = true,
  });

  @override
  State<MessageStatusWidget> createState() => _MessageStatusWidgetState();
}

class _MessageStatusWidgetState extends State<MessageStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  MessageStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  MessageStatus _getMessageStatus() {
    if (widget.event.status.isError) {
      return MessageStatus.error;
    }
    if (widget.event.status.isSending) {
      return MessageStatus.sending;
    }
    
    final receipts = widget.event.receipts;
    if (receipts.isNotEmpty) {
      // Упрощенная проверка - если есть receipts, считаем прочитанным
      return MessageStatus.read;
    }
    
    // Если статус sent или synced, показываем как отправлено
    if (widget.event.status.isSent || widget.event.status.isSynced) {
      return MessageStatus.sent;
    }
    
    return MessageStatus.sent;
  }

  void _triggerAnimation(MessageStatus newStatus) {
    if (_previousStatus != newStatus && widget.showAnimation) {
      _animationController.reset();
      _animationController.forward();
    }
    _previousStatus = newStatus;
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return _buildSendingIcon();
      case MessageStatus.sent:
        return _buildSentIcon();
      case MessageStatus.delivered:
        return _buildDeliveredIcon();
      case MessageStatus.read:
        return _buildReadIcon();
      case MessageStatus.error:
        return _buildErrorIcon();
    }
  }

  Widget _buildSendingIcon() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.textColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildSentIcon() {
    return Icon(
      Icons.check,
      size: widget.size,
      color: widget.textColor.withValues(alpha: 0.7),
    );
  }

  Widget _buildDeliveredIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.check,
          size: widget.size,
          color: widget.textColor.withValues(alpha: 0.4),
        ),
        Transform.translate(
          offset: Offset(widget.size * 0.25, 0),
          child: Icon(
            Icons.check,
            size: widget.size,
            color: widget.textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildReadIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.check,
          size: widget.size,
          color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
        ),
        Transform.translate(
          offset: Offset(widget.size * 0.25, 0),
          child: Icon(
            Icons.check,
            size: widget.size,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorIcon() {
    return Icon(
      Icons.error_outline,
      size: widget.size,
      color: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _getMessageStatus();
    _triggerAnimation(status);

    Widget statusIcon = _buildStatusIcon(status);

    if (widget.showAnimation && _animationController.isAnimating) {
      statusIcon = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: status == MessageStatus.read 
                ? _rotationAnimation.value * 0.1 
                : 0,
              child: statusIcon,
            ),
          );
        },
      );
    }

    return Tooltip(
      message: _getStatusTooltip(status),
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: statusIcon,
      ),
    );
  }

  String _getStatusTooltip(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'Отправляется...';
      case MessageStatus.sent:
        return 'Отправлено';
      case MessageStatus.delivered:
        return 'Доставлено';
      case MessageStatus.read:
        return 'Прочитано';
      case MessageStatus.error:
        return 'Ошибка отправки';
    }
  }
}

/// Оптимизированная версия без анимаций для списков
class SimpleMessageStatusWidget extends StatelessWidget {
  final Event event;
  final Color textColor;
  final double size;

  const SimpleMessageStatusWidget({
    super.key,
    required this.event,
    required this.textColor,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (event.status.isError) {
      return Icon(
        Icons.error_outline,
        size: size,
        color: Colors.red,
      );
    }

    if (event.status.isSending) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    final hasReceipts = event.receipts.isNotEmpty;

    if (hasReceipts) {
      // Двойная зеленая галочка для прочитанных
      return SizedBox(
        width: size * 1.5,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.check,
              size: size,
              color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
            ),
            Transform.translate(
              offset: Offset(size * 0.25, 0),
              child: Icon(
                Icons.check,
                size: size,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      );
    } else {
      // Одинарная галочка для отправленных
      return Icon(
        Icons.check,
        size: size,
        color: textColor.withValues(alpha: 0.7),
      );
    }
  }
}
