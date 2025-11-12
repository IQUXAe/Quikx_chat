import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:quikxchat/l10n/l10n.dart';

/// Утилиты для стандартизированной обработки ошибок
class ErrorHandlingUtils {
  /// Показать сообщение об ошибке пользователю
  static void showErrorMessage(BuildContext context, String message, {String? title}) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.of(context).ok),
          ),
        ],
      ),
    );
  }

  /// Показать сообщение об ошибке с логированием
  static void showErrorWithLog(BuildContext context, Object error, StackTrace? stackTrace, {String? title}) {
    Logs().e('Error occurred: $error', error, stackTrace);
    showErrorMessage(context, error.toString(), title: title);
  }

  /// Показать сообщение об ошибке, только если оно не является отменой
  static void showErrorIfNotCancelled(BuildContext context, Object error, String message) {
    // Проверяем, является ли ошибка отменой операции
    if (_isCancellationError(error)) {
      return; // Не показываем ошибку, если это отмена
    }
    showErrorMessage(context, message);
  }

  /// Проверить, является ли ошибка отменой операции
  static bool _isCancellationError(Object error) {
    return error is Exception && 
           (error.toString().toLowerCase().contains('cancelled') || 
            error.toString().toLowerCase().contains('cancellation'));
  }

  /// Обработать Future с автоматическим отображением ошибок
  static Future<T?> handleFutureWithErrors<T>(
    Future<T> future,
    BuildContext context, {
    String? errorMessage,
    String? successMessage,
    void Function(T result)? onSuccess,
    void Function(Object error)? onError,
  }) async {
    try {
      final result = await future;
      if (successMessage != null && context.mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage)),
          );
        }
      }
      onSuccess?.call(result);
      return result;
    } catch (error, stack) {
      Logs().e('Handled error: $error', error, stack);
      onError?.call(error);
      final message = errorMessage ?? 'An error occurred';
      if (context.mounted) {
        showErrorMessage(context, message);
      }
      return null;
    }
  }

  /// Обработать Future с логированием ошибок без отображения пользователю
  static Future<T?> handleFutureWithLogging<T>(
    Future<T> future, {
    String? operationName,
  }) async {
    try {
      final result = await future;
      if (operationName != null) {
        Logs().d('$operationName completed successfully');
      }
      return result;
    } catch (error, stack) {
      final operation = operationName ?? 'Operation';
      Logs().e('$operation failed: $error', error, stack);
      rethrow;
    }
  }
}

/// Расширение для удобного использования утилит ошибок
extension ErrorHandlingContext on BuildContext {
  /// Показать ошибку с этого контекста
  void showErrorMessage(String message, {String? title}) {
    ErrorHandlingUtils.showErrorMessage(this, message, title: title);
  }

  /// Показать ошибку с логированием
  void showErrorWithLog(Object error, StackTrace? stackTrace, {String? title}) {
    ErrorHandlingUtils.showErrorWithLog(this, error, stackTrace, title: title);
  }

  /// Обработать Future с автоматической обработкой ошибок
  Future<T?> handleFutureWithErrors<T>(
    Future<T> future, {
    String? errorMessage,
    String? successMessage,
    void Function(T result)? onSuccess,
    void Function(Object error)? onError,
  }) {
    return ErrorHandlingUtils.handleFutureWithErrors<T>(
      future,
      this,
      errorMessage: errorMessage,
      successMessage: successMessage,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}