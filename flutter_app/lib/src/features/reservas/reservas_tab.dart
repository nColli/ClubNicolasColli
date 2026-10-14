import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/features/reservas/widgets/cancelar_reserva_view.dart';
import 'package:flutter_app/src/features/reservas/widgets/reserva_card.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

enum _Pestana { proximas, historial }

/// Pestaña "Mis reservas": próximas e historial. Si hay una reserva elegida
/// para cancelar muestra la confirmación; esa reserva la controla el home,
/// igual que la sede abierta en la pestaña de sedes.
class ReservasTab extends StatefulWidget {
  /// Cuando cambia, se vuelven a cargar las reservas
  final int versionReservas;
  final Reserva? reservaACancelar;
  final ValueChanged<Reserva> onCancelar;
  final ValueChanged<Reserva> onAbrirReserva;

  /// `true` si se canceló la reserva (o cambió) y hay que recargar
  final ValueChanged<bool> onCerrarCancelacion;
  final VoidCallback onReservar;

  const ReservasTab({
    super.key,
    required this.versionReservas,
    required this.reservaACancelar,
    required this.onCancelar,
    required this.onAbrirReserva,
    required this.onCerrarCancelacion,
    required this.onReservar,
  });

  @override
  State<ReservasTab> createState() => _ReservasTabState();
}

class _ReservasTabState extends State<ReservasTab> {
  final ApiService _api = ApiService();

  bool _cargando = true;
  String? _error;
  List<Reserva> _reservas = [];
  _Pestana _pestana = _Pestana.proximas;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(ReservasTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.versionReservas != widget.versionReservas) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final reservas = await _api.obtenerReservas();
      if (mounted) setState(() => _reservas = reservas);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reservaACancelar;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: reserva == null
          ? _lista()
          : CancelarReservaView(
              key: ValueKey(reserva.id),
              reserva: reserva,
              onCerrar: widget.onCerrarCancelacion,
            ),
    );
  }

  Widget _lista() {
    final ahora = Reloj.ahora();
    // La API las devuelve de la más reciente a la más antigua; las próximas
    // se muestran de la más cercana a la más lejana
    final historial = _reservas.where((r) => r.terminada(ahora)).toList();
    final proximas = _reservas.where((r) => !r.terminada(ahora)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final visibles = _pestana == _Pestana.proximas ? proximas : historial;

    return RefreshIndicator(
      key: const ValueKey('lista'),
      color: AppColors.olive,
      onRefresh: _cargar,
      child: ListView(
        key: const PageStorageKey('lista_reservas'),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TwoToneTitle(
                    primero: 'MIS ',
                    segundo: 'RESERVAS',
                    colorPrimero: AppColors.lightTextPrimary,
                    colorSegundo: AppColors.olive,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _cargando || _error != null
                        ? ' '
                        : '${proximas.length} '
                              '${proximas.length == 1 ? 'activa' : 'activas'}'
                              ' · ${historial.length} historial',
                    style: const TextStyle(
                      color: AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectorSegmentado<_Pestana>(
                    opciones: _Pestana.values,
                    seleccionada: _pestana,
                    etiqueta: (p) => switch (p) {
                      _Pestana.proximas =>
                        _cargando
                            ? 'Próximas'
                            : 'Próximas (${proximas.length})',
                      _Pestana.historial => 'Historial',
                    },
                    onSeleccionar: (p) => setState(() => _pestana = p),
                  ),
                ],
              ),
            ),
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
          else if (visibles.isEmpty)
            _vacio()
          else
            for (final reserva in visibles)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: ReservaCard(
                  reserva: reserva,
                  estado: EstadoReserva.de(reserva, ahora),
                  onCancelar: reserva.cancelable(ahora)
                      ? () => widget.onCancelar(reserva)
                      : null,
                  onTap: () => widget.onAbrirReserva(reserva),
                ),
              ),
        ],
      ),
    );
  }

  Widget _vacio() {
    final proximas = _pestana == _Pestana.proximas;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        children: [
          Icon(
            proximas ? Icons.event_available_outlined : Icons.history,
            size: 40,
            color: AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            proximas
                ? 'No tenés reservas próximas.'
                : 'Todavía no tenés reservas finalizadas.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.lightTextPrimary),
          ),
          if (proximas) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onReservar,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.neonYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text(
                'Reservar un espacio',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
