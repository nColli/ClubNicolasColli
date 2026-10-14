import 'package:flutter/material.dart';

import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';

/// Grilla de dos columnas con los turnos del día. Los que no están
/// disponibles se muestran tachados y no se pueden elegir.
class GrillaTurnos extends StatelessWidget {
  final List<Turno> turnos;
  final int? horaSeleccionada;
  final ValueChanged<Turno> onSeleccionar;

  const GrillaTurnos({
    super.key,
    required this.turnos,
    required this.horaSeleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.6,
          children: [
            for (final turno in turnos)
              _TurnoChip(
                turno: turno,
                activo: turno.horaInicio == horaSeleccionada,
                onTap: () => onSeleccionar(turno),
              ),
          ],
        ),
        if (turnos.any((t) => !t.disponible)) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.lightBorder),
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Los horarios tachados están ocupados o ya pasaron.',
                  style: TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TurnoChip extends StatelessWidget {
  final Turno turno;
  final bool activo;
  final VoidCallback onTap;

  const _TurnoChip({
    required this.turno,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disponible = turno.disponible;
    return GestureDetector(
      onTap: disponible ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo ? AppColors.neonYellow : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: activo ? AppColors.neonYellow : AppColors.lightBorder,
          ),
        ),
        child: Text(
          Formatters.rangoHorario(turno.horaInicio, turno.horaFin),
          style: TextStyle(
            color: disponible
                ? AppColors.lightTextPrimary
                : AppColors.lightTextSecondary.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: activo ? FontWeight.w900 : FontWeight.w700,
            decoration: disponible ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}
