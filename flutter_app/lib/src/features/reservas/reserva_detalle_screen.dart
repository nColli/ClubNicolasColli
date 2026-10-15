import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/enums/enums.dart';
import 'package:flutter_app/src/features/reservas/widgets/cancelar_reserva_dialog.dart';
import 'package:flutter_app/src/features/reservas/widgets/detalle_reserva_card.dart';
import 'package:flutter_app/src/features/reservas/widgets/estado_reserva_badge.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Argumentos de la ruta [AppRoutes.reservaDetalle].
class ReservaDetalleArgs {
  final int reservaId;

  /// Si ya se tiene la reserva (desde la lista) se muestra sin esperar a la
  /// API; desde una notificación solo se tiene el id.
  final Reserva? reserva;

  const ReservaDetalleArgs({required this.reservaId, this.reserva});
}

/// Detalle de una reserva del usuario. Se cierra devolviendo `true` si la
/// reserva se canceló, para que las listas se actualicen.
class ReservaDetalleScreen extends StatefulWidget {
  final ReservaDetalleArgs args;

  const ReservaDetalleScreen({super.key, required this.args});

  @override
  State<ReservaDetalleScreen> createState() => _ReservaDetalleScreenState();
}

class _ReservaDetalleScreenState extends State<ReservaDetalleScreen> {
  final ApiService _api = ApiService();

  late Reserva? _reserva = widget.args.reserva;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_reserva == null) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final reserva = await _api.obtenerReserva(widget.args.reservaId);
      if (mounted) setState(() => _reserva = reserva);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cancelar(Reserva reserva) async {
    final cambio = await cancelarReservaConConfirmacion(context, reserva);
    // Cancelada (o ya no se podía cancelar): se vuelve con la lista a recargar
    if (cambio && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const AppBarClaro(titulo: 'Tu reserva'),
      body: _contenido(),
    );
  }

  Widget _contenido() {
    final reserva = _reserva;
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.olive),
      );
    }
    if (reserva == null) {
      return ListView(
        children: [
          ErrorView(
            mensaje: _error ?? AppStrings.errorInesperado,
            onReintentar: _cargar,
          ),
        ],
      );
    }

    final ahora = Reloj.ahora();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'DETALLE',
                style: TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            EstadoReservaBadge(estado: EstadoReserva.de(reserva, ahora)),
          ],
        ),
        const SizedBox(height: 12),
        DetalleReservaCard(
          imagenUrl: reserva.sedeImagenUrl,
          sedeNombre: reserva.sedeNombre,
          espacioTipo: reserva.espacioTipo,
          espacioTitulo: reserva.espacioTitulo,
          fecha: reserva.fecha,
          horaInicio: reserva.horaInicio,
          horaFin: reserva.horaFin,
          total: reserva.precioTotal,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                reserva.sedeDireccion,
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        if (reserva.cancelable(ahora)) ...[
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () => _cancelar(reserva),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              backgroundColor: AppColors.lightCard,
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text(
              'Cancelar reserva',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}
