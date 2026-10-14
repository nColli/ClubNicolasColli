import 'package:flutter/material.dart';

class EstiloDeporte {
  final String emoji;
  final Color fondo;
  final Color texto;

  const EstiloDeporte(this.emoji, this.fondo, this.texto);

  static const _estilos = {
    'Fútbol': EstiloDeporte('⚽', Color(0xFFE2F6EA), Color(0xFF1E8A4C)),
    'Tenis': EstiloDeporte('🎾', Color(0xFFFFEBDD), Color(0xFFE8590C)),
    'Golf': EstiloDeporte('⛳', Color(0xFFE6F4F1), Color(0xFF0F7C6B)),
    'Hockey': EstiloDeporte('🏑', Color(0xFFEFE6FF), Color(0xFF7B3FE4)),
    'Paddle': EstiloDeporte('🏓', Color(0xFFE3EEFF), Color(0xFF2F6BD8)),
    'Básquet': EstiloDeporte('🏀', Color(0xFFFFF0E0), Color(0xFFC2600B)),
  };

  static EstiloDeporte de(String deporte) =>
      _estilos[deporte] ??
      const EstiloDeporte('🏅', Color(0xFFEDEEF1), Color(0xFF55595F));
}
