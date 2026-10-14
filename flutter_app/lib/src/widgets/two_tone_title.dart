import 'package:flutter/material.dart';

import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/theme/theme.dart';

/// Título grande en dos colores: por defecto [primero] en blanco y
/// [segundo] en amarillo, para las pantallas oscuras.
class TwoToneTitle extends StatelessWidget {
  final String primero;
  final String segundo;
  final Color colorPrimero;
  final Color colorSegundo;

  const TwoToneTitle({
    super.key,
    required this.primero,
    required this.segundo,
    this.colorPrimero = AppColors.textPrimary,
    this.colorSegundo = AppColors.neonYellow,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: context.textTheme.headlineLarge,
        children: [
          TextSpan(
            text: primero,
            style: TextStyle(color: colorPrimero),
          ),
          TextSpan(
            text: segundo,
            style: TextStyle(color: colorSegundo),
          ),
        ],
      ),
    );
  }
}
