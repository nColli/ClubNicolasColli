import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

/// Indicador de los pasos de la reserva: Elegiste → Confirmás → ¡Listo!
class PasosReserva extends StatelessWidget {
  static const _pasos = ['Elegiste horario', 'Confirmás', '¡Listo!'];

  /// Paso en curso, empezando en 1. Los anteriores se muestran completos.
  final int pasoActual;

  const PasosReserva({super.key, required this.pasoActual});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _pasos.length; i++) ...[
          if (i > 0)
            Container(
              width: 24,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: i < pasoActual
                  ? AppColors.neonYellow
                  : AppColors.lightBorder,
            ),
          // Con poco ancho los textos se cortan en vez de desbordar
          Flexible(
            child: _Paso(
              numero: i + 1,
              label: _pasos[i],
              completo: i + 1 < pasoActual || pasoActual == _pasos.length,
              actual: i + 1 == pasoActual,
            ),
          ),
        ],
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  final int numero;
  final String label;
  final bool completo;
  final bool actual;

  const _Paso({
    required this.numero,
    required this.label,
    required this.completo,
    required this.actual,
  });

  @override
  Widget build(BuildContext context) {
    final resaltado = completo || actual;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: resaltado
                ? AppColors.neonYellow
                : AppColors.lightTextPrimary,
            shape: BoxShape.circle,
          ),
          child: completo
              ? const Icon(Icons.check, size: 13, color: Colors.black)
              : Text(
                  '$numero',
                  style: TextStyle(
                    color: resaltado ? Colors.black : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: actual
                  ? AppColors.lightTextPrimary
                  : AppColors.lightTextSecondary,
              fontSize: 11,
              fontWeight: actual ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
