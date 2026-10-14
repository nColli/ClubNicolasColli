import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

/// Ícono de ojo para mostrar u ocultar una contraseña.
class PasswordVisibilityButton extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;

  const PasswordVisibilityButton({
    super.key,
    required this.obscured,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }
}
