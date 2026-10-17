import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_app/src/services/api_service.dart';

/// Notificaciones push de reservas próximas (Firebase Cloud Messaging).
///
/// Para que el backend pueda mandarle un push a este celular necesita su
/// "token" de FCM: [activar] lo pide y lo guarda en la API. El backend envía
/// los avisos 24 h y 1 h antes de cada reserva a todos los tokens del usuario.
///
/// Cómo se reciben los avisos según el estado de la app lo resuelve el home
/// (ver `HomeScreen._escucharNotificaciones`).
class NotificacionesService {
  /// Canal de Android de los avisos. Con importancia alta Android los muestra
  /// como banner arriba de la pantalla; el canal que usa FCM si no hay otro
  /// ("Miscellaneous") solo deja el ícono en la barra de estado.
  /// El AndroidManifest lo declara como canal por defecto de FCM, así los
  /// push que muestra Android con la app en segundo plano también lo usan.
  static const _canal = AndroidNotificationChannel(
    'recordatorios_reservas',
    'Recordatorios de reservas',
    description: 'Avisos 24 h y 1 h antes de cada reserva',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _locales =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  /// Crea el canal de los avisos y prepara las notificaciones que se muestran
  /// con la app abierta ([mostrar]). Al tocar una se llama a [onTocar] con la
  /// reserva del aviso.
  Future<void> inicializar({
    required void Function(int reservaId) onTocar,
  }) async {
    try {
      await _locales.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (respuesta) {
          final reservaId = int.tryParse(respuesta.payload ?? '');
          if (reservaId != null) onTocar(reservaId);
        },
      );
      await _locales
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_canal);
    } catch (e) {
      debugPrint('No se pudieron preparar las notificaciones: $e');
    }
  }

  /// Pide permiso y registra el token del celular en la API.
  ///
  /// Se llama en cada inicio y no pasa nada por repetirlo: Android muestra el
  /// diálogo de permiso solo la primera vez (después devuelve lo que eligió
  /// el usuario), el token es siempre el mismo y la API no lo duplica.
  /// Si algo falla la app sigue funcionando, solo que sin push.
  Future<void> activar() async {
    try {
      final permiso = await _messaging.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      if (token != null) await _api.registrarDispositivo(token);
    } catch (e) {
      debugPrint('No se pudieron activar las notificaciones: $e');
    }
  }

  /// Muestra un push que llegó con la app abierta: en ese caso Android no lo
  /// muestra solo (con la app en segundo plano o cerrada, sí).
  Future<void> mostrar(RemoteMessage mensaje) async {
    final notificacion = mensaje.notification;
    if (notificacion == null) return;
    final reservaId = NotificacionesService.reservaId(mensaje);
    try {
      await _locales.show(
        // Un aviso nuevo de la misma reserva reemplaza al anterior
        id: reservaId ?? 0,
        title: notificacion.title,
        body: notificacion.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _canal.id,
            _canal.name,
            channelDescription: _canal.description,
            importance: Importance.high,
            priority: Priority.high,
            // El cuerpo tiene dos líneas (espacio y sede, fecha y horario)
            styleInformation: BigTextStyleInformation(notificacion.body ?? ''),
          ),
        ),
        payload: reservaId?.toString(),
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación: $e');
    }
  }

  /// Deja de recibir avisos en este celular (al cerrar sesión). Borra el
  /// token: los envíos a ese token fallan y la API lo elimina de la base.
  Future<void> desactivar() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('No se pudo borrar el token de FCM: $e');
    }
  }

  /// Reserva a la que se refiere un push (la API la manda en "reserva_id").
  static int? reservaId(RemoteMessage mensaje) =>
      int.tryParse(mensaje.data['reserva_id']?.toString() ?? '');
}
