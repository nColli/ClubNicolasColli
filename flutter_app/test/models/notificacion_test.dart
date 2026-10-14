import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/utils/utils.dart';

void main() {
  test('Notificacion.fromJson con reserva cancelada', () {
    final n = Notificacion.fromJson({
      'id': 1,
      'reserva_id': null,
      'titulo': 'Reserva cancelada',
      'cuerpo': 'Fútbol 1 · Sede Ramos Mejía',
      'creada': '2026-10-11T22:07:09Z',
      'leida': false,
    });
    expect(n.reservaId, isNull);
    expect(n.creada, DateTime.utc(2026, 10, 11, 22, 7, 9));
  });

  test('haceCuanto', () {
    final creada = DateTime.utc(2026, 10, 11, 22);
    String desde(Duration d) => Formatters.haceCuanto(creada, creada.add(d));
    expect(desde(const Duration(seconds: 30)), 'recién');
    expect(desde(const Duration(minutes: 5)), 'hace 5 min');
    expect(desde(const Duration(hours: 2)), 'hace 2 h');
    expect(desde(const Duration(days: 1, hours: 2)), 'ayer');
    expect(desde(const Duration(days: 3)), 'hace 3 días');
    // Más de una semana: la fecha en hora de Argentina (22 UTC = 19 h)
    expect(desde(const Duration(days: 10)), 'dom, 11 oct');
  });
}
