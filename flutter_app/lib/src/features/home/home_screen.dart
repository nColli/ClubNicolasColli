import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/features/home/widgets/home_bottom_nav.dart';
import 'package:flutter_app/src/features/home/widgets/inicio_tab.dart';
import 'package:flutter_app/src/features/perfil/perfil.dart';
import 'package:flutter_app/src/features/reservas/reservas.dart';
import 'package:flutter_app/src/features/sedes/sedes.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificacionesService _notificaciones = NotificacionesService();
  final List<StreamSubscription<Object>> _suscripciones = [];

  HomeTab _tabActual = HomeTab.inicio;

  /// Sede cuyo detalle se muestra en la pestaña de sedes (null = lista)
  Sede? _sedeAbierta;

  /// Aumenta cada vez que se crea o cancela una reserva, para que las
  /// pestañas que las muestran las vuelvan a cargar
  int _versionReservas = 0;

  /// Aumenta al editar el perfil, para que el inicio actualice el saludo
  int _versionPerfil = 0;

  /// Aumenta cuando puede haber notificaciones nuevas (llegó un aviso, se
  /// creó o canceló una reserva), para actualizar la campana
  int _versionNotificaciones = 0;

  @override
  void initState() {
    super.initState();
    _activarNotificaciones();
  }

  @override
  void dispose() {
    for (final suscripcion in _suscripciones) {
      suscripcion.cancel();
    }
    super.dispose();
  }

  /// El home es la primera pantalla con sesión iniciada: acá se registra el
  /// dispositivo para recibir avisos y se atienden las notificaciones tocadas.
  Future<void> _activarNotificaciones() async {
    _suscripciones.addAll([
      _notificaciones.escucharRenovacionDeToken(),
      _notificaciones.reservasAbiertas.listen(_abrirReserva),
      _notificaciones.avisosEnPrimerPlano.listen(_mostrarAviso),
    ]);
    // La app estaba cerrada y se abrió tocando una notificación
    final reservaId = await _notificaciones.reservaQueAbrioLaApp();
    if (reservaId != null && mounted) _abrirReserva(reservaId);
    try {
      await _notificaciones.activar();
    } on ApiException catch (e) {
      if (mounted) {
        context.showSnackBar(
          'No se pudieron activar las notificaciones. ${e.mensaje}',
        );
      }
    }
  }

  void _mostrarAviso(AvisoReserva aviso) {
    setState(() => _versionNotificaciones++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          aviso.cuerpo.isEmpty
              ? aviso.titulo
              : '${aviso.titulo}\n${aviso.cuerpo}',
        ),
        action: SnackBarAction(
          label: 'VER',
          textColor: AppColors.neonYellow,
          onPressed: () => _abrirReserva(aviso.reservaId),
        ),
      ),
    );
  }

  /// Abre el detalle de una reserva (desde una notificación o la lista).
  Future<void> _abrirReserva(int reservaId, [Reserva? reserva]) async {
    final cancelada = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.reservaDetalle,
      arguments: ReservaDetalleArgs(reservaId: reservaId, reserva: reserva),
    );
    if (cancelada == true && mounted) _reservasCambiaron();
  }

  /// La pestaña actual muestra una subpantalla (detalle de sede) de la que
  /// el botón atrás tiene que volver
  bool get _enSubpantalla =>
      _tabActual == HomeTab.sedes && _sedeAbierta != null;

  void _irATab(HomeTab tab) => setState(() {
    // Tocar la pestaña en la que ya se está vuelve a su pantalla principal
    if (tab == _tabActual) _cerrarSubpantalla();
    _tabActual = tab;
  });

  void _cerrarSubpantalla() {
    if (_tabActual == HomeTab.sedes) _sedeAbierta = null;
  }

  void _abrirSede(Sede sede) => setState(() {
    _sedeAbierta = sede;
    _tabActual = HomeTab.sedes;
  });

  void _cerrarSede() => setState(() => _sedeAbierta = null);

  void _reservasCambiaron() => setState(() {
    _versionReservas++;
    _versionNotificaciones++;
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // El botón atrás cierra la subpantalla antes de salir de la app
      canPop: !_enSubpantalla,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_cerrarSubpantalla);
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        extendBody: true,
        body: IndexedStack(
          // El orden de los hijos sigue el orden de HomeTab.values
          index: _tabActual.index,
          children: [
            InicioTab(
              versionReservas: _versionReservas,
              versionPerfil: _versionPerfil,
              versionNotificaciones: _versionNotificaciones,
              onIrATab: _irATab,
              onAbrirSede: _abrirSede,
              onAbrirReserva: _abrirReserva,
            ),
            SedesTab(
              sedeAbierta: _sedeAbierta,
              onAbrirSede: _abrirSede,
              onCerrarSede: _cerrarSede,
              onReservaCreada: _reservasCambiaron,
            ),
            ReservasTab(
              versionReservas: _versionReservas,
              onAbrirReserva: (r) => _abrirReserva(r.id, r),
              onReservaCancelada: _reservasCambiaron,
              onReservar: () => _irATab(HomeTab.sedes),
            ),
            PerfilTab(
              onPerfilActualizado: () => setState(() => _versionPerfil++),
            ),
          ],
        ),
        bottomNavigationBar: HomeBottomNav(
          tabActual: _tabActual,
          onTap: _irATab,
        ),
      ),
    );
  }
}
