import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

class ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const ErrorView({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.lightTextPrimary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onReintentar,
            style: TextButton.styleFrom(foregroundColor: AppColors.olive),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
