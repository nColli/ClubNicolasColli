import 'package:flutter/material.dart';

import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/theme/theme.dart';

/// Etiqueta con el estado de una reserva ("Activa", "Completada").
class EstadoReservaBadge extends StatelessWidget {
  final EstadoReserva estado;

  const EstadoReservaBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: estado.fondo,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          color: estado.texto,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
