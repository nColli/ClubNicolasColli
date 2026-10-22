import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/estilo_deporte.dart';

class FiltroDeportes extends StatelessWidget {
  final List<String> deportes;
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  const FiltroDeportes({
    super.key,
    required this.deportes,
    required this.seleccionado,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final opciones = <String?>[null, ...deportes];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: opciones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) { //aca renderiza todas las opciones - los deportse se los paso en inicio_tab
          final deporte = opciones[i];
          final activo = deporte == seleccionado;
          final emoji = deporte == null
              ? null
              : EstiloDeporte.de(deporte).emoji;

          return GestureDetector(
            onTap: () => onSeleccionar(deporte),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activo ? AppColors.neonYellow : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: activo ? AppColors.neonYellow : AppColors.lightBorder,
                ),
              ),
              child: Text(
                emoji == null ? 'Todos' : '$emoji  $deporte',
                style: TextStyle(
                  color: AppColors.lightTextPrimary,
                  fontSize: 13,
                  fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
