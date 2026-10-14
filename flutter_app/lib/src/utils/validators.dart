import 'package:flutter_app/src/constants/constants.dart';

/// Validadores para los `TextFormField` de los formularios.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requerido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.campoObligatorio;
    }
    return null;
  }

  static String? dni(String? value) {
    if (value == null || value.isEmpty) return AppStrings.campoObligatorio;
    if (value.length < 7 || value.length > 8) return 'DNI inválido';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.campoObligatorio;
    }
    if (!_emailRegex.hasMatch(value.trim())) return 'Email inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.campoObligatorio;
    if (value.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }
}
