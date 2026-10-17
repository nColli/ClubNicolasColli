import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_app/src/config/config.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/api_exception.dart';

class ApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Registra en el backend el perfil del usuario autenticado en Firebase.
  /// La API toma el uid y el email del token.
  Future<void> registrarUsuario({
    required String nombre,
    required String apellido,
    required String dni,
    required DateTime fechaNacimiento,
  }) async {
    await _post('/usuarios', {
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'fecha_nacimiento': fechaNacimiento.toIsoDate(),
    });
  }

  /// Perfil del usuario autenticado.
  Future<Usuario> obtenerPerfil() async {
    final json = await _get('/usuarios/me');
    return Usuario.fromJson(json);
  }

  /// Actualiza los datos personales del usuario autenticado.
  /// El email no se puede modificar.
  Future<Usuario> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String dni,
    required DateTime fechaNacimiento,
  }) async {
    final json = await _put('/usuarios/me', {
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'fecha_nacimiento': fechaNacimiento.toIsoDate(),
    });
    return Usuario.fromJson(json);
  }

  /// Da de baja la cuenta: la API borra al usuario de la base y de Firebase.
  Future<void> eliminarCuenta() async {
    await _delete('/usuarios/me');
  }

  /// Reservas que todavía no terminaron, de la más cercana a la más lejana.
  /// Devuelve una lista vacía si el usuario no tiene reservas próximas.
  Future<List<Reserva>> obtenerReservasProximas({int? limite}) async {
    final query = limite == null ? '' : '&limit=$limite';
    final json = await _get('/reservas?proximas=true$query') as List;
    return json.map((r) => Reserva.fromJson(r)).toList();
  }

  /// Todas las reservas del usuario, de la más reciente a la más antigua.
  Future<List<Reserva>> obtenerReservas() async {
    final json = await _get('/reservas') as List;
    return json.map((r) => Reserva.fromJson(r)).toList();
  }

  /// Una reserva del usuario (para abrirla desde una notificación).
  Future<Reserva> obtenerReserva(int reservaId) async {
    final json = await _get('/reservas/$reservaId');
    return Reserva.fromJson(json);
  }

  /// Cancela una reserva que todavía no empezó; el horario queda libre.
  Future<void> cancelarReserva(int reservaId) async {
    await _delete('/reservas/$reservaId');
  }

  /// Notificaciones de la campana, de la más nueva a la más vieja.
  Future<List<Notificacion>> obtenerNotificaciones() async {
    final json = await _get('/notificaciones') as List;
    return json.map((n) => Notificacion.fromJson(n)).toList();
  }

  Future<void> marcarNotificacionesLeidas() async {
    await _post('/notificaciones/leidas', {});
  }

  /// Registra el token de FCM del dispositivo para recibir avisos de reservas.
  Future<void> registrarDispositivo(String token) async {
    await _post('/dispositivos', {'token': token});
  }

  /// Sedes con sus horarios y los deportes que ofrecen.
  Future<List<Sede>> obtenerSedes() async {
    final json = await _get('/sedes') as List;
    return json.map((s) => Sede.fromJson(s)).toList();
  }

  /// Espacios deportivos de una sede, ordenados por tipo y número.
  Future<List<Espacio>> obtenerEspacios(int sedeId) async {
    final json = await _get('/sedes/$sedeId/espacios') as List;
    return json.map((e) => Espacio.fromJson(e)).toList();
  }

  /// Horas en que la sede del espacio abre en [fecha] y si se pueden reservar.
  Future<List<HoraDisponibilidad>> obtenerDisponibilidad(
    int espacioId,
    DateTime fecha,
  ) async {
    final json = await _get(
      '/espacios/$espacioId/disponibilidad?fecha=${fecha.toIsoDate()}',
    );
    return (json['horas'] as List)
        .map((h) => HoraDisponibilidad.fromJson(h))
        .toList();
  }

  /// Reserva un espacio para el usuario autenticado.
  Future<Reserva> crearReserva({
    required int espacioId,
    required DateTime fecha,
    required int horaInicio,
    required int horaFin,
  }) async {
    final json = await _post('/reservas', {
      'espacio_id': espacioId,
      'fecha': fecha.toIsoDate(),
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    });
    return Reserva.fromJson(json);
  }

  // ---------- Helpers ----------

  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _get(String path) async {
    return _enviar(
      () async => http.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: await _headers(),
      ),
    );
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    return _enviar(
      () async => http.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    return _enviar(
      () async => http.put(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _delete(String path) async {
    return _enviar(
      () async => http.delete(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: await _headers(),
      ),
    );
  }

  /// Ejecuta la request y traduce los errores de red y HTTP a [ApiException].
  Future<dynamic> _enviar(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(ApiConfig.timeout);
    } on SocketException {
      throw const ApiException(
        'No se pudo conectar con el servidor. Revisá tu conexión a internet.',
      );
    } on TimeoutException {
      throw const ApiException(
        'El servidor no responde. Intentá de nuevo más tarde.',
      );
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(
      _mensajeError(response),
      statusCode: response.statusCode,
    );
  }

  String _mensajeError(http.Response response) {
    if (response.statusCode == 401) {
      return 'Tu sesión expiró. Volvé a iniciar sesión.';
    }
    if (response.statusCode >= 500) {
      return 'Error del servidor. Intentá de nuevo más tarde.';
    }
    // La API devuelve en "detail" un mensaje listo para mostrar
    // (salvo en los errores de validación, donde es una lista)
    try {
      final detail = jsonDecode(utf8.decode(response.bodyBytes))['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    switch (response.statusCode) {
      case 403:
        return 'No tenés permiso para realizar esta acción.';
      case 404:
        return 'No se encontró lo que buscabas.';
      case 409:
        return 'Hay un conflicto con los datos enviados.';
      case 422:
        return 'Algunos datos no son válidos. Revisalos e intentá de nuevo.';
    }
    return 'Error inesperado (${response.statusCode}).';
  }
}
