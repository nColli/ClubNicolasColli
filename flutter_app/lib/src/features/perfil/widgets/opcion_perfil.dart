import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

/// Tarjeta con una sección chica arriba y una opción que se puede tocar
/// ("Seguridad / Cambiar contraseña >").
class OpcionPerfil extends StatelessWidget {
  final String seccion;
  final String titulo;
  final VoidCallback onTap;

  const OpcionPerfil({
    super.key,
    required this.seccion,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seccion,
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.lightTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
