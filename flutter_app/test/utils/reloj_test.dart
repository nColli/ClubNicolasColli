import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/utils/utils.dart';

void main() {
  test('Reloj.ahora devuelve la hora de Argentina (UTC-3)', () {
    expect(
      Reloj.ahora(DateTime.utc(2026, 10, 11, 21, 39)),
      DateTime(2026, 10, 11, 18, 39),
    );
    // Pasada la medianoche UTC, en Argentina todavía es el día anterior
    expect(
      Reloj.ahora(DateTime.utc(2026, 10, 12, 1, 0)),
      DateTime(2026, 10, 11, 22, 0),
    );
  });

  test('una reserva que empieza en 20 minutos se puede cancelar aunque '
      'el dispositivo esté en GMT', () {
    final reserva = Reserva(
      id: 1,
      fecha: DateTime(2026, 10, 11),
      horaInicio: 19,
      horaFin: 20,
      precioTotal: 3200,
      espacioId: 4,
      espacioNombre: 'RamosMejia_Belgrano_1240_Futbol_1',
      espacioTipo: 'Fútbol',
      espacioNumero: 1,
      sedeId: 2,
      sedeNombre: 'Ramos Mejía',
      sedeDireccion: 'Calle Belgrano 1240',
      sedeImagenUrl: null,
    );
    // 21:40 GMT = 18:40 en Argentina
    final ahora = Reloj.ahora(DateTime.utc(2026, 10, 11, 21, 40));
    expect(reserva.cancelable(ahora), isTrue);
    expect(EstadoReserva.de(reserva, ahora), EstadoReserva.activa);
  });
}
