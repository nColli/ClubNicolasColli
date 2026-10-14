import 'package:flutter/material.dart';

/// Pestañas de la barra de navegación inferior del home, en orden.
enum HomeTab {
  inicio(Icons.home_outlined, 'INICIO'),
  sedes(Icons.apartment_outlined, 'SEDES'),
  reservas(Icons.calendar_today_outlined, 'RESERVAS'),
  perfil(Icons.person_outline, 'PERFIL');

  final IconData icono;
  final String label;

  const HomeTab(this.icono, this.label);
}
