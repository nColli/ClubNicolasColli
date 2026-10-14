/// Notificación de la campana del inicio (reserva confirmada, cancelada o
/// recordatorio).
class Notificacion {
  final int id;

  /// null si la reserva se canceló
  final int? reservaId;
  final String titulo;
  final String cuerpo;
  final DateTime creada;
  final bool leida;

  const Notificacion({
    required this.id,
    required this.reservaId,
    required this.titulo,
    required this.cuerpo,
    required this.creada,
    required this.leida,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
    id: json['id'],
    reservaId: json['reserva_id'],
    titulo: json['titulo'],
    cuerpo: json['cuerpo'],
    // La API la devuelve en UTC ("2026-10-11T22:07:09Z")
    creada: DateTime.parse(json['creada']),
    leida: json['leida'],
  );
}
