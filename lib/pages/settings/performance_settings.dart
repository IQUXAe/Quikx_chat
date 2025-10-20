import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:quikxchat/utils/memory_manager.dart';


class PerformanceSettingsPage extends StatefulWidget {
  const PerformanceSettingsPage({super.key});

  @override
  State<PerformanceSettingsPage> createState() => _PerformanceSettingsPageState();
}

class _PerformanceSettingsPageState extends State<PerformanceSettingsPage> {
  Map<String, dynamic>? _memoryStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final stats = MemoryManager().getMemoryStats();
      if (mounted) {
        setState(() {
          _memoryStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Производительность'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMemorySection(),
                const SizedBox(height: 24),
                _buildCacheSection(),
                const SizedBox(height: 24),
                _buildActionsSection(),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  _buildDebugSection(),
                ],
              ],
            ),
    );
  }

  Widget _buildMemorySection() {
    if (_memoryStats == null) return const SizedBox.shrink();

    final imageCache = _memoryStats!['image_cache'] as Map<String, dynamic>;
    final usagePercent = imageCache['usage_percent'] as int;
    final currentBytes = imageCache['current_bytes'] as int;
    final maxBytes = imageCache['maximum_bytes'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.memory),
                SizedBox(width: 8),
                Text(
                  'Память',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Прогресс-бар использования памяти
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: usagePercent / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usagePercent > 80 ? Colors.red :
                      usagePercent > 60 ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$usagePercent%'),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              'Кэш изображений: ${(currentBytes / (1024 * 1024)).toStringAsFixed(1)} MB / '
              '${(maxBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                _buildStatChip(
                  'Изображений',
                  '${imageCache['current_size']}/${imageCache['maximum_size']}',
                  Icons.image,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Мало памяти',
                  _memoryStats!['is_low_memory'] ? 'Да' : 'Нет',
                  Icons.warning,
                  color: _memoryStats!['is_low_memory'] ? Colors.red : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheSection() {
    if (_memoryStats == null) return const SizedBox.shrink();

    final caches = _memoryStats!['app_caches'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage),
                SizedBox(width: 8),
                Text(
                  'Кэши приложения',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...caches.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getCacheName(entry.key)),
                    Chip(
                      label: Text('${entry.value}'),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cleaning_services),
                SizedBox(width: 8),
                Text(
                  'Действия',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Очистить кэш изображений'),
              subtitle: const Text('Освободить память, удалив кэшированные изображения'),
              onTap: () => _clearImageCache(),
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Очистить все кэши'),
              subtitle: const Text('Удалить все кэшированные данные'),
              onTap: () => _clearAllCaches(),
            ),
            
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Оптимизировать память'),
              subtitle: const Text('Принудительная оптимизация использования памяти'),
              onTap: () => _optimizeMemory(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection() {
    if (_memoryStats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report),
                SizedBox(width: 8),
                Text(
                  'Отладка',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Время: ${_memoryStats!['timestamp']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Оптимизация: ${_memoryStats!['is_optimizing'] ? 'Активна' : 'Неактивна'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, {Color? color}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
      backgroundColor: color?.withOpacity(0.1) ?? Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  String _getCacheName(String key) {
    switch (key) {
      case 'profiles':
        return 'Профили';
      case 'avatars':
        return 'Аватары';
      case 'eventContents':
        return 'События';
      case 'translations':
        return 'Переводы';
      default:
        return key;
    }
  }

  void _clearImageCache() {
    MemoryManager().clearImageCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Кэш изображений очищен')),
    );
    _loadStats();
  }

  void _clearAllCaches() {
    MemoryManager().forceOptimization();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Все кэши очищены')),
    );
    _loadStats();
  }

  void _optimizeMemory() {
    MemoryManager().optimizeForLowMemory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Память оптимизирована')),
    );
    Future.delayed(const Duration(seconds: 1), () => _loadStats());
  }
}
