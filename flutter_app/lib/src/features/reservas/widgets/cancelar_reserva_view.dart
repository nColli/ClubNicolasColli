import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/features/reservas/widgets/reserva_card.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Pide confirmación antes de cancelar una reserva y la cancela.
class CancelarReservaView extends StatefulWidget {
  final Reserva reserva;

  /// Se llama al salir; `true` si las reservas cambiaron y hay que recargarlas
  final ValueChanged<bool> onCerrar;

  const CancelarReservaView({
    super.key,
    required this.reserva,
    required this.onCerrar,
  });

  @override
  State<CancelarReservaView> createState() => _CancelarReservaViewState();
}

class _CancelarReservaViewState extends State<CancelarReservaView> {
  final ApiService _api = ApiService();

  bool _cancelando = false;

  Future<void> _cancelar() async {
    setState(() => _cancelando = true);
    try {
      await _api.cancelarReserva(widget.reserva.id);
      if (!mounted) return;
      context.showSnackBar('Reserva cancelada. El espacio quedó liberado.');
      widget.onCerrar(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      context.showSnackBar(e.mensaje);
      // La reserva ya no existe o ya empezó: se vuelve a la lista actualizada
      if (e.statusCode == 404 || e.statusCode == 409) widget.onCerrar(true);
    } catch (_) {
      if (mounted) context.showSnackBar(AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  void _volver() {
    if (!_cancelando) widget.onCerrar(false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.lightBorder,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _volver,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.chevron_left,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Querés cancelar la reserva?',
            style: TextStyle(
              color: AppColors.lightTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'El espacio quedará liberado inmediatamente para otros jugadores. '
            'Esta acción no se puede revertir.',
            style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ReservaCard(reserva: widget.reserva),
          const SizedBox(height: 28),
          LoadingButton(
            label: 'Cancelar reserva',
            isLoading: _cancelando,
            onPressed: _cancelar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.red.shade200,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _cancelando ? null : _volver,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.lightTextPrimary,
              backgroundColor: AppColors.lightCard,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.lightBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text(
              'Volver',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
