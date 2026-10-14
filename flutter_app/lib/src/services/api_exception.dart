/// Error devuelto al llamar a la API, con un mensaje listo para mostrar.
class ApiException implements Exception {
  final String mensaje;
  final int? statusCode;

  const ApiException(this.mensaje, {this.statusCode});

  @override
  String toString() => mensaje;
}
