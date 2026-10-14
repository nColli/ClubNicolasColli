import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';

class HomeHero extends StatelessWidget {
  final Usuario? perfil;
  final VoidCallback onAvatarTap;

  /// Muestra el punto en la campana
  final bool hayNotificacionesNuevas;
  final VoidCallback onNotificacionesTap;

  const HomeHero({
    super.key,
    required this.perfil,
    required this.onAvatarTap,
    required this.hayNotificacionesNuevas,
    required this.onNotificacionesTap,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = perfil?.nombreCompleto ?? '';
    final iniciales = perfil?.iniciales ?? '';

    return SizedBox(
      height: 270,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.bgImage,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Container(color: AppColors.heroPlaceholder),
          ),
          // Oscurece arriba y se funde con el fondo claro abajo
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.65, 1],
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.35),
                  AppColors.lightBackground,
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Formatters.saludo().toUpperCase()},',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NotificacionesButton(
                        hayNuevas: hayNotificacionesNuevas,
                        onTap: onNotificacionesTap,
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.neonYellow,
                          child: Text(
                            iniciales,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'CLUB NICOLAS COLLI',
                    style: TextStyle(
                      color: AppColors.neonYellow,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ZONA DEPORTIVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificacionesButton extends StatelessWidget {
  final bool hayNuevas;
  final VoidCallback onTap;

  const _NotificacionesButton({required this.hayNuevas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 18,
                semanticLabel: hayNuevas
                    ? 'Notificaciones, hay nuevas'
                    : 'Notificaciones',
              ),
              if (hayNuevas)
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.neonYellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
