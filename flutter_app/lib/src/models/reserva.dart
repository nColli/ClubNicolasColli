class Reserva {
  final int id;
  final DateTime fecha;
  final int horaInicio;
  final int horaFin;
  final double precioTotal;
  final int espacioId;
  final String espacioNombre;
  final String espacioTipo;
  final int espacioNumero;
  final int sedeId;
  final String sedeNombre;
  final String sedeDireccion;
  final String? sedeImagenUrl;

  const Reserva({
    required this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.precioTotal,
    required this.espacioId,
    required this.espacioNombre,
    required this.espacioTipo,
    required this.espacioNumero,
    required this.sedeId,
    required this.sedeNombre,
    required this.sedeDireccion,
    required this.sedeImagenUrl,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'],
    fecha: DateTime.parse(json['fecha']),
    horaInicio: json['hora_inicio'],
    horaFin: json['hora_fin'],
    // La API devuelve el precio como string decimal ("2500.00")
    precioTotal: double.parse(json['precio_total'].toString()),
    espacioId: json['espacio_id'],
    espacioNombre: json['espacio_nombre'],
    espacioTipo: json['espacio_tipo'],
    espacioNumero: json['espacio_numero'],
    sedeId: json['sede_id'],
    sedeNombre: json['sede_nombre'],
    sedeDireccion: json['sede_direccion'],
    sedeImagenUrl: json['sede_imagen_url'],
  );

  /// "Fútbol 1"
  String get espacioTitulo => '$espacioTipo $espacioNumero';

  DateTime get inicio =>
      DateTime(fecha.year, fecha.month, fecha.day, horaInicio);

  // hora_fin puede ser 24: DateTime pasa al día siguiente a las 00:00
  DateTime get fin => DateTime(fecha.year, fecha.month, fecha.day, horaFin);

  /// La reserva ya terminó: va al historial.
  bool terminada(DateTime ahora) => !fin.isAfter(ahora);

  /// Solo se pueden cancelar las reservas que todavía no empezaron.
  bool cancelable(DateTime ahora) => inicio.isAfter(ahora);
}
