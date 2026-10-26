import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/features/home/widgets/home_hero.dart';
import 'package:flutter_app/src/features/home/widgets/lista_sedes.dart';
import 'package:flutter_app/src/features/home/widgets/proxima_reserva_card.dart';
import 'package:flutter_app/src/features/home/widgets/seccion_header.dart';
import 'package:flutter_app/src/features/notificaciones/notificaciones.dart';
import 'package:flutter_app/src/features/reservas/reservas.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Pestaña de inicio: saludo, campana, próxima reserva y sedes. Carga todo
/// cada vez que se entra a la pestaña.
class InicioTab extends StatefulWidget {
  final ValueChanged<HomeTab> onIrATab;

  const InicioTab({super.key, required this.onIrATab});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  final ApiService _api = ApiService();

  bool _cargando = true;
  String? _error;
  Usuario? _perfil;
  Reserva? _proximaReserva;
  List<Sede> _sedes = [];
  bool _hayNotificacionesNuevas = false;

  /// null = "Todos"
  String? _deporteSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    // El perfil se carga aparte: si fallan las reservas o las sedes,
    // el saludo igual muestra el nombre del usuario.
    final perfil = _cargarPerfil();
    final notificaciones = _cargarNotificaciones();
    try {
      final resultados = await Future.wait([
        _api.obtenerReservasProximas(limite: 1),
        _api.obtenerSedes(),
      ]);
      if (!mounted) return;
      final reservas = resultados[0] as List<Reserva>;
      setState(() {
        _proximaReserva = reservas.isEmpty ? null : reservas.first;
        _sedes = resultados[1] as List<Sede>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
    await Future.wait([perfil, notificaciones]);
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await _api.obtenerPerfil();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Sin perfil el hero muestra solo el saludo; el resto del home sigue funcionando
    }
  }

  Future<void> _cargarNotificaciones() async {
    try {
      final notificaciones = await _api.obtenerNotificaciones();
      if (mounted) {
        setState(
          () => _hayNotificacionesNuevas = notificaciones.isNotEmpty, //el punto verde siempre se pone si hay notif de reservas, al hacer click se apaga
        );
      }
    } catch (_) {
      // Sin notificaciones la campana queda sin punto
    }
  }

  void _abrirNotificaciones() {
    // El punto se apaga al abrir el panel; vuelve si hay recordatorios al recargar
    setState(() => _hayNotificacionesNuevas = false);
    mostrarNotificaciones(context, onAbrirReserva: _abrirReserva); //el metodo _abrirReserva es comun para cuando veo la reserva en la notif o cuando toco en la prox reserva
  }

  void _abrirSede(Sede sede) {
    Navigator.of(context).pushNamed(AppRoutes.sedeDetalle, arguments: sede);
  }

  /// Abre el detalle de una reserva; si se canceló, recarga el inicio.
  Future<void> _abrirReserva(int reservaId, [Reserva? reserva]) async {
    final cancelada = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.reservaDetalle,
      arguments: ReservaDetalleArgs(reservaId: reservaId, reserva: reserva),
    );
    if (cancelada == true && mounted) _cargar();
  }

  List<String> get _deportes =>
      _sedes.expand((s) => s.deportes).toSet().toList()..sort();

  List<Sede> get _sedesFiltradas => _deporteSeleccionado == null
      ? _sedes
      : _sedes.where((s) => s.deportes.contains(_deporteSeleccionado)).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.olive,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          HomeHero(
            perfil: _perfil,
            onAvatarTap: () => widget.onIrATab(HomeTab.perfil),
            hayNotificacionesNuevas: _hayNotificacionesNuevas,
            onNotificacionesTap: _abrirNotificaciones,
          ),
          const SizedBox(height: 16),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.olive),
              ),
            )
          else if (_error != null)
            ErrorView(mensaje: _error!, onReintentar: _cargar)
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProximaReservaCard(
                reserva: _proximaReserva,
                onVerReservas: () => widget.onIrATab(HomeTab.reservas),
                onTap: (r) => _abrirReserva(r.id, r),
                onReservar: () => widget.onIrATab(HomeTab.sedes),
              ),
            ),
            const SizedBox(height: 20),
            FiltroDeportes(
              deportes: _deportes,
              seleccionado: _deporteSeleccionado,
              onSeleccionar: (d) => setState(() => _deporteSeleccionado = d),
            ),
            const SizedBox(height: 24),
            SeccionHeader(
              titulo: 'SEDES DISPONIBLES',
              onVerTodas: () => widget.onIrATab(HomeTab.sedes),
            ),
            const SizedBox(height: 12),
            ListaSedes(
              sedes: _sedesFiltradas,
              deporteSeleccionado: _deporteSeleccionado,
              onAbrirSede: _abrirSede,
            ),
          ],
        ],
      ),
    );
  }
}
