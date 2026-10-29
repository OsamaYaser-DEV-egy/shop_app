import 'package:flutter/material.dart';

/// Central color palette for the dark theme.
abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0B1020);
  static const Color surface = Color(0xFF131A2E);
  static const Color card = Color(0xFF182038);
  static const Color border = Color(0xFF263152);

  // Accents
  static const Color primary = Color(0xFF7C5CFF); // purple
  static const Color secondary = Color(0xFF2D8CFF); // electric blue

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9AA4BF);

  // Status
  static const Color success = Color(0xFF2ECC8F);
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFFF5C6C);
}
