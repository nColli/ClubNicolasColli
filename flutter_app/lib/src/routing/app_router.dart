import 'package:flutter/material.dart';

import 'package:flutter_app/src/features/auth/auth.dart';
import 'package:flutter_app/src/features/home/home.dart';
import 'package:flutter_app/src/features/reservas/reservas.dart';
import 'package:flutter_app/src/features/sedes/sedes.dart';
import 'package:flutter_app/src/models/models.dart';

/// Nombres de las rutas de la app.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String sedeDetalle = '/sede';
  static const String reservar = '/reservar';
  static const String confirmarReserva = '/confirmar-reserva';
  static const String reservaDetalle = '/reserva';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.login => _ruta(settings, const LoginScreen()),
      AppRoutes.register => _ruta(settings, const RegisterScreen()),
      AppRoutes.resetPassword => _ruta(
        settings,
        ResetPasswordScreen(initialEmail: settings.arguments as String? ?? ''),
      ),
      AppRoutes.home => _ruta(settings, const HomeScreen()),
      AppRoutes.sedeDetalle => _ruta(
        settings,
        SedeDetalleScreen(sede: _argumentos<Sede>(settings)),
      ),
      AppRoutes.reservar => _ruta<Reserva>(
        settings,
        ReservarScreen.desde(_argumentos<ReservarArgs>(settings)),
      ),
      AppRoutes.confirmarReserva => _ruta<Reserva>(
        settings,
        ConfirmarReservaScreen(
          args: _argumentos<ConfirmarReservaArgs>(settings),
        ),
      ),
      // Devuelve true si la reserva se canceló
      AppRoutes.reservaDetalle => _ruta<bool>(
        settings,
        ReservaDetalleScreen(args: _argumentos<ReservaDetalleArgs>(settings)),
      ),
      _ => throw ArgumentError('Ruta desconocida: ${settings.name}'),
    };
  }

  /// Las rutas que devuelven un resultado se crean con su tipo [T], para que
  /// `pushNamed<T>` pueda recibirlo (un `MaterialPageRoute<dynamic>` no es un
  /// `Route<T?>` y falla el cast).
  /// CREO EL METODO _RUTA PARA QUE SE ACORTE EL CODIGO PARA CADA APPROUTES.ALGO
  static MaterialPageRoute<T> _ruta<T>(RouteSettings settings, Widget page) =>
      MaterialPageRoute<T>(builder: (_) => page, settings: settings);

  static T _argumentos<T>(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! T) {
      throw ArgumentError('Falta $T para la ruta ${settings.name}');
    }
    return args;
  }
}
