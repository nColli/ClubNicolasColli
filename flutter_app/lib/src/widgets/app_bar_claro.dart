import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

/// Barra superior blanca para las pantallas de fondo claro.
///
/// El tema de la app es oscuro y define íconos blancos para el AppBar
/// (`appBarTheme.iconTheme`), que tienen prioridad sobre `foregroundColor`:
/// por eso acá se fija el color de los íconos explícitamente.
class AppBarClaro extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;

  /// Botón a la izquierda; si es null se muestra la flecha de volver
  /// automática (salvo que [mostrarVolver] sea false).
  final Widget? leading;
  final bool mostrarVolver;

  const AppBarClaro({
    super.key,
    required this.titulo,
    this.leading,
    this.mostrarVolver = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final conVolver = leading != null || mostrarVolver;
    return AppBar(
      backgroundColor: AppColors.lightCard,
      foregroundColor: AppColors.lightTextPrimary,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      automaticallyImplyLeading: mostrarVolver,
      leading: leading,
      titleSpacing: conVolver ? 0 : 20,
      title: Text(
        titulo,
        style: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.lightBorder),
      ),
    );
  }
}
