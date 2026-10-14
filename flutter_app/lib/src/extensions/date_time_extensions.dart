extension DateTimeExtensions on DateTime {
  /// Fecha en formato ISO sin hora ("2026-08-15"), como la espera la API.
  String toIsoDate() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }
}
