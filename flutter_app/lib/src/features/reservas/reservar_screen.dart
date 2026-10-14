import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/features/reservas/confirmar_reserva_screen.dart';
import 'package:flutter_app/src/features/reservas/widgets/etiqueta_seccion.dart';
import 'package:flutter_app/src/features/reservas/widgets/grilla_turnos.dart';
import 'package:flutter_app/src/features/reservas/widgets/resumen_reserva.dart';
import 'package:flutter_app/src/features/reservas/widgets/selector_fecha.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Argumentos de la ruta [AppRoutes.reservar].
class ReservarArgs {
  final Sede sede;
  final Espacio espacio;

  const ReservarArgs({required this.sede, required this.espacio});
}

/// Pantalla para elegir fecha, duración y horario de una reserva. Al
/// continuar abre la confirmación; si ahí se crea la reserva, se cierra
/// devolviendo la [Reserva] creada.
class ReservarScreen extends StatefulWidget {
  final Sede sede;
  final Espacio espacio;

  const ReservarScreen({super.key, required this.sede, required this.espacio});

  ReservarScreen.desde(ReservarArgs args, {Key? key})
    : this(key: key, sede: args.sede, espacio: args.espacio);

  @override
  State<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends State<ReservarScreen> {
  static const _diasAMostrar = 14;
  static const _duraciones = [1, 2];

  final ApiService _api = ApiService();

  late final List<DateTime> _fechas;
  late DateTime _fecha;
  int _duracion = 1;
  int? _horaInicio;

  bool _cargando = true;
  String? _error;
  List<HoraDisponibilidad> _horas = [];

  @override
  void initState() {
    super.initState();
    final hoy = DateUtils.dateOnly(Reloj.ahora());
    _fechas = [
      for (var i = 0; i < _diasAMostrar; i++) hoy.add(Duration(days: i)),
    ];
    _fecha = _fechas.firstWhere((f) => !_estaCerrado(f), orElse: () => hoy);
    _cargarDisponibilidad();
  }

  bool _estaCerrado(DateTime fecha) =>
      widget.sede.horariosDel(fecha.weekday).isEmpty;

  List<Turno> get _turnos => Turno.armar(_horas, _duracion);

  /// Con [mantenerSeleccion] recarga sin mostrar el spinner y conserva el
  /// turno elegido si sigue disponible.
  Future<void> _cargarDisponibilidad({bool mantenerSeleccion = false}) async {
    final fecha = _fecha;
    setState(() {
      _cargando = !mantenerSeleccion;
      _error = null;
      if (!mantenerSeleccion) _horaInicio = null;
    });
    try {
      final horas = await _api.obtenerDisponibilidad(widget.espacio.id, fecha);
      // Si mientras tanto se eligió otra fecha, esta respuesta ya no sirve
      if (!mounted || fecha != _fecha) return;
      setState(() {
        _horas = horas;
        final sigueLibre = _turnos.any(
          (t) => t.horaInicio == _horaInicio && t.disponible,
        );
        if (!sigueLibre) _horaInicio = null;
      });
    } on ApiException catch (e) {
      if (mounted && fecha == _fecha) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted && fecha == _fecha) {
        setState(() => _error = AppStrings.errorInesperado);
      }
    } finally {
      if (mounted && fecha == _fecha) setState(() => _cargando = false);
    }
  }

  void _elegirFecha(DateTime fecha) {
    if (fecha == _fecha) return;
    _fecha = fecha;
    _cargarDisponibilidad();
  }

  void _elegirDuracion(int duracion) {
    setState(() {
      _duracion = duracion;
      _horaInicio = null;
    });
  }

  Future<void> _continuar() async {
    final horaInicio = _horaInicio;
    if (horaInicio == null) return;

    final reserva = await Navigator.of(context).pushNamed<Reserva>(
      AppRoutes.confirmarReserva,
      arguments: ConfirmarReservaArgs(
        sede: widget.sede,
        espacio: widget.espacio,
        fecha: _fecha,
        horaInicio: horaInicio,
        horaFin: horaInicio + _duracion,
      ),
    );
    if (!mounted) return;
    if (reserva != null) {
      Navigator.of(context).pop(reserva);
    } else {
      // Se canceló o el horario dejó de estar libre: se actualiza la grilla
      _cargarDisponibilidad(mantenerSeleccion: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final espacio = widget.espacio;

    return Scaffold(
      backgroundColor: AppColors.lightCard,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SedeHero(
            imagenUrl: widget.sede.imagenUrl,
            volverLabel: 'Sede ${widget.sede.nombre}',
            onVolver: () => Navigator.of(context).pop(),
            eyebrow: '${espacio.tipo} · ${espacio.titulo}',
            titulo: 'Sede ${widget.sede.nombre}',
            height: 230,
          ),
          // Panel blanco que se superpone al hero, como una hoja
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.lightCard,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.pill),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 18),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: EtiquetaSeccion('Fecha'),
                    ),
                    SelectorFecha(
                      fechas: _fechas,
                      seleccionada: _fecha,
                      estaCerrado: _estaCerrado,
                      onSeleccionar: _elegirFecha,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EtiquetaSeccion('Duración'),
                          SelectorSegmentado<int>(
                            opciones: _duraciones,
                            seleccionada: _duracion,
                            etiqueta: (h) => h == 1 ? '1 hora' : '$h horas',
                            onSeleccionar: _elegirDuracion,
                          ),
                          const SizedBox(height: 24),
                          const EtiquetaSeccion('Horario disponible'),
                          _horarios(),
                          const SizedBox(height: 24),
                          ResumenReserva(espacio: espacio, horas: _duracion),
                          const SizedBox(height: 16),
                          LoadingButton(
                            label: _horaInicio == null
                                ? 'SELECCIONÁ UN HORARIO'
                                : 'CONTINUAR',
                            isLoading: false,
                            onPressed: _horaInicio == null ? null : _continuar,
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: AppColors.lightBorder,
                              disabledForegroundColor:
                                  AppColors.lightTextSecondary,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horarios() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.olive)),
      );
    }
    if (_error != null) {
      return ErrorView(mensaje: _error!, onReintentar: _cargarDisponibilidad);
    }
    final turnos = _turnos;
    if (turnos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No hay horarios para este día.',
          style: TextStyle(color: AppColors.lightTextSecondary),
        ),
      );
    }
    return GrillaTurnos(
      turnos: turnos,
      horaSeleccionada: _horaInicio,
      onSeleccionar: (t) => setState(() => _horaInicio = t.horaInicio),
    );
  }
}
