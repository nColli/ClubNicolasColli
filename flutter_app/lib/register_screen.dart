import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'home_screen.dart';
import 'services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

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
      final d = fecha.day.toString().padLeft(2, '0');
      final m = fecha.month.toString().padLeft(2, '0');
      _fechaController.text = '$d/$m/${fecha.year}';
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

      final nombreCompleto =
          '${_nombreController.text.trim()} ${_apellidoController.text.trim()}';
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(nombreCompleto);

      // TODO: enviar nombre, apellido, DNI y fecha al backend (POST /users)
      // cuando exista la API en Render.

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_mensajeError(e.code));
    } catch (_) {
      _showError('Error inesperado. Intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  String _mensajeError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'El email ya está registrado.';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'operation-not-allowed':
        return 'El registro con email no está habilitado.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error de registro ($code).';
    }
  }

  // ---------- Validadores ----------

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    return null;
  }

  String? _validarDni(String? value) {
    if (value == null || value.isEmpty) return 'Campo obligatorio';
    if (value.length < 7 || value.length > 8) return 'DNI inválido';
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Email inválido';
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) return 'Campo obligatorio';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_image.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Capa oscura
          Positioned.fill(
            child: Container(color: AppColors.overlay),
          ),

          // 3. Formulario
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Volver
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            Text(
                              'Volver',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subtítulo
                    const Text(
                      'NUEVA CUENTA',
                      style: TextStyle(
                        color: AppColors.neonYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Título
                    RichText(
                      text: TextSpan(
                        style: textTheme.headlineLarge,
                        children: const [
                          TextSpan(
                            text: 'CREAR ',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          TextSpan(
                            text: 'CUENTA',
                            style: TextStyle(color: AppColors.neonYellow),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Nombre + Apellido
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _campo(
                            label: 'NOMBRE *',
                            controller: _nombreController,
                            hint: 'Juan',
                            capitalization: TextCapitalization.words,
                            validator: _requerido,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _campo(
                            label: 'APELLIDO *',
                            controller: _apellidoController,
                            hint: 'Pérez',
                            capitalization: TextCapitalization.words,
                            validator: _requerido,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // DNI
                    _campo(
                      label: 'DNI *',
                      controller: _dniController,
                      hint: '31234567',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: _validarDni,
                    ),
                    const SizedBox(height: 18),

                    // Fecha de nacimiento
                    _campo(
                      label: 'FECHA DE NACIMIENTO *',
                      controller: _fechaController,
                      hint: 'DD/MM/AAAA',
                      readOnly: true,
                      onTap: _seleccionarFecha,
                      validator: _requerido,
                    ),
                    const SizedBox(height: 18),

                    // Email
                    _campo(
                      label: 'EMAIL *',
                      controller: _emailController,
                      hint: 'juan@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validarEmail,
                    ),
                    const SizedBox(height: 18),

                    // Contraseña
                    _campo(
                      label: 'CONTRASEÑA *',
                      controller: _passwordController,
                      hint: 'Mínimo 8 caracteres',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: _validarPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('CREAR CUENTA'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Campo con etiqueta superior, según el diseño.
  Widget _campo({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          textInputAction: textInputAction,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
