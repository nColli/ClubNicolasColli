import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Tarjeta con la sede y los datos de una reserva: espacio, fecha, horario
/// y total. Se usa al confirmar una reserva y en su detalle.
class DetalleReservaCard extends StatelessWidget {
  final String? imagenUrl;
  final String sedeNombre;
  final String espacioTipo;

  /// "Fútbol 1"
  final String espacioTitulo;
  final DateTime fecha;
  final int horaInicio;
  final int horaFin;
  final double total;

  const DetalleReservaCard({
    super.key,
    required this.imagenUrl,
    required this.sedeNombre,
    required this.espacioTipo,
    required this.espacioTitulo,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SedeHero(
            imagenUrl: imagenUrl,
            eyebrow: '$espacioTipo · $espacioTitulo',
            titulo: 'Sede $sedeNombre',
            height: 140,
          ),
          _Fila(label: 'Espacio', valor: espacioTitulo),
          _Fila(label: 'Fecha', valor: Formatters.fechaLarga(fecha)),
          _Fila(
            label: 'Horario',
            valor: '${Formatters.rangoHorario(horaInicio, horaFin)} hs',
          ),
          _Fila(
            label: 'Total',
            valor: Formatters.precio(total),
            colorValor: AppColors.olive,
            ultima: true,
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String label;
  final String valor;
  final Color colorValor;
  final bool ultima;

  const _Fila({
    required this.label,
    required this.valor,
    this.colorValor = AppColors.lightTextPrimary,
    this.ultima = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor.toUpperCase(),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colorValor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
