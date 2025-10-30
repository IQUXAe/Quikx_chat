import 'dart:async';
import 'package:matrix/matrix.dart';
import 'translation_providers.dart';
import 'translation_cache.dart';
import 'translation_rate_limiter.dart';

class TranslationBatchProcessor {
  static const Duration _batchDelay = Duration(milliseconds: 100);
  static const int _maxBatchSize = 10;
  
  final List<_TranslationRequest> _queue = [];
  Timer? _batchTimer;
  
  static final TranslationBatchProcessor _instance = TranslationBatchProcessor._();
  factory TranslationBatchProcessor() => _instance;
  TranslationBatchProcessor._();
  
  final _cache = TranslationCache();
  final _rateLimiter = TranslationRateLimiter();
  
  Future<String?> translate(String text, String from, String to) async {
    final cached = await _cache.get(text, from, to);
    if (cached != null) return cached;
    
    final completer = Completer<String?>();
    final request = _TranslationRequest(text, from, to, completer);
    
    _queue.add(request);
    _scheduleBatch();
    
    return completer.future;
  }
  
  void _scheduleBatch() {
    _batchTimer?.cancel();
    
    if (_queue.length >= _maxBatchSize) {
      _processBatch();
    } else {
      _batchTimer = Timer(_batchDelay, _processBatch);
    }
  }
  
  Future<void> _processBatch() async {
    if (_queue.isEmpty) return;
    
    final batch = _queue.take(_maxBatchSize).toList();
    _queue.removeRange(0, batch.length);
    
    for (final request in batch) {
      try {
        final key = '${request.text.hashCode}_${request.from}_${request.to}';
        final result = await _rateLimiter.execute(
          key,
          () => TranslationProviders.translateText(request.text, request.from, request.to),
        );
        
        if (result != null) {
          await _cache.put(request.text, request.from, request.to, result);
          request.completer.complete(result);
        } else {
          request.completer.complete(null);
        }
      } catch (e) {
        Logs().w('[BatchProcessor] Failed: $e');
        request.completer.completeError(e);
      }
    }
  }
  
  void dispose() {
    _batchTimer?.cancel();
    _queue.clear();
  }
}

class _TranslationRequest {
  final String text;
  final String from;
  final String to;
  final Completer<String?> completer;
  
  _TranslationRequest(this.text, this.from, this.to, this.completer);
}
