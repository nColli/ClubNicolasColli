/// Recordatorio de la campana del inicio: una reserva que todavía no empezó
/// y ya tiene un aviso enviado. La API lo arma en el momento, no se guarda.
class Notificacion {
  final int reservaId;
  final String titulo;
  final String cuerpo;

  const Notificacion({
    required this.reservaId,
    required this.titulo,
    required this.cuerpo,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
    reservaId: json['reserva_id'],
    titulo: json['titulo'],
    cuerpo: json['cuerpo'],
  );
}
