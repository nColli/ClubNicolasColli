import 'package:flutter/material.dart';

import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Card de un espacio deportivo con su precio, el horario de hoy y el botón
/// para reservar.
class EspacioCard extends StatelessWidget {
  final Espacio espacio;
  final Sede sede;
  final VoidCallback onReservar;

  const EspacioCard({
    super.key,
    required this.espacio,
    required this.sede,
    required this.onReservar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SedeImagen(url: sede.imagenUrl),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      espacio.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Espacio N° ${espacio.numero} · Sede ${sede.nombre}',
                            style: const TextStyle(
                              color: AppColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DeporteTag(deporte: espacio.tipo),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.precio(espacio.precioHora),
                          style: const TextStyle(
                            color: AppColors.lightTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'por hora',
                          style: TextStyle(
                            color: AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.lightBorder),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _horarioDeHoy(),
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onReservar,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.neonYellow,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(Icons.event_available, size: 18),
                  label: const Text(
                    'VER HORARIOS / RESERVAR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _horarioDeHoy() {
    final hoy = sede.horariosDel(Reloj.ahora().weekday);
    if (hoy.isEmpty) return 'Hoy cerrado';
    return 'Hoy ${hoy.map((h) => Formatters.rangoHorario(h.horaApertura, h.horaCierre)).join(', ')}';
  }
}
