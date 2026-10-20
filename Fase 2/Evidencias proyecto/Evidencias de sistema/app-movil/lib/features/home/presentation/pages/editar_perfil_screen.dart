import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/region_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/especie_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/models/usuario_model.dart';
import '../../presentation/widgets/app_button.dart';
import '../../presentation/widgets/app_input.dart';
import '../widgets/app_background.dart';
import '../widgets/main_scaffold.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _authService = AuthService();
  final _sessionService = SessionService();
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ────────────────────────────────────────────────────────────
  final _nombreController = TextEditingController();
  final _apPaternoController = TextEditingController();
  final _apMaternoController = TextEditingController();
  final _correoController = TextEditingController();

  // ── Estado ─────────────────────────────────────────────────────────────────
  UsuarioModel? _usuario;
  bool _isLoading = false;
  bool _cargando = true;
  DateTime? _fechaNacimiento;

  int? _idRegionSeleccionada;
  List<RegionModel> _regiones = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarRegiones();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apPaternoController.dispose();
    _apMaternoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _cargarRegiones() async {
    try {
      final regiones = await EspecieService().obtenerRegionesRegistro();
      if (mounted) setState(() => _regiones = regiones);
    } catch (_) {}
  }

  /// Carga los datos actuales del usuario en los campos
  Future<void> _cargarUsuario() async {
    final usuario = await _sessionService.obtenerSesion();
    if (usuario == null) return;

    setState(() {
      _usuario = usuario;
      _nombreController.text = usuario.nombre;
      _apPaternoController.text = usuario.apPaterno ?? '';
      _apMaternoController.text = usuario.apMaterno ?? '';
      _correoController.text = usuario.correo;
      _idRegionSeleccionada = usuario.idRegion;

      // Cargar fecha de nacimiento desde la sesión.
      // Se intenta el parseo completo primero; si falla (p.ej. el backend
      // devuelve un formato con timezone o sin separador T), se toman solo
      // los primeros 10 caracteres "YYYY-MM-DD" que Dart siempre reconoce.
      if (usuario.fechaNacimiento != null) {
        final raw = usuario.fechaNacimiento!;
        _fechaNacimiento = DateTime.tryParse(raw) ??
            DateTime.tryParse(raw.substring(0, raw.length.clamp(0, 10)));
      }

      _cargando = false;
    });
  }

  /// Abre el DatePicker para fecha de nacimiento
  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _fechaNacimiento ?? DateTime(hoy.year - 18, hoy.month, hoy.day),
      firstDate: DateTime(1900),
      lastDate: hoy,
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

  Future<void> _handleGuardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usuario == null) return;
    setState(() => _isLoading = true);

    try {
      final actualizado = await _authService.editarPerfil(
        idUsuario: _usuario!.id,
        nombre: _nombreController.text.trim(),
        apPaterno: _apPaternoController.text.trim().isEmpty
            ? null
            : _apPaternoController.text.trim(),
        apMaterno: _apMaternoController.text.trim().isEmpty
            ? null
            : _apMaternoController.text.trim(),
        correo: _correoController.text.trim(),
        fechaNacimiento: _fechaNacimiento?.toIso8601String(),
        idRegion: _idRegionSeleccionada,
      );

      // Actualizar la sesión guardada con los nuevos datos
      await _sessionService.guardarSesion(actualizado);

      if (mounted) {
        // Toast de éxito antes de volver
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
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
    return MainScaffold(
      currentIndex: 4,
      child: AppBackground(
        imagePath: AppBackgrounds.profile,
        child: SafeArea(
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatar(),
                              const SizedBox(height: 28),
                              _buildField(
                                label: 'NOMBRE',
                                child: AppInput(
                                  label: 'Nombre',
                                  prefixIcon: Icons.person_outlined,
                                  controller: _nombreController,
                                  textInputAction: TextInputAction.next,
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
                                  prefixIcon: Icons.person_outlined,
                                  controller: _apPaternoController,
                                  textInputAction: TextInputAction.next,
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
                                  prefixIcon: Icons.person_outlined,
                                  controller: _apMaternoController,
                                  textInputAction: TextInputAction.next,
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
                                label: 'CORREO ELECTRÓNICO',
                                child: AppInput(
                                  label: 'Correo electrónico',
                                  prefixIcon: Icons.email_outlined,
                                  controller: _correoController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
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
                              _buildFechaNacimiento(),
                              const SizedBox(height: 20),
                              _buildRegion(),
                              const SizedBox(height: 32),
                              AppButton(
                                label: 'Guardar Cambios',
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                width: double.infinity,
                                isLoading: _isLoading,
                                height: 56,
                                onPressed: _handleGuardar,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppTheme.textDark,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Editar Perfil',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.lightGray,
                backgroundImage: _usuario?.fotoPerfilUrl != null
                    ? NetworkImage(_usuario!.fotoPerfilUrl!)
                    : null,
                child: _usuario?.fotoPerfilUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 48,
                        color: AppTheme.textGray,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              // TODO: implementar selector de imagen
            },
            child: Text(
              'Cambiar foto de perfil',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
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
                            child: Text(
                              r.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
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