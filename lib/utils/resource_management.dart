import 'dart:async';
import 'package:flutter/widgets.dart';

/// Класс для управления ресурсами виджета с автоматической очисткой
class WidgetResourceManager {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<VoidCallback> _disposers = [];

  /// Добавить подписку для автоматической отмены
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Добавить таймер для автоматической отмены
  void addTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Добавить функцию очистки ресурсов
  void addDisposer(VoidCallback disposer) {
    _disposers.add(disposer);
  }

  /// Очистить все ресурсы
  void dispose() {
    for (final subscription in _subscriptions) {
      if (!subscription.isPaused) {
        subscription.cancel();
      }
    }
    _subscriptions.clear();

    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }

  /// Получить количество управляемых ресурсов (для отладки)
  int get resourceCount => _subscriptions.length + _timers.length + _disposers.length;
}

/// Миксин для автоматического управления ресурсами
mixin ResourceDisposable<T extends StatefulWidget> on State<T> {
  final WidgetResourceManager _resourceManager = WidgetResourceManager();

  WidgetResourceManager get resourceManager => _resourceManager;

  @override
  void dispose() {
    _resourceManager.dispose();
    super.dispose();
  }
}

/// Утилита для безопасного выполнения асинхронных операций
class SafeAsyncExecutor {
  /// Выполнить асинхронную операцию с проверкой на mounted
  static Future<void> executeAsync(
    Future<void> Function() asyncOperation,
    BuildContext context, {
    VoidCallback? onError,
  }) async {
    if (!context.mounted) return;
    
    try {
      await asyncOperation();
      if (!context.mounted) return;
    } catch (e) {
      if (context.mounted) {
        onError?.call();
      }
    }
  }

  /// Выполнить Future с возвратом значения и проверкой mounted
  static Future<T?> executeAsyncWithResult<T>(
    Future<T> future,
    BuildContext context, {
    T? defaultValue,
  }) async {
    if (!context.mounted) return defaultValue;
    
    try {
      final result = await future;
      return context.mounted ? result : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}

/// Утилита для отложенного выполнения с отменой
class Debouncer {
  Timer? _timer;
  final int delay;

  Debouncer({this.delay = 300});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delay), callback);
  }

  void cancel() {
    _timer?.cancel();
  }
}