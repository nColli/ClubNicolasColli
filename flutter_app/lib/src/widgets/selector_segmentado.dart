import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

/// Control segmentado: una fila de opciones donde la elegida se resalta en
/// neón ("1 hora | 2 horas", "Próximas | Historial").
class SelectorSegmentado<T> extends StatelessWidget {
  final List<T> opciones;
  final T seleccionada;
  final String Function(T opcion) etiqueta;
  final ValueChanged<T> onSeleccionar;

  const SelectorSegmentado({
    super.key,
    required this.opciones,
    required this.seleccionada,
    required this.etiqueta,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          for (final opcion in opciones)
            Expanded(
              child: GestureDetector(
                onTap: () => onSeleccionar(opcion),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: opcion == seleccionada
                        ? AppColors.neonYellow
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    etiqueta(opcion),
                    style: TextStyle(
                      color: opcion == seleccionada
                          ? Colors.black
                          : AppColors.lightTextSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
