import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';

/// Pide confirmación y cancela [reserva]. Devuelve `true` si las reservas
/// cambiaron y hay que recargarlas: se canceló, o ya no existía o ya empezó.
Future<bool> cancelarReservaConConfirmacion(
  BuildContext context,
  Reserva reserva,
) async {
  final cambio = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _CancelarReservaDialog(reserva: reserva),
  );
  return cambio == true;
}

class _CancelarReservaDialog extends StatefulWidget {
  final Reserva reserva;

  const _CancelarReservaDialog({required this.reserva});

  @override
  State<_CancelarReservaDialog> createState() => _CancelarReservaDialogState();
}

class _CancelarReservaDialogState extends State<_CancelarReservaDialog> {
  final ApiService _api = ApiService();

  bool _cancelando = false;

  Future<void> _cancelar() async {
    setState(() => _cancelando = true);
    try {
      await _api.cancelarReserva(widget.reserva.id);
      if (!mounted) return;
      context.showSnackBar('Reserva cancelada. El espacio quedó liberado.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      context.showSnackBar(e.mensaje);
      // La reserva ya no existe o ya empezó: se cierra para recargar
      if (e.statusCode == 404 || e.statusCode == 409) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _cancelando = false);
      }
    } catch (_) {
      if (!mounted) return;
      context.showSnackBar(AppStrings.errorInesperado);
      setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_cancelando,
      child: AlertDialog(
        backgroundColor: AppColors.lightCard,
        title: const Text(
          '¿Cancelar la reserva?',
          style: TextStyle(
            color: AppColors.lightTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'El espacio quedará liberado inmediatamente para otros jugadores. '
          'Esta acción no se puede revertir.',
          style: TextStyle(color: AppColors.lightTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: _cancelando
                ? null
                : () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.lightTextSecondary,
            ),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: _cancelando ? null : _cancelar,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: _cancelando
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red.shade700,
                    ),
                  )
                : const Text(
                    'Cancelar reserva',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}
