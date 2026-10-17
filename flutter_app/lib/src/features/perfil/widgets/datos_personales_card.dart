import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/features/perfil/widgets/campo_perfil.dart';
import 'package:flutter_app/src/models/models.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

/// Datos personales del usuario. Con "Editar" se pueden modificar todos
/// salvo el email, que es el de la cuenta de Firebase.
class DatosPersonalesCard extends StatefulWidget {
  final Usuario usuario;
  final ValueChanged<Usuario> onGuardado;

  const DatosPersonalesCard({
    super.key,
    required this.usuario,
    required this.onGuardado,
  });

  @override
  State<DatosPersonalesCard> createState() => _DatosPersonalesCardState();
}

class _DatosPersonalesCardState extends State<DatosPersonalesCard> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _fechaController = TextEditingController();
  final _emailController = TextEditingController();

  late DateTime _fechaNacimiento;
  bool _editando = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _mostrar(widget.usuario);
  }

  @override
  void didUpdateWidget(DatosPersonalesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editando && oldWidget.usuario != widget.usuario) {
      _mostrar(widget.usuario);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _fechaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Carga los datos del usuario en los campos (descarta lo editado).
  void _mostrar(Usuario usuario) {
    _nombreController.text = usuario.nombre;
    _apellidoController.text = usuario.apellido;
    _dniController.text = usuario.dni;
    _emailController.text = usuario.email;
    _fechaNacimiento = usuario.fechaNacimiento;
    _fechaController.text = Formatters.fechaNumerica(usuario.fechaNacimiento);
  }

  void _cancelar() {
    FocusScope.of(context).unfocus();
    setState(() {
      _mostrar(widget.usuario);
      _editando = false;
    });
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento,
      firstDate: DateTime(1900),
      // La API exige una fecha pasada
      lastDate: hoy.subtract(const Duration(days: 1)),
      helpText: 'FECHA DE NACIMIENTO',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.olive,
            onPrimary: Colors.white,
            surface: AppColors.lightCard,
            onSurface: AppColors.lightTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (fecha == null) return;
    setState(() {
      _fechaNacimiento = fecha;
      _fechaController.text = Formatters.fechaNumerica(fecha);
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final usuario = await _api.actualizarPerfil(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        dni: _dniController.text,
        fechaNacimiento: _fechaNacimiento,
      );
      // El nombre también se guarda en Firebase (como al registrarse); si
      // falla no importa, la fuente de verdad es la API
      _auth.updateDisplayName(usuario.nombreCompleto).catchError((_) {});
      if (!mounted) return;
      setState(() {
        _editando = false;
        _mostrar(usuario);
      });
      widget.onGuardado(usuario);
      context.showSnackBar('Perfil actualizado.');
    } on ApiException catch (e) {
      if (mounted) context.showSnackBar(e.mensaje);
    } catch (_) {
      if (mounted) context.showSnackBar(AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = _editando && !_guardando;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'DATOS PERSONALES',
                    style: TextStyle(
                      color: AppColors.lightTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                if (!_editando)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _editando = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.olive,
                      side: const BorderSide(color: AppColors.lightBorder),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text(
                      'Editar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoPerfil(
                    label: 'Nombre',
                    controller: _nombreController,
                    habilitado: habilitado,
                    capitalization: TextCapitalization.words,
                    validator: Validators.requerido,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampoPerfil(
                    label: 'Apellido',
                    controller: _apellidoController,
                    habilitado: habilitado,
                    capitalization: TextCapitalization.words,
                    validator: Validators.requerido,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CampoPerfil(
              label: 'DNI',
              controller: _dniController,
              habilitado: habilitado,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: Validators.dni,
            ),
            const SizedBox(height: 14),
            CampoPerfil(
              label: 'Fecha de nacimiento',
              controller: _fechaController,
              habilitado: habilitado,
              onTap: _seleccionarFecha,
              suffixIcon: _editando
                  ? const Icon(Icons.calendar_today_outlined, size: 18)
                  : null,
            ),
            const SizedBox(height: 14),
            CampoPerfil(
              label: 'Email',
              nota: '(solo lectura)',
              controller: _emailController,
              habilitado: false,
              suffixIcon: const Icon(Icons.lock_outline, size: 18),
            ),
            if (_editando) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando ? null : _cancelar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightTextPrimary,
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.lightBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LoadingButton(
                      label: 'GUARDAR',
                      isLoading: _guardando,
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
