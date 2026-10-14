import 'package:flutter/material.dart';

import 'package:flutter_app/src/theme/theme.dart';

/// Imagen de la sede, con un fondo verde si no tiene o no se puede cargar.
class SedeImagen extends StatelessWidget {
  final String? url;

  const SedeImagen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.sedePlaceholder,
      alignment: Alignment.center,
      child: Icon(
        Icons.sports_soccer,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
    final url = this.url;
    if (url == null) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progreso) =>
          progreso == null ? child : placeholder,
    );
  }
}
