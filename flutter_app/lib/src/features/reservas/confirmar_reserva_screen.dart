import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/features/reservas/widgets/detalle_reserva_card.dart';
import 'package:flutter_app/src/features/reservas/widgets/pasos_reserva.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Argumentos de la ruta [AppRoutes.confirmarReserva].
class ConfirmarReservaArgs {
  final Sede sede;
  final Espacio espacio;
  final DateTime fecha;
  final int horaInicio;
  final int horaFin;

  const ConfirmarReservaArgs({
    required this.sede,
    required this.espacio,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
  });
}

/// Muestra el resumen de la reserva elegida y la crea recién cuando el
/// usuario confirma. Se cierra devolviendo la [Reserva] creada, o null si el
/// usuario cancela o el horario ya no está disponible.
class ConfirmarReservaScreen extends StatefulWidget {
  final ConfirmarReservaArgs args;

  const ConfirmarReservaScreen({super.key, required this.args});

  @override
  State<ConfirmarReservaScreen> createState() => _ConfirmarReservaScreenState();
}

class _ConfirmarReservaScreenState extends State<ConfirmarReservaScreen> {
  final ApiService _api = ApiService();

  bool _enviando = false;

  /// Reserva creada; mientras sea null el usuario todavía no confirmó
  Reserva? _reserva;

  Future<void> _confirmar() async {
    final args = widget.args;
    setState(() => _enviando = true);
    try {
      final reserva = await _api.crearReserva(
        espacioId: args.espacio.id,
        fecha: args.fecha,
        horaInicio: args.horaInicio,
        horaFin: args.horaFin,
      );
      if (mounted) setState(() => _reserva = reserva);
    } on ApiException catch (e) {
      if (!mounted) return;
      context.showSnackBar(e.mensaje);
      // El horario ya no se puede reservar (lo tomó otro usuario o ya pasó):
      // se vuelve a elegir otro
      if (e.statusCode == 409 || e.statusCode == 422) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) context.showSnackBar(AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _cerrar() => Navigator.of(context).pop(_reserva);

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final confirmada = _reserva != null;

    return PopScope(
      // Una vez creada la reserva, volver tiene que avisar que se creó.
      // Mientras se envía no se puede salir.
      canPop: !confirmada && !_enviando,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && confirmada) _cerrar();
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBarClaro(
          titulo: confirmada ? '¡Reserva confirmada!' : 'Confirmá tu reserva',
          // Confirmada, se sale con "LISTO"; mientras se envía no se puede volver
          mostrarVolver: !confirmada,
          leading: confirmada
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _enviando
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    PasosReserva(pasoActual: confirmada ? 3 : 2),
                    const SizedBox(height: 20),
                    DetalleReservaCard(
                      imagenUrl: args.sede.imagenUrl,
                      sedeNombre: args.sede.nombre,
                      espacioTipo: args.espacio.tipo,
                      espacioTitulo: args.espacio.titulo,
                      fecha: args.fecha,
                      horaInicio: args.horaInicio,
                      horaFin: args.horaFin,
                      total:
                          args.espacio.precioHora *
                          (args.horaFin - args.horaInicio),
                    ),
                    if (confirmada) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Te esperamos. Podés ver tus reservas en la pestaña '
                        'Reservas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: confirmada ? _botonListo() : _botonesConfirmar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonesConfirmar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingButton(
          label: 'CONFIRMAR RESERVA',
          isLoading: _enviando,
          onPressed: _confirmar,
          style: _estiloBoton,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(color: Colors.red.shade700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _botonListo() {
    return LoadingButton(
      label: 'LISTO',
      isLoading: false,
      onPressed: _cerrar,
      style: _estiloBoton,
    );
  }

  static final _estiloBoton = ElevatedButton.styleFrom(
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
    ),
  );
}
