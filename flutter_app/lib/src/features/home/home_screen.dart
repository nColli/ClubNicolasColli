import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/features/home/widgets/home_bottom_nav.dart';
import 'package:flutter_app/src/features/home/widgets/inicio_tab.dart';
import 'package:flutter_app/src/features/perfil/perfil.dart';
import 'package:flutter_app/src/features/reservas/reservas.dart';
import 'package:flutter_app/src/features/sedes/sedes.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';

/// Pantalla principal con la barra de pestañas.
///
/// Solo se muestra la pestaña actual: al cambiar de pestaña la anterior se
/// descarta y la nueva se crea de cero, así cada una pide sus datos a la API
/// cada vez que se entra (siempre muestra la información actualizada).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<StreamSubscription<RemoteMessage>> _suscripciones = [];

  HomeTab _tabActual = HomeTab.inicio;

  @override
  void initState() {
    super.initState();
    _escucharNotificaciones();
  }

  @override
  void dispose() {
    for (final suscripcion in _suscripciones) {
      suscripcion.cancel();
    }
    super.dispose();
  }

  /// El home es la primera pantalla con sesión iniciada: acá se registra el
  /// celular para recibir push y se atienden los avisos según el estado de
  /// la app.
  Future<void> _escucharNotificaciones() async {
    final notificaciones = NotificacionesService();
    // Antes de pedir el permiso, así el canal de los avisos ya existe cuando
    // llega el primer push
    await notificaciones.inicializar(onTocar: _abrirReserva);
    notificaciones.activar();
    _suscripciones.addAll([
      // App en segundo plano: Android muestra el aviso y el usuario lo tocó
      FirebaseMessaging.onMessageOpenedApp.listen(_abrirReservaDelAviso),
      // App abierta: Android no muestra el aviso, lo muestra la app
      FirebaseMessaging.onMessage.listen(notificaciones.mostrar),
    ]);
    // App cerrada: se abrió tocando un aviso
    try {
      final mensaje = await FirebaseMessaging.instance.getInitialMessage();
      if (mensaje != null) _abrirReservaDelAviso(mensaje);
    } catch (_) {
      // Sin Firebase Messaging disponible la app sigue sin notificaciones
    }
  }

  void _abrirReservaDelAviso(RemoteMessage mensaje) =>
      _abrirReserva(NotificacionesService.reservaId(mensaje));

  void _abrirReserva(int? reservaId) {
    if (reservaId == null || !mounted) return;
    Navigator.of(context).pushNamed(
      AppRoutes.reservaDetalle,
      arguments: ReservaDetalleArgs(reservaId: reservaId),
    );
  }

  void _irATab(HomeTab tab) => setState(() => _tabActual = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      extendBody: true,
      body: switch (_tabActual) {
        HomeTab.inicio => InicioTab(onIrATab: _irATab),
        HomeTab.sedes => const SedesTab(),
        HomeTab.reservas => ReservasTab(
          onReservar: () => _irATab(HomeTab.sedes),
        ),
        HomeTab.perfil => const PerfilTab(),
      },
      bottomNavigationBar: HomeBottomNav(tabActual: _tabActual, onTap: _irATab),
    );
  }
}
