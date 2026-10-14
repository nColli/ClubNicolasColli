import 'package:flutter/material.dart';

import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';

/// Avatar con las iniciales, nombre y email del usuario.
class PerfilHeader extends StatelessWidget {
  final Usuario usuario;

  const PerfilHeader({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.neonYellow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            usuario.iniciales,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.nombreCompleto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                usuario.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'MIEMBRO ACTIVO',
                style: TextStyle(
                  color: AppColors.olive,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
