import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/utils/reloj.dart';

/// Formatos de fecha, hora y precio en español (Argentina).
abstract final class Formatters {
  static const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _diasLargos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// "sáb, 15 ago"
  static String fechaCorta(DateTime fecha) =>
      '${_dias[fecha.weekday - 1]}, ${fecha.day} ${_meses[fecha.month - 1]}';

  /// "Miércoles 12 de agosto"
  static String fechaLarga(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
  }

  /// "sáb"
  static String diaSemanaCorto(DateTime fecha) => _dias[fecha.weekday - 1];

  /// "15/08/2026"
  static String fechaNumerica(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year}';
  }

  /// 19 -> "19:00"
  static String hora(int hora) => '${hora.toString().padLeft(2, '0')}:00';

  /// (8, 23) -> "08:00 – 23:00"
  static String rangoHorario(int desde, int hasta) =>
      '${hora(desde)} – ${hora(hasta)}';

  /// Agrupa los días consecutivos con el mismo horario:
  /// ["Lun a Vie · 08:00 – 23:00", "Sáb y Dom · 09:00 – 20:00"]
  static List<String> resumenHorarios(List<HorarioSede> horarios) {
    // Horario de cada día (lunes a domingo) como texto; vacío si ese día no abre
    final porDia = [
      for (var dia = 1; dia <= 7; dia++)
        (horarios.where((h) => h.diaSemana == dia).toList()
              ..sort((a, b) => a.horaApertura.compareTo(b.horaApertura)))
            .map((h) => rangoHorario(h.horaApertura, h.horaCierre))
            .join(', '),
    ];

    final resumen = <String>[];
    var inicio = 0;
    while (inicio < 7) {
      var fin = inicio;
      while (fin + 1 < 7 && porDia[fin + 1] == porDia[inicio]) {
        fin++;
      }
      if (porDia[inicio].isNotEmpty) {
        final dias = switch (fin - inicio) {
          0 => _diasLargos[inicio],
          1 => '${_diasLargos[inicio]} y ${_diasLargos[fin]}',
          _ => '${_diasLargos[inicio]} a ${_diasLargos[fin]}',
        };
        resumen.add('$dias · ${porDia[inicio]}');
      }
      inicio = fin + 1;
    }
    return resumen;
  }

  /// 2500 -> "$ 2.500"
  static String precio(double precio) {
    final entero = precio.round().toString();
    final conPuntos = entero.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '\$ $conPuntos';
  }

  /// "hoy", "mañana" o "en 3 días"
  static String diasHasta(DateTime fecha) {
    final ahora = Reloj.ahora();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final dias = dia.difference(hoy).inDays;
    if (dias <= 0) return 'hoy';
    if (dias == 1) return 'mañana';
    return 'en $dias días';
  }

  /// Tiempo transcurrido desde [momento]: "recién", "hace 5 min",
  /// "hace 2 h", "ayer", "hace 3 días" o la fecha ("sáb, 15 ago").
  static String haceCuanto(DateTime momento, [DateTime? ahora]) {
    final pasado = (ahora ?? DateTime.now()).difference(momento);
    if (pasado.inMinutes < 1) return 'recién';
    if (pasado.inMinutes < 60) return 'hace ${pasado.inMinutes} min';
    if (pasado.inHours < 24) return 'hace ${pasado.inHours} h';
    if (pasado.inDays == 1) return 'ayer';
    if (pasado.inDays < 7) return 'hace ${pasado.inDays} días';
    return fechaCorta(Reloj.ahora(momento));
  }

  /// Saludo según la hora del día.
  static String saludo([DateTime? ahora]) {
    final hora = (ahora ?? Reloj.ahora()).hour;
    if (hora >= 6 && hora < 12) return 'Buenos días';
    if (hora >= 12 && hora < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
