import 'dart:async';
import 'package:matrix/matrix.dart';

class TranslationRateLimiter {
  static const int _maxRequestsPerMinute = 20;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static const int _maxRetries = 2;
  
  final List<DateTime> _requestTimes = [];
  final Map<String, Completer<String?>> _pendingRequests = {};
  
  static final TranslationRateLimiter _instance = TranslationRateLimiter._();
  factory TranslationRateLimiter() => _instance;
  TranslationRateLimiter._();
  
  Future<String?> execute(
    String key,
    Future<String?> Function() request,
  ) async {
    if (_pendingRequests.containsKey(key)) {
      return _pendingRequests[key]!.future;
    }
    
    final completer = Completer<String?>();
    _pendingRequests[key] = completer;
    
    try {
      final result = await _executeWithRetry(request);
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(key);
    }
  }
  
  Future<String?> _executeWithRetry(Future<String?> Function() request) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        await _waitForRateLimit();
        _recordRequest();
        
        final result = await request().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Translation timeout'),
        );
        
        return result;
      } catch (e) {
        Logs().w('[RateLimiter] Attempt ${attempt + 1} failed: $e');
        
        if (attempt < _maxRetries - 1) {
          final delay = _retryDelay * (attempt + 1);
          await Future.delayed(delay);
        } else {
          rethrow;
        }
      }
    }
    return null;
  }
  
  Future<void> _waitForRateLimit() async {
    _cleanOldRequests();
    
    while (_requestTimes.length >= _maxRequestsPerMinute) {
      await Future.delayed(const Duration(milliseconds: 500));
      _cleanOldRequests();
    }
  }
  
  void _recordRequest() {
    _requestTimes.add(DateTime.now());
  }
  
  void _cleanOldRequests() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    _requestTimes.removeWhere((time) => time.isBefore(cutoff));
  }
  
  void reset() {
    _requestTimes.clear();
    _pendingRequests.clear();
  }
}
