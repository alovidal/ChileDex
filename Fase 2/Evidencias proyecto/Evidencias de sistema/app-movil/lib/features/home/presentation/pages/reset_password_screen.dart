import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class ResetPasswordScreen extends StatefulWidget {
  /// Correo recibido desde ForgotPasswordScreen para saber a qué cuenta actualizar
  final String correo;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.correo,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleRestablecer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.restablecerContrasena(
        correo: widget.correo,
        nuevaContrasena: _passController.text,
        token: widget.token,
      );

      if (mounted) {
        // Toast de éxito antes de navegar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña restablecida correctamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ha ocurrido un error, Inténtelo nuevamente'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: AppBackgrounds.recover,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildField(
                    label: 'NUEVA CONTRASEÑA',
                    child: AppInput(
                      label: 'Nueva contraseña',
                      hint: 'Ingresa tu nueva contraseña',
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      controller: _passController,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa tu nueva contraseña';
                        }
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'REPETIR CONTRASEÑA',
                    child: AppInput(
                      label: 'Repite tu contraseña',
                      hint: 'Repite tu nueva contraseña',
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      controller: _confirmPassController,
                      onSubmitted: (_) => _handleRestablecer(),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Repite tu contraseña';
                        if (v != _passController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Restablecer Contraseña',
                    isLoading: _isLoading,
                    fontSize: 15,
                    width: double.infinity,
                    fontWeight: FontWeight.w900,
                    height: 56,
                    onPressed: _handleRestablecer,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.login,
                    ),
                    child: Center(
                      child: Text(
                        'Volver al inicio',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nueva Contraseña',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Crea tu nueva contraseña de acceso.',
          style: TextStyle(fontSize: 15, color: AppTheme.textGray, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}