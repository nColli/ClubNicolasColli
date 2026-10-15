import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/features/home/widgets/home_hero.dart';
import 'package:flutter_app/src/features/home/widgets/lista_sedes.dart';
import 'package:flutter_app/src/features/home/widgets/proxima_reserva_card.dart';
import 'package:flutter_app/src/features/home/widgets/seccion_header.dart';
import 'package:flutter_app/src/features/notificaciones/notificaciones.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

class InicioTab extends StatefulWidget {
  /// Cuando cambia, el inicio vuelve a cargar la próxima reserva
  final int versionReservas;

  /// Cuando cambia, el inicio vuelve a cargar el perfil (nombre del saludo)
  final int versionPerfil;

  /// Cuando cambia, se vuelve a revisar si hay notificaciones nuevas
  final int versionNotificaciones;
  final ValueChanged<HomeTab> onIrATab;
  final ValueChanged<Sede> onAbrirSede;

  /// Abre el detalle de una reserva (la próxima reserva o una notificación)
  final void Function(int reservaId, [Reserva? reserva]) onAbrirReserva;

  const InicioTab({
    super.key,
    required this.versionReservas,
    required this.versionPerfil,
    required this.versionNotificaciones,
    required this.onIrATab,
    required this.onAbrirSede,
    required this.onAbrirReserva,
  });

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

  @override
  void didUpdateWidget(InicioTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // _cargar ya incluye el perfil y las notificaciones
    if (oldWidget.versionReservas != widget.versionReservas) {
      _cargar();
      return;
    }
    if (oldWidget.versionPerfil != widget.versionPerfil) _cargarPerfil();
    if (oldWidget.versionNotificaciones != widget.versionNotificaciones) {
      _cargarNotificaciones();
    }
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
          () => _hayNotificacionesNuevas = notificaciones.any((n) => !n.leida),
        );
      }
    } catch (_) {
      // Sin notificaciones la campana queda sin punto
    }
  }

  Future<void> _abrirNotificaciones() async {
    // El panel las marca como leídas al abrirse
    setState(() => _hayNotificacionesNuevas = false);
    await mostrarNotificaciones(context, onAbrirReserva: widget.onAbrirReserva);
    if (mounted) _cargarNotificaciones();
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
                onTap: (r) => widget.onAbrirReserva(r.id, r),
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
              onAbrirSede: widget.onAbrirSede,
            ),
          ],
        ],
      ),
    );
  }
}
