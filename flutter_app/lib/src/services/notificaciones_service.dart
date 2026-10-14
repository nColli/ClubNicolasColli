import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_app/src/services/api_exception.dart';
import 'package:flutter_app/src/services/api_service.dart';

/// Aviso de reserva recibido mientras la app está abierta.
class AvisoReserva {
  final int reservaId;
  final String titulo;
  final String cuerpo;

  const AvisoReserva({
    required this.reservaId,
    required this.titulo,
    required this.cuerpo,
  });
}

/// Notificaciones push de reservas próximas (Firebase Cloud Messaging).
///
/// La API envía los avisos 24 h y 1 h antes de cada reserva al token que
/// registra [activar]. Con la app cerrada o en segundo plano, Android muestra
/// la notificación solo; con la app abierta llega por [avisosEnPrimerPlano].
class NotificacionesService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _api = ApiService();

  /// Pide permiso y registra el dispositivo en la API.
  ///
  /// Si falla Firebase Messaging la app sigue sin notificaciones; si falla el
  /// registro en el servidor lanza [ApiException] para poder avisarle al
  /// usuario.
  Future<void> activar() async {
    final String? token;
    try {
      final permiso = await _messaging.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) return;

      token = await _messaging.getToken();
    } catch (e) {
      // Sin Google Play Services, sin conexión con FCM, etc.
      debugPrint('No se pudo obtener el token de FCM: $e');
      return;
    }
    if (token != null) await _api.registrarDispositivo(token);
  }

  /// Vuelve a registrar el dispositivo cuando FCM renueva el token.
  StreamSubscription<String> escucharRenovacionDeToken() => _messaging
      .onTokenRefresh
      .listen((token) => _api.registrarDispositivo(token).catchError((_) {}));

  /// Deja de recibir avisos en este dispositivo. Se llama antes de cerrar
  /// sesión, mientras todavía hay un usuario autenticado.
  Future<void> desactivar() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _api.quitarDispositivo(token);
      await _messaging.deleteToken();
    } catch (_) {
      // Si falla, la API borra el token cuando FCM lo informe como inválido
    }
  }

  /// Reserva de la notificación que abrió la app estando cerrada, si hubo.
  Future<int?> reservaQueAbrioLaApp() async {
    try {
      final mensaje = await _messaging.getInitialMessage();
      return mensaje == null ? null : _reservaId(mensaje);
    } catch (_) {
      // Sin Firebase Messaging disponible la app sigue sin notificaciones
      return null;
    }
  }

  /// Reservas de las notificaciones que el usuario toca con la app en
  /// segundo plano.
  Stream<int> get reservasAbiertas => FirebaseMessaging.onMessageOpenedApp
      .map(_reservaId)
      .where((id) => id != null)
      .cast<int>();

  /// Avisos que llegan con la app abierta (Android no los muestra solo).
  Stream<AvisoReserva> get avisosEnPrimerPlano => FirebaseMessaging.onMessage
      .where((m) => _reservaId(m) != null)
      .map(
        (m) => AvisoReserva(
          reservaId: _reservaId(m)!,
          titulo: m.notification?.title ?? 'Recordatorio de reserva',
          cuerpo: m.notification?.body ?? '',
        ),
      );

  static int? _reservaId(RemoteMessage mensaje) =>
      int.tryParse(mensaje.data['reserva_id']?.toString() ?? '');
}
