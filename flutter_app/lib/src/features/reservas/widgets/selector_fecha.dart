import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';

/// Fila horizontal de días para elegir la fecha de la reserva.
class SelectorFecha extends StatelessWidget {
  final List<DateTime> fechas;
  final DateTime seleccionada;

  /// Días en que la sede no abre: se muestran deshabilitados
  final bool Function(DateTime fecha) estaCerrado;
  final ValueChanged<DateTime> onSeleccionar;

  const SelectorFecha({
    super.key,
    required this.fechas,
    required this.seleccionada,
    required this.estaCerrado,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: fechas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final fecha = fechas[i];
          final activa = DateUtils.isSameDay(fecha, seleccionada);
          final cerrado = estaCerrado(fecha);
          final colorTexto = cerrado
              ? AppColors.lightBorder
              : AppColors.lightTextPrimary;

          return GestureDetector(
            onTap: cerrado ? null : () => onSeleccionar(fecha),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              decoration: BoxDecoration(
                color: activa
                    ? AppColors.neonYellow
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: activa ? AppColors.neonYellow : AppColors.lightBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Formatters.diaSemanaCorto(fecha).toUpperCase(),
                    style: TextStyle(
                      color: activa ? Colors.black : colorTexto,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fecha.day}',
                    style: TextStyle(
                      color: activa ? Colors.black : colorTexto,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
