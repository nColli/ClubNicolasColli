import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';

/// Abre el panel de notificaciones arriba de la pantalla. Al tocar una
/// notificación de una reserva vigente se cierra y llama a [onAbrirReserva].
Future<void> mostrarNotificaciones(
  BuildContext context, {
  required ValueChanged<int> onAbrirReserva,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar notificaciones',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          child: NotificacionesPanel(
            onAbrirReserva: (id) {
              Navigator.of(context).pop();
              onAbrirReserva(id);
            },
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animacion, _, child) => FadeTransition(
      opacity: animacion,
      child: ScaleTransition(
        alignment: Alignment.topRight,
        scale: Tween(begin: 0.95, end: 1.0).animate(animacion),
        child: child,
      ),
    ),
  );
}

/// Lista de notificaciones del usuario. Al abrirse las marca como leídas,
/// pero mientras está abierto sigue resaltando las que eran nuevas.
class NotificacionesPanel extends StatefulWidget {
  final ValueChanged<int> onAbrirReserva;

  const NotificacionesPanel({super.key, required this.onAbrirReserva});

  @override
  State<NotificacionesPanel> createState() => _NotificacionesPanelState();
}

class _NotificacionesPanelState extends State<NotificacionesPanel> {
  final ApiService _api = ApiService();

  bool _cargando = true;
  String? _error;
  List<Notificacion> _notificaciones = [];

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
      final notificaciones = await _api.obtenerNotificaciones();
      if (!mounted) return;
      setState(() => _notificaciones = notificaciones);
      if (notificaciones.any((n) => !n.leida)) {
        _api.marcarNotificacionesLeidas().catchError((_) {});
      }
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
    return Material(
      color: AppColors.lightCard,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(
                        color: AppColors.lightTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Flexible: con muchas notificaciones la lista scrollea dentro
              // del alto máximo del panel
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _contenido(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.olive)),
      );
    }
    final error = _error;
    if (error != null) {
      return _Mensaje(texto: error, onReintentar: _cargar);
    }
    if (_notificaciones.isEmpty) {
      return const _Mensaje(texto: 'No tenés notificaciones.');
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _notificaciones.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final notificacion = _notificaciones[i];
        final reservaId = notificacion.reservaId;
        return _NotificacionTile(
          notificacion: notificacion,
          onTap: reservaId == null
              ? null
              : () => widget.onAbrirReserva(reservaId),
        );
      },
    );
  }
}

class _NotificacionTile extends StatelessWidget {
  final Notificacion notificacion;
  final VoidCallback? onTap;

  const _NotificacionTile({required this.notificacion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nueva = !notificacion.leida;
    return Material(
      color: AppColors.lightBackground,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  // Neón con borde oliva para que se vea sobre fondo claro
                  color: nueva ? AppColors.neonYellow : AppColors.lightBorder,
                  shape: BoxShape.circle,
                  border: nueva
                      ? Border.all(color: AppColors.olive, width: 1)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacion.titulo,
                      style: TextStyle(
                        color: AppColors.lightTextPrimary,
                        fontSize: 15,
                        fontWeight: nueva ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notificacion.cuerpo,
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.haceCuanto(notificacion.creada),
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 2),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final String texto;
  final VoidCallback? onReintentar;

  const _Mensaje({required this.texto, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final onReintentar = this.onReintentar;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_none,
            size: 32,
            color: AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.lightTextSecondary),
          ),
          if (onReintentar != null)
            TextButton(
              onPressed: onReintentar,
              style: TextButton.styleFrom(foregroundColor: AppColors.olive),
              child: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
