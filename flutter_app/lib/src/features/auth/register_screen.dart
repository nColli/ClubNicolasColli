import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _fechaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _fechaNacimiento;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _fechaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------- Acciones ----------

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate:
          _fechaNacimiento ?? DateTime(hoy.year - 18, hoy.month, hoy.day),
      firstDate: DateTime(1900),
      lastDate: hoy,
      helpText: 'FECHA DE NACIMIENTO',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonYellow,
            onPrimary: Colors.black,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
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

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        _emailController.text,
        _passwordController.text,
      );

      final nombre = _nombreController.text.trim();
      final apellido = _apellidoController.text.trim();
      await _authService.updateDisplayName('$nombre $apellido');

      try {
        await _apiService.registrarUsuario(
          nombre: nombre,
          apellido: apellido,
          dni: _dniController.text,
          fechaNacimiento: _fechaNacimiento!,
        );
      } catch (_) {
        // Si el backend no registró el perfil, se borra la cuenta de Firebase
        // para que el usuario pueda reintentar con el mismo email.
        await _authService.deleteCurrentUser();
        rethrow;
      }

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } on FirebaseAuthException catch (e) {
      _showError(
        authErrorMessage(
          e.code,
          fallback: (code) => 'Error de registro ($code).',
        ),
      );
    } on ApiException catch (e) {
      _showError(e.mensaje);
    } catch (_) {
      _showError(AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String mensaje) {
    if (mounted) context.showSnackBar(mensaje);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BackLink(),
                  const SizedBox(height: 20),

                  const Text('NUEVA CUENTA', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),

                  const TwoToneTitle(primero: 'CREAR ', segundo: 'CUENTA'),
                  const SizedBox(height: 28),

                  // Nombre + Apellido
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledTextField(
                          label: 'NOMBRE *',
                          controller: _nombreController,
                          hint: 'Juan',
                          capitalization: TextCapitalization.words,
                          validator: Validators.requerido,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledTextField(
                          label: 'APELLIDO *',
                          controller: _apellidoController,
                          hint: 'Pérez',
                          capitalization: TextCapitalization.words,
                          validator: Validators.requerido,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  LabeledTextField(
                    label: 'DNI *',
                    controller: _dniController,
                    hint: '31234567',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: Validators.dni,
                  ),
                  const SizedBox(height: 18),

                  LabeledTextField(
                    label: 'FECHA DE NACIMIENTO *',
                    controller: _fechaController,
                    hint: 'DD/MM/AAAA',
                    readOnly: true,
                    onTap: _seleccionarFecha,
                    validator: Validators.requerido,
                  ),
                  const SizedBox(height: 18),

                  LabeledTextField(
                    label: 'EMAIL *',
                    controller: _emailController,
                    hint: 'juan@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 18),

                  LabeledTextField(
                    label: 'CONTRASEÑA *',
                    controller: _passwordController,
                    hint: 'Mínimo 8 caracteres',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                    suffixIcon: PasswordVisibilityButton(
                      obscured: _obscurePassword,
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 28),

                  LoadingButton(
                    label: 'CREAR CUENTA',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
