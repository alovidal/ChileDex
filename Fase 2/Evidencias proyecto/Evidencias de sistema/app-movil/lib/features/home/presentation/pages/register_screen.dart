import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/region_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/especie_service.dart';
import '../../../../core/services/foto_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/foto_perfil_picker.dart';
import '../widgets/foto_picker_mixin.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with FotoPickerMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apPaternoController = TextEditingController();
  final _apMaternoController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── Servicios ──────────────────────────────────────────────────────────────
  final _authService = AuthService();
  final _sessionService = SessionService();

  // ── Estado ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  DateTime? _fechaNacimiento;

  // --- Regiones ─────────────────────────────────────────────────────────────
  int? _idRegionSeleccionada;
  List<RegionModel> _regiones = [];

  @override
  void initState() {
    super.initState();
    _cargarRegiones();
  }

  Future<void> _cargarRegiones() async {
    try {
      final regiones = await EspecieService().obtenerRegionesRegistro();
      if (mounted) setState(() => _regiones = regiones);
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nombreController.dispose();
    _apPaternoController.dispose();
    _apMaternoController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ── Lógica ─────────────────────────────────────────────────────────────────

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(hoy.year - 18, hoy.month, hoy.day),
      firstDate: DateTime(1900),
      lastDate: hoy,
      locale: const Locale('es', 'CL'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primaryGreen,
            onSurface: AppTheme.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  String get _fechaFormateada {
    if (_fechaNacimiento == null) return 'DD / MM / AAAA';
    final d = _fechaNacimiento!;
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / '
        '${d.year}';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final usuario = await _authService.registrar(
        correo: _emailController.text.trim(),
        contrasena: _passController.text,
        nombre: _nombreController.text.trim(),
        apPaterno: _apPaternoController.text.trim().isEmpty
            ? null
            : _apPaternoController.text.trim(),
        apMaterno: _apMaternoController.text.trim().isEmpty
            ? null
            : _apMaternoController.text.trim(),
        fechaNacimiento: _fechaNacimiento?.toIso8601String(),
        idRegion: _idRegionSeleccionada,
      );

      // Subir foto si se seleccionó una
      if (fotoSeleccionada != null) {
        await FotoService().subirFotoPerfil(
          idUsuario: usuario.id,
          foto: fotoSeleccionada!,
        );
      }

      await _sessionService.guardarSesion(usuario);
      if (mounted) {
        // Toast de éxito antes de navegar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada correctamente'),
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

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: AppBackgrounds.register,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildAvatar(),
                  const SizedBox(height: 32),
                  _buildField(
                    label: 'CORREO ELECTRÓNICO',
                    child: AppInput(
                      label: 'Correo electrónico',
                      hint: 'Ingresa el correo electrónico',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      controller: _emailController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
                            .hasMatch(v.trim())) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'NOMBRE',
                    child: AppInput(
                      label: 'Tu nombre',
                      hint: 'Ingresa tu nombre',
                      prefixIcon: Icons.person_outlined,
                      textInputAction: TextInputAction.next,
                      controller: _nombreController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$')
                            .hasMatch(v.trim())) {
                          return 'Solo se permiten letras';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'APELLIDO PATERNO',
                    child: AppInput(
                      label: 'Primer apellido',
                      hint: 'Ingresa tu apellido paterno',
                      prefixIcon: Icons.person_outlined,
                      textInputAction: TextInputAction.next,
                      controller: _apPaternoController,
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty &&
                            !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$')
                                .hasMatch(v.trim())) {
                          return 'Solo se permiten letras';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'APELLIDO MATERNO',
                    child: AppInput(
                      label: 'Segundo apellido',
                      hint: 'Ingresa tu apellido materno',
                      prefixIcon: Icons.person_outlined,
                      textInputAction: TextInputAction.next,
                      controller: _apMaternoController,
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty &&
                            !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$')
                                .hasMatch(v.trim())) {
                          return 'Solo se permiten letras';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRegion(),
                  const SizedBox(height: 20),
                  _buildFechaNacimiento(),
                  const SizedBox(height: 20),
                  _buildField(
                    label: 'CONTRASEÑA',
                    child: AppInput(
                      label: 'Contraseña',
                      hint: 'Ingresa tu contraseña',
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      controller: _passController,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa una contraseña';
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
                      hint: 'Repite tu contraseña',
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      controller: _confirmPassController,
                      onSubmitted: (_) => _handleRegister(),
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
          'Crear Cuenta',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Únete a la comunidad de exploradores y descubre la biodiversidad que rodea a Chile!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppTheme.textGray, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return FotoPerfilPicker(
      fotoLocal: fotoSeleccionada,
      onTap: mostrarOpcionesFoto,
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

  Widget _buildFechaNacimiento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FECHA DE NACIMIENTO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _seleccionarFecha,
          child: Container(
            width: double.infinity,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightGray),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppTheme.textGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fechaFormateada,
                    style: TextStyle(
                      fontSize: 15,
                      color: _fechaNacimiento == null
                          ? AppTheme.textGray
                          : AppTheme.textDark,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textGray),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppButton(
          label: 'Crear Cuenta',
          isLoading: _isLoading,
          height: 56,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          width: double.infinity,
          onPressed: _handleRegister,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
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
      ],
    );
  }

  Widget _buildRegion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REGIÓN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGray),
          ),
          child: _regiones.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _idRegionSeleccionada,
                    hint: Text(
                      'Selecciona tu región',
                      style: TextStyle(color: AppTheme.textGray, fontSize: 15),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.textGray,
                    ),
                    isExpanded: true,
                    style: TextStyle(color: AppTheme.textDark, fontSize: 15),
                    items: _regiones
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _idRegionSeleccionada = v),
                  ),
                ),
        ),
      ],
    );
  }
}