import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.danger = false,
    this.confirmColor,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool danger;
  final Color? confirmColor;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        danger: danger,
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final c = confirmColor ?? (danger ? AppColors.red : AppColors.primary);
    return AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: c),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
