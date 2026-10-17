import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';

const Color _rojo = Color(0xFFDC2626);
const Color _rojoClaro = Color(0xFFF87171);

/// Tarjeta "Zona de peligro" con el botón para dar de baja la cuenta.
class EliminarCuentaCard extends StatelessWidget {
  final VoidCallback onEliminar;

  const EliminarCuentaCard({super.key, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _rojo.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TituloZonaPeligro(),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onEliminar,
            style: _estiloBotonEliminar,
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
  }
}

/// Pide confirmación y elimina la cuenta. Devuelve `true` (con `pop`) si la
/// cuenta se eliminó; mientras se envía la request no se puede cerrar.
class EliminarCuentaDialog extends StatefulWidget {
  const EliminarCuentaDialog({super.key});

  @override
  State<EliminarCuentaDialog> createState() => _EliminarCuentaDialogState();
}

class _EliminarCuentaDialogState extends State<EliminarCuentaDialog> {
  final ApiService _api = ApiService();

  bool _eliminando = false;
  String? _error;

  Future<void> _eliminar() async {
    setState(() {
      _eliminando = true;
      _error = null;
    });
    try {
      // La API borra también los dispositivos del usuario
      await _api.eliminarCuenta();
      await NotificacionesService().desactivar();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _eliminando = false;
        _error = e is ApiException ? e.mensaje : AppStrings.errorInesperado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_eliminando,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: _rojo.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TituloZonaPeligro(),
              const SizedBox(height: 12),
              const Text(
                '¿Estás seguro? Esta acción elimina todos tus datos '
                'permanentemente.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: _rojoClaro, fontSize: 13),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _eliminando
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        backgroundColor: AppColors.card,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: AppColors.fieldBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _eliminando ? null : _eliminar,
                      style: _estiloBotonEliminar,
                      child: _eliminando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final ButtonStyle _estiloBotonEliminar = ElevatedButton.styleFrom(
  backgroundColor: _rojo,
  foregroundColor: Colors.white,
  disabledBackgroundColor: _rojo.withValues(alpha: 0.6),
  disabledForegroundColor: Colors.white,
  minimumSize: const Size.fromHeight(48),
  elevation: 6,
  shadowColor: _rojo.withValues(alpha: 0.5),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
);

class _TituloZonaPeligro extends StatelessWidget {
  const _TituloZonaPeligro();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.warning_rounded, color: _rojoClaro, size: 14),
        SizedBox(width: 6),
        Text(
          'ZONA DE PELIGRO',
          style: TextStyle(
            color: _rojoClaro,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
