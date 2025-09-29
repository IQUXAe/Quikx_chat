import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Оптимизированный ListView с улучшенной производительностью
class PerformanceListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final bool reverse;
  final EdgeInsets? padding;
  final double? itemExtent;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  const PerformanceListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.reverse = false,
    this.padding,
    this.itemExtent,
  }) : separatorBuilder = null;

  const PerformanceListView.separated({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.controller,
    this.reverse = false,
    this.padding,
    this.itemExtent,
  });

  @override
  State<PerformanceListView> createState() => _PerformanceListViewState();
}

class _PerformanceListViewState extends State<PerformanceListView> {
  final Set<int> _visibleItems = <int>{};
  bool _isScrolling = false;

  @override
  Widget build(BuildContext context) {
    if (widget.separatorBuilder != null) {
      return _buildSeparatedList();
    } else {
      return _buildRegularList();
    }
  }

  Widget _buildRegularList() {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ListView.builder(
        controller: widget.controller,
        reverse: widget.reverse,
        padding: widget.padding,
        itemExtent: widget.itemExtent,
        itemCount: widget.itemCount,
        cacheExtent: 1000, // Увеличиваем кэш для плавности
        addAutomaticKeepAlives: false, // Отключаем автоматическое сохранение состояния
        addRepaintBoundaries: true, // Включаем границы перерисовки
        addSemanticIndexes: false, // Отключаем семантические индексы для производительности
        itemBuilder: (context, index) {
          return _OptimizedListItem(
            key: ValueKey('item_$index'),
            index: index,
            isVisible: _visibleItems.contains(index),
            isScrolling: _isScrolling,
            child: widget.itemBuilder(context, index),
          );
        },
      ),
    );
  }

  Widget _buildSeparatedList() {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ListView.separated(
        controller: widget.controller,
        reverse: widget.reverse,
        padding: widget.padding,
        itemCount: widget.itemCount,
        cacheExtent: 1000,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        itemBuilder: (context, index) {
          return _OptimizedListItem(
            key: ValueKey('item_$index'),
            index: index,
            isVisible: _visibleItems.contains(index),
            isScrolling: _isScrolling,
            child: widget.itemBuilder(context, index),
          );
        },
        separatorBuilder: widget.separatorBuilder!,
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      setState(() => _isScrolling = true);
    } else if (notification is ScrollEndNotification) {
      setState(() => _isScrolling = false);
    }

    // Обновляем видимые элементы
    if (notification is ScrollUpdateNotification) {
      _updateVisibleItems(notification);
    }

    return false;
  }

  void _updateVisibleItems(ScrollUpdateNotification notification) {
    final viewport = notification.metrics;
    final itemHeight = widget.itemExtent ?? 60.0; // Предполагаемая высота элемента
    
    final startIndex = (viewport.pixels / itemHeight).floor().clamp(0, widget.itemCount - 1);
    final endIndex = ((viewport.pixels + viewport.viewportDimension) / itemHeight)
        .ceil()
        .clamp(0, widget.itemCount - 1);

    final newVisibleItems = <int>{};
    for (int i = startIndex; i <= endIndex; i++) {
      newVisibleItems.add(i);
    }

    if (!_setEquals(_visibleItems, newVisibleItems)) {
      setState(() {
        _visibleItems.clear();
        _visibleItems.addAll(newVisibleItems);
      });
    }
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

/// Оптимизированный элемент списка
class _OptimizedListItem extends StatelessWidget {
  final int index;
  final bool isVisible;
  final bool isScrolling;
  final Widget child;

  const _OptimizedListItem({
    super.key,
    required this.index,
    required this.isVisible,
    required this.isScrolling,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Во время прокрутки показываем упрощенную версию
    if (isScrolling && !isVisible) {
      return SizedBox(
        height: 60, // Примерная высота элемента
        child: Container(
          color: Colors.transparent,
        ),
      );
    }

    return RepaintBoundary(
      child: child,
    );
  }
}

/// Оптимизированный виджет для больших списков с ленивой загрузкой
class LazyPerformanceListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final bool reverse;
  final EdgeInsets? padding;
  final int preloadOffset;
  final VoidCallback? onEndReached;

  const LazyPerformanceListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.reverse = false,
    this.padding,
    this.preloadOffset = 5,
    this.onEndReached,
  });

  @override
  State<LazyPerformanceListView> createState() => _LazyPerformanceListViewState();
}

class _LazyPerformanceListViewState extends State<LazyPerformanceListView> {
  final Map<int, Widget> _builtItems = {};
  bool _isNearEnd = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ListView.builder(
        controller: widget.controller,
        reverse: widget.reverse,
        padding: widget.padding,
        itemCount: widget.itemCount,
        cacheExtent: 2000,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          // Кэшируем построенные виджеты
          if (!_builtItems.containsKey(index)) {
            _builtItems[index] = RepaintBoundary(
              key: ValueKey('lazy_item_$index'),
              child: widget.itemBuilder(context, index),
            );
          }
          
          return _builtItems[index]!;
        },
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final remaining = metrics.maxScrollExtent - metrics.pixels;
      final threshold = metrics.viewportDimension * 0.8;
      
      if (remaining <= threshold && !_isNearEnd) {
        _isNearEnd = true;
        widget.onEndReached?.call();
      } else if (remaining > threshold) {
        _isNearEnd = false;
      }

      // Очищаем кэш если он становится слишком большим
      if (_builtItems.length > 100) {
        _cleanupCache(notification.metrics);
      }
    }
    
    return false;
  }

  void _cleanupCache(ScrollMetrics metrics) {
    final itemHeight = 60.0; // Примерная высота
    final currentIndex = (metrics.pixels / itemHeight).round();
    final keepRange = 50; // Количество элементов для сохранения
    
    final keysToRemove = _builtItems.keys
        .where((key) => (key - currentIndex).abs() > keepRange)
        .toList();
    
    for (final key in keysToRemove) {
      _builtItems.remove(key);
    }
  }

  @override
  void dispose() {
    _builtItems.clear();
    super.dispose();
  }
}
