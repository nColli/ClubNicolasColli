import 'package:flutter/material.dart';

import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/features/reservas/widgets/estado_reserva_badge.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Card de una reserva del usuario: sede, espacio, fecha, horario y precio.
/// Muestra el estado si se indica, el botón "Cancelar" si hay [onCancelar] y
/// abre el detalle con [onTap].
class ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final EstadoReserva? estado;
  final VoidCallback? onCancelar;
  final VoidCallback? onTap;

  const ReservaCard({
    super.key,
    required this.reserva,
    this.estado,
    this.onCancelar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final estado = this.estado;
    final onCancelar = this.onCancelar;

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      EstiloDeporte.de(reserva.espacioTipo).emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sede ${reserva.sedeNombre}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.lightTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (estado != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: EstadoReservaBadge(estado: estado),
                              ),
                          ],
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
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _Dato(
                              icono: Icons.calendar_today_outlined,
                              texto: Formatters.fechaCorta(reserva.fecha),
                            ),
                            _Dato(
                              icono: Icons.schedule,
                              texto: Formatters.rangoHorario(
                                reserva.horaInicio,
                                reserva.horaFin,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                      Formatters.precio(reserva.precioTotal),
                      style: const TextStyle(
                        color: AppColors.olive,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (onCancelar != null)
                    OutlinedButton.icon(
                      onPressed: onCancelar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        backgroundColor: Colors.red.shade50,
                        side: BorderSide(color: Colors.red.shade200),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 12, color: AppColors.lightTextSecondary),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
