import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

class SeccionHeader extends StatelessWidget {
  final String titulo;
  final VoidCallback onVerTodas;

  const SeccionHeader({
    super.key,
    required this.titulo,
    required this.onVerTodas,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: AppColors.lightTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          GestureDetector(
            onTap: onVerTodas,
            child: const Text(
              'Ver todas →',
              style: TextStyle(
                color: AppColors.olive,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
