import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

class SedesHeader extends StatelessWidget {
  const SedesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CLUB NICOLAS COLLI',
              style: TextStyle(
                color: AppColors.olive,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'NUESTRAS SEDES',
              style: TextStyle(
                color: AppColors.lightTextPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Elegí una sede para ver sus espacios y reservar.',
              style: TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
