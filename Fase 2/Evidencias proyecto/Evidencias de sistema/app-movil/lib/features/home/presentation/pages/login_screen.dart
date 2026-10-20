import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _sessionService = SessionService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final usuario = await _authService.login(
        correo: _emailController.text.trim(),
        contrasena: _passwordController.text,
      );
      await _sessionService.guardarSesion(usuario);
      if (mounted) {
        // Toast de éxito antes de navegar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión iniciada correctamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.home);
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
        imagePath: AppBackgrounds.login,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    64,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildDescription(),
                    const SizedBox(height: 32),
                    _buildFormCard(),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildRegisterLink(),
                    const SizedBox(height: 24),
                    _buildVersion(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ChileDex',
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryGreen,
            letterSpacing: 2.0,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 12,
                offset: const Offset(0, 0),
              ),
              Shadow(
                color: Colors.white.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Explora la fauna nativa',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
            shadows: [
              Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 10),
              Shadow(color: Colors.white.withOpacity(0.6), blurRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Identifica y aprende sobre la asombrosa biodiversidad de Chile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textDark,
            height: 1.5,
            shadows: [
              Shadow(color: Colors.white.withOpacity(0.95), blurRadius: 8),
              Shadow(color: Colors.white.withOpacity(0.7), blurRadius: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CORREO ELECTRÓNICO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryGreen,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        AppInput(
          label: 'Correo electrónico',
          hint: 'Ingresa tu correo electrónico',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          controller: _emailController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa tu correo electrónico';
            }
            if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
                .hasMatch(value.trim())) {
              return 'Ingresa un correo válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Text(
          'CONTRASEÑA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryGreen,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        AppInput(
          label: 'Contraseña',
          hint: 'Ingresa tu contraseña',
          prefixIcon: Icons.lock_outlined,
          isPassword: true,
          textInputAction: TextInputAction.done,
          controller: _passwordController,
          onSubmitted: (_) => _handleLogin(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa tu contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
            child: Text(
              '¿Olvidé mi contraseña?',
              style: TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.accentOrange,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return AppButton(
      label: 'Iniciar sesión',
      isLoading: _isLoading,
      height: 56,
      width: double.infinity,
      fontSize: 15,
      fontWeight: FontWeight.w900,
      onPressed: _handleLogin,
    );
  }

  Widget _buildRegisterLink() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta?',
          style: TextStyle(
            color: AppTheme.textGray,
            fontSize: 14,
            shadows: [
              Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          child: Text(
            'Crear cuenta',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.primaryGreen,
              shadows: [
                Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersion() {
    return Center(
      child: Text(
        'v1.0.0',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textGray.withOpacity(0.6),
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(color: Colors.white.withOpacity(0.8), blurRadius: 8),
          ],
        ),
      ),
    );
  }
}
