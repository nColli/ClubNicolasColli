/// Una hora del día en que la sede está abierta y si se puede reservar.
class HoraDisponibilidad {
  final int hora;
  final bool disponible;

  const HoraDisponibilidad({required this.hora, required this.disponible});

  factory HoraDisponibilidad.fromJson(Map<String, dynamic> json) =>
      HoraDisponibilidad(hora: json['hora'], disponible: json['disponible']);
}

/// Turno reservable de una o más horas seguidas.
class Turno {
  final int horaInicio;
  final int horaFin;
  final bool disponible;

  const Turno({
    required this.horaInicio,
    required this.horaFin,
    required this.disponible,
  });

  /// Arma los turnos de [duracion] horas que entran en el horario de la sede,
  /// uno por cada hora de inicio posible. Un turno está disponible solo si
  /// todas sus horas lo están.
  static List<Turno> armar(List<HoraDisponibilidad> horas, int duracion) {
    final porHora = {for (final h in horas) h.hora: h.disponible};
    return [
      for (final h in horas)
        if (List.generate(
          duracion,
          (i) => h.hora + i,
        ).every(porHora.containsKey))
          Turno(
            horaInicio: h.hora,
            horaFin: h.hora + duracion,
            disponible: List.generate(
              duracion,
              (i) => h.hora + i,
            ).every((hora) => porHora[hora]!),
          ),
    ];
  }
}
