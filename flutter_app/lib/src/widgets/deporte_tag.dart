import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/estilo_deporte.dart';

/// Etiqueta con el emoji y el color de un deporte ("⚽ Fútbol").
class DeporteTag extends StatelessWidget {
  final String deporte;

  const DeporteTag({super.key, required this.deporte});

  @override
  Widget build(BuildContext context) {
    final estilo = EstiloDeporte.de(deporte);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: estilo.fondo,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${estilo.emoji} $deporte',
        style: TextStyle(
          color: estilo.texto,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
