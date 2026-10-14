class HorarioSede {
  /// 1 = lunes, 7 = domingo
  final int diaSemana;
  final int horaApertura;
  final int horaCierre;

  const HorarioSede({
    required this.diaSemana,
    required this.horaApertura,
    required this.horaCierre,
  });

  factory HorarioSede.fromJson(Map<String, dynamic> json) => HorarioSede(
    diaSemana: json['dia_semana'],
    horaApertura: json['hora_apertura'],
    horaCierre: json['hora_cierre'],
  );
}

class Sede {
  final int id;
  final String nombre;
  final String direccion;
  final String? imagenUrl;

  /// Tipos de espacios deportivos de la sede (Fútbol, Tenis, etc.)
  final List<String> deportes;
  final List<HorarioSede> horarios;

  const Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.imagenUrl,
    required this.deportes,
    required this.horarios,
  });

  factory Sede.fromJson(Map<String, dynamic> json) => Sede(
    id: json['id'],
    nombre: json['nombre'],
    direccion: json['direccion'],
    imagenUrl: json['imagen_url'],
    deportes: List<String>.from(json['deportes']),
    horarios: (json['horarios'] as List)
        .map((h) => HorarioSede.fromJson(h))
        .toList(),
  );

  /// Horarios de un día de la semana (1 = lunes, 7 = domingo).
  List<HorarioSede> horariosDel(int diaSemana) =>
      horarios.where((h) => h.diaSemana == diaSemana).toList();

  bool estaAbierta(DateTime momento) => horariosDel(
    momento.weekday,
  ).any((h) => momento.hour >= h.horaApertura && momento.hour < h.horaCierre);
}
