/// Traduce un código de error de Firebase Auth a un mensaje para el usuario.
///
/// [fallback] arma el mensaje para códigos no contemplados, que varía según
/// la operación (login, registro o recuperación de contraseña).
String authErrorMessage(
  String code, {
  required String Function(String) fallback,
}) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Email o contraseña incorrectos.';
    case 'email-already-in-use':
      return 'El email ya está registrado.';
    case 'invalid-email':
      return 'El formato del email no es válido.';
    case 'weak-password':
      return 'La contraseña es demasiado débil.';
    case 'operation-not-allowed':
      return 'El registro con email no está habilitado.';
    case 'user-disabled':
      return 'La cuenta está deshabilitada.';
    case 'too-many-requests':
      return 'Demasiados intentos. Esperá unos minutos.';
    case 'network-request-failed':
      return 'Sin conexión a internet.';
    default:
      return fallback(code);
  }
}
