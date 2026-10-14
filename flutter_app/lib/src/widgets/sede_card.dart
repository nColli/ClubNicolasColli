import 'package:flutter/material.dart';

import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/deporte_tag.dart';
import 'package:flutter_app/src/widgets/sede_imagen.dart';

/// Card de una sede: imagen con el nombre, dirección y deportes.
///
/// La versión compacta se usa en el carrusel del home; la expandida ocupa
/// todo el ancho y suma si está abierta, los horarios y "Ver espacios".
class SedeCard extends StatelessWidget {
  final Sede sede;
  final VoidCallback onTap;
  final bool expandida;

  const SedeCard({
    super.key,
    required this.sede,
    required this.onTap,
    this.expandida = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          expandida ? AppRadius.lg : AppRadius.md,
        ),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: expandida ? double.infinity : 168,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Imagen(sede: sede, expandida: expandida),
              Padding(
                padding: EdgeInsets.all(expandida ? 14 : 10),
                child: expandida
                    ? _DetalleExpandido(sede: sede)
                    : _DetalleCompacto(sede: sede),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Imagen extends StatelessWidget {
  final Sede sede;
  final bool expandida;

  const _Imagen({required this.sede, required this.expandida});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: expandida ? 160 : 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SedeImagen(url: sede.imagenUrl),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          if (expandida)
            Positioned(
              top: 12,
              left: 12,
              child: _EstadoPill(abierta: sede.estaAbierta(Reloj.ahora())),
            ),
          Positioned(
            left: expandida ? 14 : 10,
            right: expandida ? 14 : 10,
            bottom: expandida ? 12 : 10,
            child: Text(
              sede.nombre.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: expandida ? 20 : 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoPill extends StatelessWidget {
  final bool abierta;

  const _EstadoPill({required this.abierta});

  @override
  Widget build(BuildContext context) {
    final color = abierta ? AppColors.neonYellow : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            abierta ? 'ABIERTA AHORA' : 'CERRADA',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Direccion extends StatelessWidget {
  final String direccion;
  final double fontSize;

  const _Direccion({required this.direccion, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: fontSize + 2,
          color: AppColors.lightTextSecondary,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            direccion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.lightTextSecondary,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetalleCompacto extends StatelessWidget {
  final Sede sede;

  const _DetalleCompacto({required this.sede});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Direccion(direccion: sede.direccion, fontSize: 11),
        const SizedBox(height: 8),
        SizedBox(
          height: 22,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sede.deportes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (_, i) => DeporteTag(deporte: sede.deportes[i]),
          ),
        ),
      ],
    );
  }
}

class _DetalleExpandido extends StatelessWidget {
  final Sede sede;

  const _DetalleExpandido({required this.sede});

  @override
  Widget build(BuildContext context) {
    final horarios = Formatters.resumenHorarios(sede.horarios);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Direccion(direccion: sede.direccion, fontSize: 12),
        if (horarios.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final horario in horarios)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    horario,
                    style: const TextStyle(
                      color: AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final deporte in sede.deportes)
                    DeporteTag(deporte: deporte),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ver espacios →',
              style: TextStyle(
                color: AppColors.olive,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
