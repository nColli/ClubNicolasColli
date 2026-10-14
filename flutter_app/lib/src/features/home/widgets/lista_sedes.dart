import 'package:flutter/material.dart';

import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

class ListaSedes extends StatelessWidget {
  final List<Sede> sedes;
  final String? deporteSeleccionado;
  final ValueChanged<Sede> onAbrirSede;

  const ListaSedes({
    super.key,
    required this.sedes,
    required this.deporteSeleccionado,
    required this.onAbrirSede,
  });

  @override
  Widget build(BuildContext context) {
    if (sedes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Text(
          deporteSeleccionado == null
              ? 'No hay sedes disponibles.'
              : 'No hay sedes con $deporteSeleccionado.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.lightTextSecondary),
        ),
      );
    }

    return SizedBox(
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sedes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) =>
            SedeCard(sede: sedes[i], onTap: () => onAbrirSede(sedes[i])),
      ),
    );
  }
}
