import 'package:flutter/material.dart';
import 'package:quikxchat/l10n/l10n.dart';
import 'package:quikxchat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:quikxchat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:quikxchat/widgets/future_loading_dialog.dart';

/// Общий класс для часто используемых UI операций
class UIHelpers {
  /// Показывает диалог подтверждения с часто используемыми параметрами
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    String? message,
    String? okLabel,
    String? cancelLabel,
    bool isDestructive = false,
  }) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: title,
      message: message,
      okLabel: okLabel ?? L10n.of(context).ok,
      cancelLabel: cancelLabel ?? L10n.of(context).cancel,
      isDestructive: isDestructive,
    );
    // showOkCancelAlertDialog returns OkCancelResult? but we want bool?
    return result == OkCancelResult.ok;
  }

  /// Показывает диалог подтверждения удаления
  static Future<bool?> showDeleteConfirmationDialog({
    required BuildContext context,
    required String title,
    String? message,
    String? deleteLabel,
    String? cancelLabel,
  }) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: title,
      message: message,
      okLabel: deleteLabel ?? L10n.of(context).delete,
      cancelLabel: cancelLabel ?? L10n.of(context).cancel,
      isDestructive: true,
    );
    // showOkCancelAlertDialog returns OkCancelResult? but we want bool?
    return result == OkCancelResult.ok;
  }

  /// Показывает диалог для ввода текста с часто используемыми параметрами
  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    String? message,
    String? hintText,
    String? initialText,
    String? okLabel,
    String? cancelLabel,
    TextInputType? keyboardType,
    bool autocorrect = true,
    int? maxLength,
    int? maxLines,
    int? minLines,
    bool isDestructive = false,
    String? Function(String?)? validator,
  }) async {
    return await showTextInputDialog(
      context: context,
      title: title,
      message: message,
      hintText: hintText,
      initialText: initialText,
      okLabel: okLabel ?? L10n.of(context).ok,
      cancelLabel: cancelLabel ?? L10n.of(context).cancel,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      isDestructive: isDestructive,
      validator: validator,
    );
  }

  /// Упрощенный вызов Future Loading Dialog с часто используемыми параметрами
  static Future<T?> showLoadingDialog<T>({
    required BuildContext context,
    required Future<T> Function() future,
    dynamic exceptionContext,
    bool delay = true,
  }) async {
    final result = await showFutureLoadingDialog<T>(
      context: context,
      future: future,
      exceptionContext: exceptionContext,
      delay: delay,
    );
    return result.result;
  }

  /// Упрощенный вызов Future Loading Dialog с обработкой результата
  static Future<void> showLoadingDialogWithResult<T>({
    required BuildContext context,
    required Future<T> Function() future,
    dynamic exceptionContext,
    void Function(T result)? onSuccess,
    void Function(dynamic error)? onError,
  }) async {
    final result = await showFutureLoadingDialog<T>(
      context: context,
      future: future,
      exceptionContext: exceptionContext,
    );

    if (result.error != null) {
      onError?.call(result.error);
    } else if (result.result != null) {
      onSuccess?.call(result.result!);
    }
  }
}

/// Класс для часто используемых UI элементов
class UIElements {
  /// Создает стандартную кнопку с подтверждением
  static Widget buildConfirmationButton({
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isDestructive = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red : backgroundColor,
        foregroundColor: foregroundColor,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  /// Создает стандартный список настроек
  static Widget buildSettingsList({
    required List<Widget> children,
    EdgeInsets? padding,
  }) {
    return ListView(
      padding: padding ?? const EdgeInsets.all(16.0),
      children: children,
    );
  }
}