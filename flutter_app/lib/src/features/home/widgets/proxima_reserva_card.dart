import 'package:flutter/material.dart';

import 'package:flutter_app/src/widgets/widgets.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';

class ProximaReservaCard extends StatelessWidget {
  final Reserva? reserva;
  final VoidCallback onVerReservas;
  final VoidCallback onReservar;

  /// Se llama al tocar la card cuando hay una reserva
  final ValueChanged<Reserva> onTap;

  const ProximaReservaCard({
    super.key,
    required this.reserva,
    required this.onVerReservas,
    required this.onReservar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reserva = this.reserva;

    return Material(
      color: AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: reserva == null ? null : () => onTap(reserva),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PRÓXIMA RESERVA',
                      style: TextStyle(
                        color: AppColors.olive,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                  if (reserva != null)
                    GestureDetector(
                      onTap: onVerReservas,
                      child: Text(
                        '${Formatters.diasHasta(reserva.fecha)} →',
                        style: const TextStyle(
                          color: AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (reserva == null) _sinReservas() else ..._conReserva(reserva),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sinReservas() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'No tenés reservas próximas.',
            style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: onReservar,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.neonYellow,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text(
            'Reservar',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  List<Widget> _conReserva(Reserva reserva) {
    return [
      Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 48,
              height: 48,
              child: SedeImagen(url: reserva.sedeImagenUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sede ${reserva.sedeNombre}',
                  style: const TextStyle(
                    color: AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reserva.espacioNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.hora(reserva.horaInicio),
                style: const TextStyle(
                  color: AppColors.olive,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.hora(reserva.horaFin),
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: AppColors.lightBorder),
      ),
      Row(
        children: [
          Expanded(
            child: Text(
              Formatters.fechaCorta(reserva.fecha),
              style: const TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            Formatters.precio(reserva.precioTotal),
            style: const TextStyle(
              color: AppColors.lightTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ];
  }
}
