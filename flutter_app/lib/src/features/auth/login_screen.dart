import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/routing/routing.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      context.showSnackBar('Completá email y contraseña.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signIn(email, password);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        context.showSnackBar(
          authErrorMessage(
            e.code,
            fallback: (code) => 'Error de autenticación ($code).',
          ),
        );
      }
    } catch (_) {
      if (mounted) context.showSnackBar(AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Top Sub-header
                  Text(
                    'BIENVENIDO A',
                    style: AppTextStyles.eyebrow.copyWith(
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  const TwoToneTitle(
                    primero: 'CLUB ',
                    segundo: 'NICOLAS COLLI',
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Gestión de espacios deportivos',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 36),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.fieldInput,
                    decoration: const InputDecoration(hintText: 'Email'),
                  ),
                  const SizedBox(height: 14),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTextStyles.fieldInput,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      suffixIcon: PasswordVisibilityButton(
                        obscured: _obscurePassword,
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.resetPassword),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: AppTextStyles.link,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  LoadingButton(
                    label: 'INICIAR SESIÓN',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 28),

                  // Divider with dot
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.fieldBorder)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'o',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.fieldBorder)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Footer: Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tenés cuenta? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.register),
                        child: const Text(
                          'COMENZAR →',
                          style: TextStyle(
                            color: AppColors.neonYellow,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
