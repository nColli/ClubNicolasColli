import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Colors
  static const Color neonYellow = Color(0xFFD4FF00);
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);

  // Translucent layers
  static final Color fieldBackground = Colors.white.withValues(alpha: 0.08);
  static final Color fieldBorder = Colors.white.withValues(alpha: 0.14);
  static final Color overlay = Colors.black.withValues(alpha: 0.78);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF616161);

  // Home (fondo claro)
  static const Color lightBackground = Color(0xFFF4F5F7);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE3E5E9);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF8A8F98);
  static const Color olive = Color.fromARGB(255, 147, 194, 7);

  // Fondos de respaldo cuando una imagen no carga
  static const Color heroPlaceholder = Color(0xFF1B2410);
  static const Color sedePlaceholder = Color(0xFF2A3A12);
}
