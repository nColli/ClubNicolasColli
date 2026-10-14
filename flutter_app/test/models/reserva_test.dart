import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/models/models.dart';

Reserva _reserva({required int desde, required int hasta}) => Reserva(
  id: 1,
  fecha: DateTime(2026, 10, 15),
  horaInicio: desde,
  horaFin: hasta,
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

void main() {
  final reserva = _reserva(desde: 18, hasta: 20);

  test('estado según el momento', () {
    expect(
      EstadoReserva.de(reserva, DateTime(2026, 10, 15, 17, 59)),
      EstadoReserva.activa,
    );
    expect(
      EstadoReserva.de(reserva, DateTime(2026, 10, 15, 18)),
      EstadoReserva.enCurso,
    );
    expect(
      EstadoReserva.de(reserva, DateTime(2026, 10, 15, 20)),
      EstadoReserva.completada,
    );
  });

  test('solo se puede cancelar antes de que empiece', () {
    expect(reserva.cancelable(DateTime(2026, 10, 15, 17, 59)), isTrue);
    expect(reserva.cancelable(DateTime(2026, 10, 15, 18)), isFalse);
  });

  test('una reserva que termina a las 24 termina a medianoche', () {
    final tarde = _reserva(desde: 22, hasta: 24);
    expect(tarde.terminada(DateTime(2026, 10, 15, 23, 59)), isFalse);
    expect(tarde.terminada(DateTime(2026, 10, 16)), isTrue);
  });
}
