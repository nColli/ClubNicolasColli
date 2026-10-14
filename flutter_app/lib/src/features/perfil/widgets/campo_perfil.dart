import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_app/src/theme/theme.dart';

/// Campo del formulario de perfil, sobre fondo claro. Deshabilitado se ve
/// gris, como un dato de solo lectura.
class CampoPerfil extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool habilitado;

  /// Texto chico al lado de la etiqueta ("(solo lectura)")
  final String? nota;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const CampoPerfil({
    super.key,
    required this.label,
    required this.controller,
    required this.habilitado,
    this.nota,
    this.capitalization = TextCapitalization.none,
    this.keyboardType,
    this.inputFormatters,
    this.onTap,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final nota = this.nota;
    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label.toUpperCase(),
            children: [
              if (nota != null)
                TextSpan(
                  text: '  $nota',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: habilitado,
          // Con onTap el valor se elige con un selector (ej. la fecha)
          readOnly: onTap != null,
          onTap: onTap,
          textCapitalization: capitalization,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(
            color: habilitado
                ? AppColors.lightTextPrimary
                : AppColors.lightTextSecondary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: habilitado
                ? AppColors.lightCard
                : AppColors.lightBackground,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            suffixIcon: suffixIcon,
            suffixIconColor: AppColors.lightTextSecondary,
            enabledBorder: borde(AppColors.lightBorder),
            disabledBorder: borde(AppColors.lightBorder),
            focusedBorder: borde(AppColors.olive, 1.4),
            errorBorder: borde(Colors.red.shade400),
            focusedErrorBorder: borde(Colors.red.shade400, 1.4),
            errorStyle: TextStyle(color: Colors.red.shade700),
          ),
        ),
      ],
    );
  }
}
