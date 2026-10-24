import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_app/src/constants/constants.dart';
import 'package:flutter_app/src/extensions/extensions.dart';
import 'package:flutter_app/src/services/services.dart';
import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/utils/utils.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail.trim(),
  );

  bool _isLoading = false;
  bool _enviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ---------- Acciones ----------

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordReset(_emailController.text);
      if (!mounted) return;
      setState(() => _enviado = true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        context.showSnackBar(
          authErrorMessage(
            e.code,
            fallback: (code) => 'No se pudo enviar el email ($code).',
          ),
        );
      }
    } catch (_) {
      if (mounted) context.showSnackBar(AppStrings.errorInesperado);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

                  const Text('RESETEAR CONTRASEÑA', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 6),

                  const TwoToneTitle(primero: 'NUEVA ', segundo: 'CONTRASEÑA'),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    _enviado
                        ? 'Si el email está registrado, vas a recibir un enlace '
                              'para crear una contraseña nueva. Revisá también spam.'
                        : 'Ingresá tu email. Te enviamos un enlace para crear '
                              'una contraseña nueva.',
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  if (!_enviado) ...[
                    LabeledTextField(
                      label: 'EMAIL *',
                      controller: _emailController,
                      hint: 'juan@email.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleReset(),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 28),

                    LoadingButton(
                      label: 'ENVIAR ENLACE',
                      isLoading: _isLoading,
                      onPressed: _handleReset,
                    ),
                  ] else ...[
                    // Botón volver al login
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('VOLVER'),
                    ),
                    const SizedBox(height: 16),

                    // Reenviar
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _enviado = false),
                        child: const Text(
                          '¿No llegó el email? REENVIAR',
                          style: AppTextStyles.link,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
