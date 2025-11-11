import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/utils/error_reporter.dart';
import 'package:quikxchat/utils/localized_exception_extension.dart';

/// Общий класс для часто используемых операций с ошибками
class ErrorHelpers {
  /// Показывает сообщение об ошибке через SnackBar
  static void showErrorMessage(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        action: SnackBarAction(
          label: L10n.of(context).close,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Показывает сообщение об ошибке с локализацией
  static void showLocalizedError(BuildContext context, Object error) {
    showErrorMessage(context, error.toLocalizedString(context));
  }

  /// Обработка ошибки с отчетом и отображением сообщения
  static void handleAndReportError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    String contextMessage,
  ) {
    ErrorReporter(context, contextMessage).onErrorCallback(error, stackTrace);
    showLocalizedError(context, error);
  }

  /// Обработка ошибки с кастомным сообщением
  static void handleCustomError(
    BuildContext context,
    Object error,
    String customMessage,
  ) {
    ErrorReporter(context, customMessage).onErrorCallback(error, null);
    showErrorMessage(context, customMessage);
  }

  /// Проверяет, является ли ошибка сетевой
  static bool isNetworkError(Object error) {
    // Проверяем на основе типа ошибки и сообщения
    if (error is MatrixException) {
      // Проверяем по коду ошибки, если он известен
      if (error is dynamic) {
        final matrixError = error as MatrixException;
        final errorCode = matrixError.error;
        // Вместо конкретных констант проверяем на основе строк
        final errorString = errorCode.toString();
        return errorString.contains('LIMIT_EXCEEDED') || 
               errorString.contains('UNKNOWN_TOKEN') ||
               errorString.contains('UNAUTHORIZED');
      }
    }
    return error is io.IOException || 
           error.toString().toLowerCase().contains('network') ||
           error.toString().toLowerCase().contains('connection');
  }

  /// Показывает сообщение о сетевой ошибке
  static void showNetworkError(BuildContext context) {
    final l10n = L10n.of(context);
    showErrorMessage(context, 'No network connection'); // Используем строку вместо несуществующего поля
  }

  /// Проверяет, требуется ли повторная авторизация
  static bool requiresReauthentication(Object error) {
    if (error is MatrixException) {
      final errorCode = error.error;
      final errorString = errorCode.toString();
      return errorString.contains('UNKNOWN_TOKEN') || 
             errorString.contains('UNAUTHORIZED');
    }
    return false;
  }

  /// Проверяет, является ли ошибка о квоте
  static bool isQuotaExceeded(Object error) {
    if (error is MatrixException) {
      final errorCode = error.error;
      final errorString = errorCode.toString();
      return errorString.contains('LIMIT_EXCEEDED');
    }
    return false;
  }

  /// Проверяет, связана ли ошибка с согласием на политику
  static bool requiresConsent(Object error) {
    if (error is MatrixException) {
      final errorCode = error.error;
      final errorString = errorCode.toString();
      return errorString.contains('CONSENT_NOT_GIVEN');
    }
    return false;
  }
}