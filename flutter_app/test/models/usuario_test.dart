import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/models/models.dart';

void main() {
  final json = {
    'uid': 'abc',
    'email': 'juana@example.com',
    'nombre': 'Juana',
    'apellido': 'González',
    'dni': '40123456',
    'fecha_nacimiento': '2000-05-21',
  };

  test('Usuario.fromJson lee el DNI', () {
    final usuario = Usuario.fromJson(json);
    expect(usuario.dni, '40123456');
    expect(usuario.iniciales, 'JG');
  });
}
