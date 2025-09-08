import 'dart:async';
import 'dart:io';
import 'package:http/http.dart';
import 'package:matrix/matrix.dart';

class NetworkErrorHandler {
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) {
      return true;
    }
    
    if (error is TimeoutException) {
      return true;
    }
    
    if (error is ClientException) {
      return true;
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('software caused connection abort') ||
           errorString.contains('connection refused') ||
           errorString.contains('network is unreachable') ||
           errorString.contains('connection reset') ||
           errorString.contains('connection timed out') ||
           errorString.contains('no route to host') ||
           errorString.contains('socketexception') ||
           errorString.contains('handshake exception') ||
           errorString.contains('certificate verify failed') ||
           errorString.contains('connection closed') ||
           errorString.contains('broken pipe');
  }
  
  static Future<T> retryOnNetworkError<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    var attempt = 0;
    var delay = initialDelay;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (attempt >= maxRetries || !isNetworkError(e)) {
          rethrow;
        }
        
        Logs().w('Network operation failed (attempt $attempt/$maxRetries): $e. Retrying in ${delay.inSeconds}s');
        
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }
    
    throw StateError('This should never be reached');
  }
  
  static String getErrorDescription(dynamic error) {
    if (error is SocketException) {
      switch (error.osError?.errorCode) {
        case 103:
          return 'Connection aborted by software';
        case 111:
          return 'Connection refused';
        case 113:
          return 'No route to host';
        case 110:
          return 'Connection timed out';
        case 101:
          return 'Network is unreachable';
        case 104:
          return 'Connection reset by peer';
        default:
          return 'Network connection error: ${error.message} (code: ${error.osError?.errorCode})';
      }
    }
    
    if (error is TimeoutException) {
      return 'Operation timed out after ${error.duration?.inSeconds ?? 'unknown'}s';
    }
    
    if (error is ClientException) {
      return 'HTTP client error: ${error.message}';
    }
    
    if (error is MatrixException) {
      final httpStatus = error.raw['httpStatus'];
      if (httpStatus != null) {
        return 'Matrix API error: ${error.error} (HTTP $httpStatus)';
      }
      return 'Matrix API error: ${error.error}';
    }
    
    return error.toString();
  }
  
  /// Проверяет доступность сети
  static Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Ждет восстановления сети
  static Future<void> waitForNetwork({
    Duration timeout = const Duration(minutes: 2),
    Duration checkInterval = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      if (await isNetworkAvailable()) {
        return;
      }
      
      await Future.delayed(checkInterval);
    }
    
    throw TimeoutException('Network not available after ${timeout.inSeconds}s');
  }
  
  /// Выполняет операцию с ожиданием восстановления сети
  static Future<T> executeWithNetworkWait<T>(
    Future<T> Function() operation, {
    Duration networkTimeout = const Duration(minutes: 2),
    int maxRetries = 3,
  }) async {
    try {
      return await retryOnNetworkError(operation, maxRetries: maxRetries);
    } catch (e) {
      if (isNetworkError(e)) {
        Logs().w('Network error detected, waiting for network recovery: ${getErrorDescription(e)}');
        await waitForNetwork(timeout: networkTimeout);
        return await retryOnNetworkError(operation, maxRetries: maxRetries);
      }
      rethrow;
    }
  }
}