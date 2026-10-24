import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/models/models.dart';

void main() {
  test('Notificacion.fromJson', () {
    final n = Notificacion.fromJson({
      'reserva_id': 7,
      'titulo': 'Tu reserva es mañana',
      'cuerpo': 'Fútbol 1 · Sede Ramos Mejía\nlun, 12 oct · 10:00 – 12:00 hs',
    });
    expect(n.reservaId, 7);
    expect(n.titulo, 'Tu reserva es mañana');
  });
}
