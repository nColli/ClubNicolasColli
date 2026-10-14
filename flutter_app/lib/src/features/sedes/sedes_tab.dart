import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/features/sedes/widgets/sede_detalle.dart';
import 'package:flutter_app/src/features/sedes/widgets/sedes_header.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Pestaña de sedes: muestra la lista de sedes o, si hay una abierta, su
/// detalle. La sede abierta la controla el home, para poder abrirla también
/// desde la pestaña de inicio.
class SedesTab extends StatefulWidget {
  final Sede? sedeAbierta;
  final ValueChanged<Sede> onAbrirSede;
  final VoidCallback onCerrarSede;
  final VoidCallback onReservaCreada;

  const SedesTab({
    super.key,
    required this.sedeAbierta,
    required this.onAbrirSede,
    required this.onCerrarSede,
    required this.onReservaCreada,
  });

  @override
  State<SedesTab> createState() => _SedesTabState();
}

class _SedesTabState extends State<SedesTab> {
  final ApiService _api = ApiService();

  bool _cargando = true;
  String? _error;
  List<Sede> _sedes = [];

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
      final sedes = await _api.obtenerSedes();
      if (mounted) setState(() => _sedes = sedes);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<String> get _deportes =>
      _sedes.expand((s) => s.deportes).toSet().toList()..sort();

  List<Sede> get _sedesFiltradas => _deporteSeleccionado == null
      ? _sedes
      : _sedes.where((s) => s.deportes.contains(_deporteSeleccionado)).toList();

  @override
  Widget build(BuildContext context) {
    final sede = widget.sedeAbierta;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: sede == null
          ? _lista()
          : SedeDetalle(
              key: ValueKey(sede.id),
              sede: sede,
              onVolver: widget.onCerrarSede,
              onReservaCreada: widget.onReservaCreada,
            ),
    );
  }

  Widget _lista() {
    return RefreshIndicator(
      key: const ValueKey('lista'),
      color: AppColors.olive,
      onRefresh: _cargar,
      child: ListView(
        // Conserva el scroll al volver del detalle de una sede
        key: const PageStorageKey('lista_sedes'),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          const SedesHeader(),
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
            FiltroDeportes(
              deportes: _deportes,
              seleccionado: _deporteSeleccionado,
              onSeleccionar: (d) => setState(() => _deporteSeleccionado = d),
            ),
            const SizedBox(height: 20),
            if (_sedesFiltradas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Text(
                  _deporteSeleccionado == null
                      ? 'No hay sedes disponibles.'
                      : 'No hay sedes con $_deporteSeleccionado.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.lightTextSecondary),
                ),
              ),
            for (final sede in _sedesFiltradas)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SedeCard(
                  sede: sede,
                  expandida: true,
                  onTap: () => widget.onAbrirSede(sede),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
