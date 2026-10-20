import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleBuscar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final correo = _emailController.text.trim();
      await _authService.buscarCorreo(correo: correo);

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.verificarToken,
          arguments: correo,
        );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildField(),
                  const SizedBox(height: 32),
                  _buildButtons(),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Recuperar Contraseña',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ingresa tu correo y te enviaremos instrucciones para restablecer tu contraseña.',
          style: TextStyle(fontSize: 15, color: AppTheme.textGray, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CORREO ELECTRÓNICO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        AppInput(
          label: 'Correo electrónico',
          hint: 'ejemplo@chiledex.cl',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          controller: _emailController,
          onSubmitted: (_) => _handleBuscar(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
            if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
              return 'Correo inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        AppButton(
          label: 'Recuperar contraseña',
          fontSize: 15,
          width: double.infinity,
          fontWeight: FontWeight.w900,
          isLoading: _isLoading,
          height: 56,
          onPressed: _handleBuscar,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
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
    );
  }
}