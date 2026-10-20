import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/especie_model.dart';
import '../../../../core/models/evento_model.dart';
import '../../../../core/models/region_model.dart';
import '../../../../core/services/especie_service.dart';
import '../../../../core/services/racha_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/app_background.dart';
import '../widgets/logro_toast.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/onboarding_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _especieService = EspecieService();
  final _sessionService = SessionService();
  final _rachaService = RachaService();

  // Estado de carga y datos
  bool _isLoading = true;
  String _nombreUsuario = '';
  List<EspecieModel> _especies = [];
  List<RegionModel> _regiones = [];
  List<EventoModel> _eventos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _actualizarRacha();
      // Onboarding si es nuevo (ya existía)
      final usuario = await _sessionService.obtenerSesion();
      if (usuario != null && mounted) {
        await OnboardingModal.mostrarSiEsNuevo(context, usuario);
      }
    });
  }

  Future<void> _actualizarRacha() async {
    try {
      final usuario = await _sessionService.obtenerSesion();
      if (usuario == null) return;

      final resultado = await _rachaService.actualizarRacha(usuario.id);

      // Si subió la racha, mostrar snackbar
      if (mounted && resultado.subio) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  '¡Racha de ${resultado.rachaActual} días!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentOrange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      // Si se reseteó, avisar
      if (mounted && resultado.reseteo) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Text('', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  'Tu racha se reinició. ¡Vuelve mañana!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.textGray,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      // Si desbloqueó logros de racha, mostrar toast
      if (mounted && resultado.logrosNuevos.isNotEmpty) {
        await LogroToast.mostrar(context, resultado.logrosNuevos, usuario.id);
      }
    } catch (_) {
      // Silencioso — no interrumpir la app si falla
    }
  }

  /// Carga en paralelo el usuario, especies y regiones
  Future<void> _cargarDatos() async {
    try {
      final results = await Future.wait([
        _sessionService.obtenerSesion(),
        _especieService.obtenerDestacadas(),
        _especieService.obtenerRegiones(),
        _especieService.obtenerEventos(),
      ]);

      if (mounted) {
        setState(() {
          final usuario = results[0];
          _nombreUsuario = usuario != null
              ? (usuario as dynamic).nombre as String
              : 'explorador/a';
          _especies = results[1] as List<EspecieModel>;
          _regiones = results[2] as List<RegionModel>;
          _eventos = results[3] as List<EventoModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Abre el onboarding manualmente sin importar si el usuario es nuevo
  Future<void> _mostrarOnboarding() async {
    final usuario = await _sessionService.obtenerSesion();
    if (usuario != null && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => OnboardingModal(usuario: usuario),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: AppBackground(
        imagePath: AppBackgrounds.home,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  onRefresh: _cargarDatos,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Fila bienvenida + botón ayuda ────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildBienvenida()),
                            // ── Botón ? con fondo blanco y sombra ──────
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.lightGray,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                tooltip: 'Guía de la app',
                                onPressed: _mostrarOnboarding,
                                icon: const Icon(Icons.help_outline_rounded),
                                color: AppTheme.textGray,
                                iconSize: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _buildSeccionEspecies(),
                        const SizedBox(height: 28),
                        _buildSeccionRegiones(),
                        const SizedBox(height: 28),
                        _buildSeccionEventos(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// Saludo personalizado con el nombre del usuario
  Widget _buildBienvenida() {
    return Text(
      '¡Bienvenido/a, $_nombreUsuario!',
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppTheme.successGreen,
        letterSpacing: 0.7,
      ),
    );
  }

  // ── Especies destacadas ──────────────────────────────────────────────────

  Widget _buildSeccionEspecies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('ESPECIES DESTACADAS'),
        const SizedBox(height: 16),
        _especies.isEmpty
            ? const Text(
                'Sin especies disponibles',
                style: TextStyle(color: AppTheme.textCream),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _especies.map((e) {
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.especieDetalle,
                      arguments: e.id,
                    ),
                    child: _buildEspecieCard(e),
                  );
                }).toList(),
              ),
      ],
    );
  }

  /// Tarjeta circular de especie destacada
  Widget _buildEspecieCard(EspecieModel especie) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          // Foto circular con sombra
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.lightGray,
              backgroundImage: especie.fotoPortada != null
                  ? NetworkImage(especie.fotoPortada!)
                  : null,
              child: especie.fotoPortada == null
                  ? const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTheme.textGray,
                      size: 28,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // Nombre común
          Text(
            especie.nombreComun,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          // Categoría
          Text(
            _formatCategoria(especie.categoria),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }

  /// Convierte la categoría del backend a texto legible
  String _formatCategoria(String categoria) {
    return switch (categoria) {
      'FLORA' => 'Flora',
      'MAMIFERO' => 'Mamífero',
      'AVE' => 'Ave',
      'REPTIL' => 'Reptil',
      'ANFIBIO' => 'Anfibio',
      'INSECTO' => 'Insecto',
      _ => categoria,
    };
  }

  // ── Regiones ─────────────────────────────────────────────────────────────

  Widget _buildSeccionRegiones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('REGIONES'),
        const SizedBox(height: 16),
        _regiones.isEmpty
            ? const Text(
                'Sin regiones disponibles',
                style: TextStyle(color: AppTheme.textGray),
              )
            : Column(
                children: _regiones.map((r) => _buildRegionCard(r)).toList(),
              ),
      ],
    );
  }

  /// Tarjeta de región con imagen de fondo y nombre superpuesto
  Widget _buildRegionCard(RegionModel region) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.regionDetalle,
        arguments: region.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppTheme.lightGray,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          image: region.imagenUrl != null
              ? DecorationImage(
                  image: NetworkImage(region.imagenUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        // Overlay con gradient de la guía de estilos
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppTheme.overlayGradient,
              stops: const [0.3, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              region.nombre,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Etiqueta de sección reutilizable (verde, mayúsculas, bold)
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppTheme.successGreen,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSeccionEventos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('EVENTOS'),
        const SizedBox(height: 16),
        _eventos.isEmpty
            ? Text(
                'No hay eventos próximos.',
                style: TextStyle(color: AppTheme.textGray, fontSize: 13),
              )
            : Column(
                children: _eventos.map((e) => _buildEventoCard(e)).toList(),
              ),
      ],
    );
  }

  /// Card de evento — mismo estilo visual que las regiones
  Widget _buildEventoCard(EventoModel evento) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.eventoDetalle,
        arguments: evento.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _colorCategoria(evento.categoria),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          // Imagen de fondo si existe — igual que las regiones
          image: evento.imagenUrl != null
              ? DecorationImage(
                  image: NetworkImage(evento.imagenUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.10),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evento.nombre,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  evento.fechaFormateada,
                  if (evento.lugar != null) evento.lugar!,
                ].join(' · '),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Color de fondo según categoría (cuando no hay imagen de fondo)
  Color _colorCategoria(String? categoria) {
    return switch (categoria) {
      'CONSERVACION' => AppTheme.primaryGreen,
      'EDUCACION' => AppTheme.primaryGreen, // Azul
      'AVISTAMIENTO' => AppTheme.primaryGreen,
      _ => AppTheme.textGray,
    };
  }
}
