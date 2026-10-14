import 'package:flutter/material.dart';

import 'package:flutter_app/src/models/models.dart';

/// Estado de una reserva según el momento actual.
enum EstadoReserva {
  activa('Activa', Color(0xFFF1FFB3), Color(0xFF5B7A00)),
  enCurso('En curso', Color(0xFFE3EEFF), Color(0xFF2F6BD8)),
  completada('Completada', Color(0xFFE2F6EA), Color(0xFF1E8A4C));

  final String label;
  final Color fondo;
  final Color texto;

  const EstadoReserva(this.label, this.fondo, this.texto);

  static EstadoReserva de(Reserva reserva, DateTime ahora) {
    if (reserva.terminada(ahora)) return completada;
    if (reserva.cancelable(ahora)) return activa;
    return enCurso;
  }
}
