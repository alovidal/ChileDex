import 'package:chiledex/features/home/presentation/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/usuario_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_service.dart';

/// Modal de onboarding tipo carrusel para usuarios nuevos.
/// Se abre automáticamente al iniciar sesión o crear cuenta.
/// Al cerrarlo marca al usuario como no nuevo.
class OnboardingModal extends StatefulWidget {
  final UsuarioModel usuario;

  const OnboardingModal({super.key, required this.usuario});

  /// Muestra el modal si el usuario es nuevo.
  static Future<void> mostrarSiEsNuevo(
    BuildContext context,
    UsuarioModel usuario,
  ) async {
    if (!usuario.esNuevo) return;
    await showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (_) => OnboardingModal(usuario: usuario),
    );
  }

  @override
  State<OnboardingModal> createState() => _OnboardingModalState();
}

class _OnboardingModalState extends State<OnboardingModal> {
  final _pageController = PageController();
  int _paginaActual = 0;

  static const int _totalPaginas = 5;

  // ── Datos de cada slide ───────────────────────────────────────────────────
  static const List<_SlideData> _slides = [
    _SlideData(
      imagePath: 'lib/app/assets/images/acerca_de/banner_slide_1.webp',
      titulo: '¡Bienvenido/a a ChileDex!',
      descripcion: 'Cada salida es una oportunidad: descubre, identifica y aprende de la biodiversidad que nos rodea.',
      colorFondo: Color(0xFFE8F5E9),
      features: [
        _FeatureItem(texto: 'Descubre y explora especies nativas'),
        _FeatureItem(texto: 'Identifica especies a través de tu cámara'),
        _FeatureItem(texto: 'Obtén insignias por tu aprendizaje'),
      ],
    ),
    _SlideData(
      imagePath: 'lib/app/assets/images/acerca_de/banner_slide_2.webp',
      titulo: 'Fotografía y descubre',
      descripcion: 'Solo apunta tu cámara y ChileDex reconocerá la especie y te entregará todo lo que necesitas saber sobre ella.',
      colorFondo: Color(0xFFFFF3E0),
      features: [
        _FeatureItem(texto: 'Enfoca una especie y capturala'),
        _FeatureItem(texto: 'Reconocimiento inteligente'),
        _FeatureItem(texto: 'Aprende sobre lo que ves'),
      ],
    ),
    _SlideData(
      imagePath: 'lib/app/assets/images/acerca_de/banner_slide_3.webp',
      titulo: 'Todo un país por descubrir',
      descripcion: 'Encuentra las especies de flora y fauna que habitan cada región de Chile en un catálogo completo y organizado.',
      colorFondo: Color(0xFFE3F2FD),
      features: [
        _FeatureItem(texto: 'Regiones, zonas y hábitats'),
        _FeatureItem(texto: 'Filtra por aves, mamíferos, flora y más'),
        _FeatureItem(texto: 'Encuentra tu especie favorita'),
      ],
    ),
    _SlideData(
      imagePath: 'lib/app/assets/images/acerca_de/banner_slide_4.webp',
      titulo: 'Deja tu huella en el mapa',
      descripcion: 'Los avistamientos de toda la comunidad quedan marcados en el mapa, construyendo juntos un registro vivo de la biodiversidad.',
      colorFondo: Color(0xFFF3E5F5),
      features: [
        _FeatureItem(texto: 'Registro geolocalizado de avistamientos'),
        _FeatureItem(texto: 'Comunidad activa en todo el territorio'),
        _FeatureItem(texto: 'Historial de descubrimientos'),
      ],
    ),
    _SlideData(
      imagePath: 'lib/app/assets/images/acerca_de/banner_slide_5.webp',
      titulo: 'Colecciona logros y supérate',
      descripcion: 'Identifica especies, completa desafíos y desbloquea insignias que demuestran tu conocimiento de la biodiversidad.',
      colorFondo: Color(0xFFFCE4EC),
      features: [
        _FeatureItem(texto: 'Desafíos novedosos y temáticos'),
        _FeatureItem(texto: 'Niveles de explorador y rangos'),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _irASiguiente() {
    if (_paginaActual < _totalPaginas - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _cerrar();
    }
  }

  Future<void> _cerrar() async {
    // Marcar usuario como no nuevo
    try {
      await AuthService().marcarUsuarioVisto(widget.usuario.id);
      // Actualizar sesión local
      final sessionService = SessionService();
      final usuarioActual = await sessionService.obtenerSesion();
      if (usuarioActual != null) {
        // Guardar con esNuevo = false
        await sessionService.guardarSesion(
          UsuarioModel.fromJson({...usuarioActual.toJson(), 'es_nuevo': false}),
        );
      }
    } catch (_) {
      // Si falla, igual cerrar el modal
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        clipBehavior: Clip.antiAlias, // recorta los hijos al radio del borde
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Carrusel ──────────────────────────────────────────────
            SizedBox(
              height: 490,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _paginaActual = i),
                itemCount: _totalPaginas,
                itemBuilder: (_, i) => _buildSlide(_slides[i]),
              ),
            ),

            // ── Indicadores ───────────────────────────────────────────
            _buildIndicadores(),
            const SizedBox(height: 16),

            // ── Botones ───────────────────────────────────────────────
            _buildBotones(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Container(
      // Fondo gris claro para toda el área del slide
      color: AppTheme.lightGray,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Banner ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.asset(
              slide.imagePath,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, _) => Container(
                height: 200,
                color: slide.colorFondo,
                child: const Icon(
                  Icons.broken_image,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // ── Texto ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.titulo,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  slide.descripcion,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGray,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // ── Tarjeta de features ───────────────────────────────────────
          _buildFeaturesCard(slide.features),
        ],
      ),
    );
  }

  /// Tarjeta con tres puntos destacados del slide, separados por divisores.
  Widget _buildFeaturesCard(List<_FeatureItem> features) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.lightGray),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < features.length; i++) ...[
              _buildFeatureItem(features[i]),
              // Divisor entre items (no después del último)
              if (i < features.length - 1)
                Divider(height: 1, thickness: 1, color: AppTheme.lightGray),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(_FeatureItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.texto,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPaginas, (i) {
        final activo = i == _paginaActual;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: activo ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: activo ? AppTheme.primaryGreen : AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBotones() {
    final esUltimo = _paginaActual == _totalPaginas - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Botón Saltar
          Expanded(
            child: AppButton(
              label: 'Saltar',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              type: AppButtonType.ghost,
              foregroundColor: AppTheme.textGray,
              height: 48,
              onPressed: _cerrar,
            ),
          ),
          const SizedBox(width: 12),
          // Botón Siguiente / ¡Comenzar!
          Expanded(
            child: AppButton(
              label: esUltimo ? '¡Comenzar!' : 'Siguiente',
              type: AppButtonType.primary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 48,
              onPressed: _irASiguiente,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelos de datos ──────────────────────────────────────────────────────────

/// Datos de cada slide del onboarding.
class _SlideData {
  final String imagePath;
  final String titulo;
  final String descripcion;
  final Color colorFondo;
  final List<_FeatureItem> features;

  const _SlideData({
    required this.imagePath,
    required this.titulo,
    required this.descripcion,
    required this.colorFondo,
    required this.features,
  });
}

/// Un ítem de la tarjeta de features: o descriptivo.
class _FeatureItem {
  final String texto;

  const _FeatureItem({required this.texto});
}
