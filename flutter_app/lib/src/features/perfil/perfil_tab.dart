import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/features/perfil/widgets/datos_personales_card.dart';
import 'package:flutter_app/src/features/perfil/widgets/opcion_perfil.dart';
import 'package:flutter_app/src/features/perfil/widgets/perfil_header.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Pestaña "Mi perfil": datos del usuario (editables salvo el email),
/// cambio de contraseña y cierre de sesión.
class PerfilTab extends StatefulWidget {
  /// Se llama al guardar cambios, para que el resto del home los muestre
  final VoidCallback onPerfilActualizado;

  const PerfilTab({super.key, required this.onPerfilActualizado});

  @override
  State<PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<PerfilTab> {
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  bool _cargando = true;
  String? _error;
  Usuario? _usuario;

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
      final usuario = await _api.obtenerPerfil();
      if (mounted) setState(() => _usuario = usuario);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) setState(() => _error = AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _guardado(Usuario usuario) {
    setState(() => _usuario = usuario);
    widget.onPerfilActualizado();
  }

  /// Usa el mismo flujo que "¿Olvidaste tu contraseña?": Firebase envía un
  /// email para elegir una contraseña nueva.
  void _cambiarContrasena(Usuario usuario) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.resetPassword, arguments: usuario.email);
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lightCard,
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(
            color: AppColors.lightTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Vas a tener que volver a ingresar con tu email y contraseña.',
          style: TextStyle(color: AppColors.lightTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.lightTextSecondary,
            ),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.olive),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      // Antes de cerrar sesión, porque quitar el dispositivo requiere el token
      await NotificacionesService().desactivar();
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (mounted) context.showSnackBar(AppStrings.errorInesperado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;

    return RefreshIndicator(
      color: AppColors.olive,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TwoToneTitle(
                    primero: 'MI ',
                    segundo: 'PERFIL',
                    colorPrimero: AppColors.lightTextPrimary,
                    colorSegundo: AppColors.neonYellow,
                  ),
                  const SizedBox(height: 20),
                  if (_cargando && usuario == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.olive,
                        ),
                      ),
                    )
                  else if (usuario == null) ...[
                    ErrorView(
                      mensaje: _error ?? AppStrings.errorInesperado,
                      onReintentar: _cargar,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    PerfilHeader(usuario: usuario),
                    const SizedBox(height: 20),
                    DatosPersonalesCard(
                      usuario: usuario,
                      onGuardado: _guardado,
                    ),
                    const SizedBox(height: 12),
                    OpcionPerfil(
                      seccion: 'Seguridad',
                      titulo: 'Cambiar contraseña',
                      onTap: () => _cambiarContrasena(usuario),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Cerrar sesión se puede aunque no haya cargado el perfil
                  OutlinedButton.icon(
                    onPressed: _cerrarSesion,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.olive,
                      backgroundColor: AppColors.lightCard,
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.lightBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
