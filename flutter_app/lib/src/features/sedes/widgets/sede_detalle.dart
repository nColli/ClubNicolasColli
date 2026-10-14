import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/features/sedes/widgets/espacio_card.dart';
import 'package:flutter_app/src/features/reservas/reservas.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Detalle de una sede con sus espacios deportivos, filtrables por deporte.
class SedeDetalle extends StatefulWidget {
  final Sede sede;
  final VoidCallback onVolver;
  final VoidCallback onReservaCreada;

  const SedeDetalle({
    super.key,
    required this.sede,
    required this.onVolver,
    required this.onReservaCreada,
  });

  @override
  State<SedeDetalle> createState() => _SedeDetalleState();
}

class _SedeDetalleState extends State<SedeDetalle> {
  final ApiService _api = ApiService();

  bool _cargando = true;
  String? _error;
  List<Espacio> _espacios = [];

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
    try {
      final espacios = await _api.obtenerEspacios(widget.sede.id);
      if (mounted) setState(() => _espacios = espacios);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<String> get _deportes =>
      _espacios.map((e) => e.tipo).toSet().toList()..sort();

  List<Espacio> get _espaciosFiltrados => _deporteSeleccionado == null
      ? _espacios
      : _espacios.where((e) => e.tipo == _deporteSeleccionado).toList();

  String get _resumen {
    final cantidad = _espaciosFiltrados.length;
    final texto = cantidad == 1 ? '1 espacio' : '$cantidad espacios';
    return _deporteSeleccionado == null
        ? texto
        : '$texto · $_deporteSeleccionado';
  }

  Future<void> _reservar(Espacio espacio) async {
    final reserva = await Navigator.of(context).pushNamed<Reserva>(
      AppRoutes.reservar,
      arguments: ReservarArgs(sede: widget.sede, espacio: espacio),
    );
    // La confirmación ya se mostró en el paso "¡Listo!"; solo se avisa para
    // que el inicio actualice la próxima reserva
    if (reserva != null && mounted) widget.onReservaCreada();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.olive,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.lg),
            ),
            child: SedeHero(
              imagenUrl: widget.sede.imagenUrl,
              volverLabel: 'Todas las sedes',
              onVolver: widget.onVolver,
              eyebrow: 'Sede',
              titulo: 'Sede ${widget.sede.nombre}',
              direccion: widget.sede.direccion,
            ),
          ),
          const SizedBox(height: 20),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.olive),
              ),
            )
          else if (_error != null)
            ErrorView(mensaje: _error!, onReintentar: _cargar)
          else if (_espacios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                'Esta sede todavía no tiene espacios disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightTextSecondary),
              ),
            )
          else ...[
            FiltroDeportes(
              deportes: _deportes,
              seleccionado: _deporteSeleccionado,
              onSeleccionar: (d) => setState(() => _deporteSeleccionado = d),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                _resumen,
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            for (final espacio in _espaciosFiltrados)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: EspacioCard(
                  espacio: espacio,
                  sede: widget.sede,
                  onReservar: () => _reservar(espacio),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
