import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/sede_imagen.dart';

/// Encabezado oscuro con la imagen de una sede, un texto chico en neón, el
/// título y opcionalmente un link para volver y la dirección.
class SedeHero extends StatelessWidget {
  final String? imagenUrl;
  final String? volverLabel;
  final VoidCallback? onVolver;
  final String eyebrow;
  final String titulo;
  final String? direccion;
  final double height;

  const SedeHero({
    super.key,
    required this.imagenUrl,
    this.volverLabel,
    this.onVolver,
    required this.eyebrow,
    required this.titulo,
    this.direccion,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    final direccion = this.direccion;
    final volverLabel = this.volverLabel;
    final textoSecundario = Colors.white.withValues(alpha: 0.7);

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SedeImagen(url: imagenUrl),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (volverLabel != null)
                    GestureDetector(
                      onTap: onVolver,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 18,
                            ),
                            Text(
                              volverLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.neonYellow,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    titulo.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  if (direccion != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: textoSecundario,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            direccion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textoSecundario,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
