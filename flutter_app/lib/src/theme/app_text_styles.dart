import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/app_colors.dart';

/// Estilos de texto reutilizados que no encajan en el [TextTheme].
abstract final class AppTextStyles {
  /// Texto chico en mayúsculas sobre los títulos ("NUEVA CUENTA").
  static const TextStyle eyebrow = TextStyle(
    color: AppColors.neonYellow,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.5,
  );

  /// Etiqueta encima de un campo de formulario ("EMAIL *").
  static const TextStyle fieldLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );

  /// Texto ingresado en los campos de las pantallas oscuras.
  static const TextStyle fieldInput = TextStyle(color: AppColors.textPrimary);

  /// Link de acción secundaria ("¿Olvidaste tu contraseña?").
  static const TextStyle link = TextStyle(
    color: AppColors.neonYellow,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}
