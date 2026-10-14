import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/features/reservas/reservas.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/routing/routing.dart';

void main() {
  test('la ruta de reservar devuelve una Reserva (pushNamed<Reserva>)', () {
    const args = ReservarArgs(
      sede: Sede(
        id: 1,
        nombre: 'Morón',
        direccion: 'Av. Rivadavia 17500',
        imagenUrl: null,
        deportes: [],
        horarios: [],
      ),
      espacio: Espacio(
        id: 1,
        tipo: 'Fútbol',
        numero: 1,
        nombre: 'x',
        precioHora: 3000,
      ),
    );
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.reservar, arguments: args),
    );
    expect(route, isA<Route<Reserva?>>());

    final confirmar = AppRouter.onGenerateRoute(
      RouteSettings(
        name: AppRoutes.confirmarReserva,
        arguments: ConfirmarReservaArgs(
          sede: args.sede,
          espacio: args.espacio,
          fecha: DateTime(2026, 10, 15),
          horaInicio: 18,
          horaFin: 19,
        ),
      ),
    );
    expect(confirmar, isA<Route<Reserva?>>());
  });

  test('el detalle de reserva devuelve si se canceló (pushNamed<bool>)', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(
        name: AppRoutes.reservaDetalle,
        arguments: ReservaDetalleArgs(reservaId: 3),
      ),
    );
    expect(route, isA<Route<bool?>>());
  });

  test('una ruta sin sus argumentos falla con un error claro', () {
    expect(
      () => AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.confirmarReserva),
      ),
      throwsArgumentError,
    );
  });
}
