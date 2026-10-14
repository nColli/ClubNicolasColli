import 'package:flutter/material.dart';

import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';

/// Resumen del espacio, la duración y el total a pagar.
class ResumenReserva extends StatelessWidget {
  final Espacio espacio;
  final int horas;

  const ResumenReserva({super.key, required this.espacio, required this.horas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      espacio.titulo,
                      style: const TextStyle(
                        color: AppColors.lightTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${espacio.tipo} · ${horas}h',
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${Formatters.precio(espacio.precioHora)} × $horas',
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.lightBorder),
          ),
          const Text(
            'Total',
            style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 12),
          ),
          Text(
            Formatters.precio(espacio.precioHora * horas),
            style: const TextStyle(
              color: AppColors.lightTextPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
