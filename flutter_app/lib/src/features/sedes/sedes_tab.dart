import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/features/sedes/widgets/sedes_header.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Pestaña de sedes: lista de sedes filtrable por deporte. Al tocar una se
/// abre su detalle en otra pantalla.
class SedesTab extends StatefulWidget {
  const SedesTab({super.key});

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
      if (mounted) setState(() => _sedes = sedes); //uso mounted xq si se destruye la vista - ej usuario salio de la vista no actualizo el estado
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

  void _abrirSede(Sede sede) {
    Navigator.of(context).pushNamed(AppRoutes.sedeDetalle, arguments: sede);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.olive,
      onRefresh: _cargar,
      child: ListView(
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
                  onTap: () => _abrirSede(sede), //si selecciono una sede, abre el detalle
                ),
              ),
          ],
        ],
      ),
    );
  }
}
