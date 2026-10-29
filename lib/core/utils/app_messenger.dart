import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Global snackbar access, so feedback still appears when the page that
/// started an action has already been replaced by auth-driven routing.
abstract final class AppMessenger {
  static final GlobalKey<ScaffoldMessengerState> key =
      GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) =>
      _show(message, AppColors.success, Icons.check_circle_outline);

  static void showError(String message) =>
      _show(message, AppColors.error, Icons.error_outline);

  static void _show(String message, Color color, IconData icon) {
    final messenger = key.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.6)),
          ),
        ),
      );
  }
}
