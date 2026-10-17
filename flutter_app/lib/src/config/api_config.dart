/// URL base de la API REST.
///
/// Por defecto apunta al backend local visto desde el emulador de Android
/// (10.0.2.2 = localhost de la PC). Para usar otra URL:
///   flutter run --dart-define=API_URL=https://mi-api.onrender.com
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://clubnicolascolli.onrender.com',
  );

  static const Duration timeout = Duration(seconds: 20);
}
