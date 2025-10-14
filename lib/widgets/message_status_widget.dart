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

/// Ключ для принудительного обновления виджета при изменении статуса
class _StatusKey {
  final EventStatus status;
  final int receiptsCount;
  final List<String> readByUsers;
  
  _StatusKey(Event event) : 
    status = event.status,
    receiptsCount = event.receipts.length,
    readByUsers = event.receipts
      .where((r) => r.user.id != event.room.client.userID)
      .map((r) => r.user.id)
      .toList();
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _StatusKey &&
      other.status == status &&
      other.receiptsCount == receiptsCount &&
      other.readByUsers.length == readByUsers.length &&
      other.readByUsers.every((id) => readByUsers.contains(id));
  }
  
  @override
  int get hashCode => Object.hash(status, receiptsCount, readByUsers.length);
}

class _MessageStatusWidgetState extends State<MessageStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  MessageStatus? _previousStatus;
  _StatusKey? _previousKey;

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
    
    final room = widget.event.room;
    final myUserId = room.client.userID;
    
    // Если это не мое сообщение, не показываем статус
    if (widget.event.senderId != myUserId) {
      return MessageStatus.sent;
    }
    
    // Проверяем receipts на сообщении
    final hasReceipts = widget.event.receipts.any((r) => r.user.id != myUserId);
    if (hasReceipts) {
      return MessageStatus.read;
    }
    
    // Проверяем fullyRead маркер комнаты
    if (room.fullyRead.isNotEmpty) {
      // Если есть fullyRead маркер и наше сообщение старше, считаем прочитанным
      if (widget.event.eventId == room.fullyRead || 
          widget.event.originServerTs.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
        return MessageStatus.read;
      }
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
    final currentKey = _StatusKey(widget.event);
    
    // Принудительно обновляем состояние при изменении ключевых параметров
    if (_previousKey != currentKey) {
      _previousKey = currentKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    
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
class SimpleMessageStatusWidget extends StatefulWidget {
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
  State<SimpleMessageStatusWidget> createState() => _SimpleMessageStatusWidgetState();
}

class _SimpleMessageStatusWidgetState extends State<SimpleMessageStatusWidget> {
  _StatusKey? _previousKey;

  @override
  Widget build(BuildContext context) {
    final currentKey = _StatusKey(widget.event);
    
    // Принудительно обновляем состояние при изменении ключевых параметров
    if (_previousKey != currentKey) {
      _previousKey = currentKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    
    if (widget.event.status.isError) {
      return Icon(
        Icons.error_outline,
        size: widget.size,
        color: Colors.red,
      );
    }

    if (widget.event.status.isSending) {
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

    final room = widget.event.room;
    final myUserId = room.client.userID;
    
    // Если это не мое сообщение, не показываем статус
    if (widget.event.senderId != myUserId) {
      return Icon(
        Icons.check,
        size: widget.size,
        color: widget.textColor.withValues(alpha: 0.7),
      );
    }
    
    // Проверяем receipts на сообщении
    bool isRead = widget.event.receipts.any((r) => r.user.id != myUserId);
    
    // Проверяем fullyRead маркер
    if (!isRead && room.fullyRead.isNotEmpty) {
      if (widget.event.eventId == room.fullyRead || 
          widget.event.originServerTs.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
        isRead = true;
      }
    }

    if (isRead) {
      // Двойная зеленая галочка для прочитанных
      return SizedBox(
        width: widget.size * 1.5,
        height: widget.size,
        child: Stack(
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
        ),
      );
    } else {
      // Одинарная галочка для отправленных
      return Icon(
        Icons.check,
        size: widget.size,
        color: widget.textColor.withValues(alpha: 0.7),
      );
    }
  }
}
