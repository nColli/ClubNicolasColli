import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/utils/utils.dart';

void main() {
  group('Validators', () {
    test('requerido rechaza vacíos y espacios', () {
      expect(Validators.requerido(null), AppStrings.campoObligatorio);
      expect(Validators.requerido('   '), AppStrings.campoObligatorio);
      expect(Validators.requerido('Juan'), isNull);
    });

    test('dni acepta 7 u 8 dígitos', () {
      expect(Validators.dni('123456'), 'DNI inválido');
      expect(Validators.dni('1234567'), isNull);
      expect(Validators.dni('12345678'), isNull);
    });

    test('email valida el formato', () {
      expect(Validators.email('juan@'), 'Email inválido');
      expect(Validators.email(' juan@email.com '), isNull);
    });

    test('password exige 8 caracteres', () {
      expect(Validators.password('1234567'), 'Mínimo 8 caracteres');
      expect(Validators.password('12345678'), isNull);
    });
  });
}
