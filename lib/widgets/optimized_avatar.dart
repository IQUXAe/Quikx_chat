import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:quikxchat/utils/global_cache.dart';
import 'package:quikxchat/widgets/mxc_image.dart';

/// Оптимизированный аватар с кэшированием
class OptimizedAvatar extends StatelessWidget {
  final String? mxcUrl;
  final String name;
  final double size;
  final void Function()? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const OptimizedAvatar({
    super.key,
    required this.mxcUrl,
    required this.name,
    this.size = 40,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  /// Создает аватар для пользователя с кэшированием
  factory OptimizedAvatar.user(
    User user, {
    double size = 40,
    void Function()? onTap,
  }) {
    return OptimizedAvatar(
      mxcUrl: user.avatarUrl?.toString(),
      name: user.calcDisplayname(),
      size: size,
      onTap: onTap,
    );
  }

  /// Создает аватар для комнаты с кэшированием
  factory OptimizedAvatar.room(
    Room room, {
    double size = 40,
    void Function()? onTap,
  }) {
    return OptimizedAvatar(
      mxcUrl: room.avatar?.toString(),
      name: room.getLocalizedDisplayname(),
      size: size,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Проверяем кэш для аватара
    final cacheKey = '${mxcUrl}_$size';
    final cachedData = AppCaches.avatars.get(cacheKey);
    
    Widget avatar;
    
    if (mxcUrl != null && cachedData == null) {
      // Загружаем аватар и кэшируем результат
      avatar = MxcImage(
        uri: Uri.parse(mxcUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(theme),
        errorWidget: (context, url, error) => _buildPlaceholder(theme),
      );
      
      // Кэшируем успешную загрузку
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppCaches.avatars.put(cacheKey, mxcUrl!);
      });
    } else {
      // Используем placeholder
      avatar = _buildPlaceholder(theme);
    }

    // Оборачиваем в контейнер
    final container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatar,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: container,
      );
    }

    return container;
  }

  Widget _buildPlaceholder(ThemeData theme) {
    // Генерируем initials из имени
    final initials = _getInitials(name);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: backgroundColor ?? _getColorFromName(name, colorScheme),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor ?? colorScheme.onPrimaryContainer,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
  }

  Color _getColorFromName(String name, ColorScheme colorScheme) {
    if (name.isEmpty) return colorScheme.primaryContainer;
    
    final hash = name.hashCode;
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.errorContainer,
      Colors.teal.shade200,
      Colors.purple.shade200,
      Colors.orange.shade200,
      Colors.green.shade200,
    ];
    
    return colors[hash.abs() % colors.length];
  }
}

/// Компактная версия аватара для списков
class CompactAvatar extends StatelessWidget {
  final String? mxcUrl;
  final String name;
  final double size;

  const CompactAvatar({
    super.key,
    required this.mxcUrl,
    required this.name,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials(name);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: _getColorFromName(name, theme.colorScheme),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Color _getColorFromName(String name, ColorScheme colorScheme) {
    if (name.isEmpty) return colorScheme.primaryContainer;
    final hash = name.hashCode;
    final colors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];
    return colors[hash.abs() % colors.length];
  }
}
