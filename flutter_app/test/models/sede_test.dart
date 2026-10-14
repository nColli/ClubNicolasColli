import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/models/models.dart';

void main() {
  const sede = Sede(
    id: 1,
    nombre: 'Morón',
    direccion: 'Av. Rivadavia 17500',
    imagenUrl: null,
    deportes: ['Fútbol'],
    horarios: [HorarioSede(diaSemana: 1, horaApertura: 8, horaCierre: 23)],
  );

  test('estaAbierta según el día y la hora', () {
    // 2026-10-12 es lunes
    expect(sede.estaAbierta(DateTime(2026, 10, 12, 8)), isTrue);
    expect(sede.estaAbierta(DateTime(2026, 10, 12, 22, 59)), isTrue);
    expect(sede.estaAbierta(DateTime(2026, 10, 12, 23)), isFalse);
    expect(sede.estaAbierta(DateTime(2026, 10, 12, 7)), isFalse);
    expect(sede.estaAbierta(DateTime(2026, 10, 13, 10)), isFalse);
  });

  test('Espacio.fromJson parsea el precio decimal', () {
    final espacio = Espacio.fromJson({
      'id': 4,
      'tipo': 'Fútbol',
      'numero': 1,
      'nombre': 'RamosMejia_Belgrano_1240_Futbol_1',
      'precio_hora': '3200.00',
    });
    expect(espacio.precioHora, 3200);
    expect(espacio.titulo, 'Fútbol 1');
  });
}
