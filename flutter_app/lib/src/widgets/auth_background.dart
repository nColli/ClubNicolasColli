import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/theme/theme.dart';

/// Fondo de las pantallas de autenticación: imagen con una capa oscura encima.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(AppAssets.bgImage, fit: BoxFit.cover),
        ),
        Positioned.fill(child: Container(color: AppColors.overlay)),
        child,
      ],
    );
  }
}
