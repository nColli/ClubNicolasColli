/// Hora actual del club (Argentina), sin importar la zona horaria del
/// dispositivo. La API valida reservas y horarios con la hora de Argentina,
/// así que la app tiene que usar la misma: si no, en un dispositivo en otra
/// zona (los emuladores suelen estar en GMT) una reserva futura puede
/// aparecer como terminada.
abstract final class Reloj {
  /// Argentina es UTC-3
  static const Duration _diferenciaConUtc = Duration(hours: -3);

  /// Fecha y hora de Argentina como un [DateTime]
  static DateTime ahora([DateTime? utc]) {
    final t = (utc ?? DateTime.now()).toUtc().add(_diferenciaConUtc);
    return DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
    );
  }
}
