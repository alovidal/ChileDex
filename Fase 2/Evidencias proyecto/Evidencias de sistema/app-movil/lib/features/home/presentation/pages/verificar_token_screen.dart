import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';

class VerificarTokenScreen extends StatefulWidget {
  final String correo;
  const VerificarTokenScreen({super.key, required this.correo});

  @override
  State<VerificarTokenScreen> createState() => _VerificarTokenScreenState();
}

class _VerificarTokenScreenState extends State<VerificarTokenScreen> {
  // 6 campos, uno por dígito
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String get _tokenCompleto => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitIngresado(int index, String value) {
    if (value.length == 1 && index < 5) {
      // Avanzar al siguiente campo
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      // Retroceder al anterior con backspace
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _verificar() {
    if (_tokenCompleto.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código completo')),
      );
      return;
    }
    // Pasar correo y token a ResetPasswordScreen
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.resetPassword,
      arguments: {'correo': widget.correo, 'token': _tokenCompleto},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: AppBackgrounds.recover,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildCamposCodigo(),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Verificar código',
                  width: double.infinity,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 56,
                  onPressed: _verificar,
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Reenviar código',
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
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verifica tu correo',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryGreen,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ingresa el código de 6 dígitos que enviamos a ${widget.correo}',
          style: TextStyle(fontSize: 15, color: AppTheme.textGray, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildCamposCodigo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
            decoration: InputDecoration(
              counterText: '', // ocultar contador de caracteres
              filled: true,
              fillColor: AppTheme.cardWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
              ),
            ),
            onChanged: (v) => _onDigitIngresado(i, v),
          ),
        );
      }),
    );
  }
}
