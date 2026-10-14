import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/utils/utils.dart';

void main() {
  group('Formatters', () {
    test('fechaNumerica usa dd/MM/yyyy', () {
      expect(Formatters.fechaNumerica(DateTime(2026, 8, 5)), '05/08/2026');
    });

    test('fechaLarga', () {
      expect(
        Formatters.fechaLarga(DateTime(2026, 8, 12)),
        'Miércoles 12 de agosto',
      );
    });

    test('fechaCorta', () {
      expect(Formatters.fechaCorta(DateTime(2026, 8, 15)), 'sáb, 15 ago');
    });

    test('hora y precio', () {
      expect(Formatters.hora(9), '09:00');
      expect(Formatters.precio(2500), '\$ 2.500');
      expect(Formatters.precio(1234567.4), '\$ 1.234.567');
    });

    test('resumenHorarios agrupa días consecutivos con el mismo horario', () {
      final horarios = [
        for (var dia = 1; dia <= 7; dia++)
          HorarioSede(
            diaSemana: dia,
            horaApertura: dia <= 5 ? 8 : 9,
            horaCierre: dia <= 5 ? 23 : 20,
          ),
      ];
      expect(Formatters.resumenHorarios(horarios), [
        'Lun a Vie · 08:00 – 23:00',
        'Sáb y Dom · 09:00 – 20:00',
      ]);
    });

    test('resumenHorarios omite los días que no abre', () {
      const horarios = [
        HorarioSede(diaSemana: 1, horaApertura: 8, horaCierre: 12),
        HorarioSede(diaSemana: 3, horaApertura: 8, horaCierre: 12),
      ];
      expect(Formatters.resumenHorarios(horarios), [
        'Lun · 08:00 – 12:00',
        'Mié · 08:00 – 12:00',
      ]);
      expect(Formatters.resumenHorarios([]), isEmpty);
    });

    test('saludo según la hora', () {
      expect(Formatters.saludo(DateTime(2026, 1, 1, 8)), 'Buenos días');
      expect(Formatters.saludo(DateTime(2026, 1, 1, 15)), 'Buenas tardes');
      expect(Formatters.saludo(DateTime(2026, 1, 1, 23)), 'Buenas noches');
    });
  });

  test('DateTime.toIsoDate', () {
    expect(DateTime(2026, 8, 5).toIsoDate(), '2026-08-05');
  });
}
