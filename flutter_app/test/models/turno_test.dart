import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/models/models.dart';

void main() {
  // Sede abierta de 8 a 12, con las 10 ocupadas
  const horas = [
    HoraDisponibilidad(hora: 8, disponible: true),
    HoraDisponibilidad(hora: 9, disponible: true),
    HoraDisponibilidad(hora: 10, disponible: false),
    HoraDisponibilidad(hora: 11, disponible: true),
  ];

  String describir(Turno t) =>
      '${t.horaInicio}-${t.horaFin}${t.disponible ? '' : ' x'}';

  test('turnos de una hora', () {
    expect(Turno.armar(horas, 1).map(describir), [
      '8-9',
      '9-10',
      '10-11 x',
      '11-12',
    ]);
  });

  test(
    'turnos de dos horas no pasan el cierre y se bloquean si una hora está ocupada',
    () {
      expect(Turno.armar(horas, 2).map(describir), [
        '8-10',
        '9-11 x',
        '10-12 x',
      ]);
    },
  );

  test('no arma turnos que crucen un hueco entre franjas', () {
    const partido = [
      HoraDisponibilidad(hora: 8, disponible: true),
      HoraDisponibilidad(hora: 14, disponible: true),
    ];
    expect(Turno.armar(partido, 2), isEmpty);
    expect(Turno.armar([], 1), isEmpty);
  });
}
