import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/especie_detalle_model.dart';
import '../../../../core/services/especie_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/app_background.dart';
import '../widgets/main_scaffold.dart';

class EspecieDetalleScreen extends StatefulWidget {
  final int idEspecie;

  const EspecieDetalleScreen({super.key, required this.idEspecie});

  @override
  State<EspecieDetalleScreen> createState() => _EspecieDetalleScreenState();
}

class _EspecieDetalleScreenState extends State<EspecieDetalleScreen> {
  final _especieService = EspecieService();
  final _sessionService = SessionService();

  EspecieDetalleModel? _especie;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    try {
      final usuario = await _sessionService.obtenerSesion();
      final detalle = await _especieService.obtenerDetalle(
        idEspecie: widget.idEspecie,
        idUsuario: usuario?.id,
      );
      if (mounted) {
        setState(() {
          _especie = detalle;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      child: AppBackground(
        imagePath: AppBackgrounds.detail,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _especie == null
            ? _buildError()
            : _buildContenido(),
      ),
    );
  }

  Widget _buildContenido() {
    return CustomScrollView(
      slivers: [
        _buildHeroSliver(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildNombreYEstado(),
              const SizedBox(height: 16),
              _buildTamanioYPeso(),
              const SizedBox(height: 24),
              if (_especie!.descripcion != null) ...[
                _buildDescripcion(),
                const SizedBox(height: 20),
              ],
              if (_especie!.habitats.isNotEmpty) ...[
                _buildHabitat(),
                const SizedBox(height: 24),
              ],
              _buildMisAvistamientos(),
              // Fuente de la fotografía de portada
              if (_especie!.fuentePortada != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.photo_camera_outlined,
                      size: 11,
                      color: AppTheme.textGray,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Foto: ${_especie!.fuentePortada!}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textCream,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  // ── Hero image con botón volver ────────────────────────────────────────────

  Widget _buildHeroSliver() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.35),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen principal
            _especie!.fotoHero != null
                ? Image.network(
                    _especie!.fotoHero!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _heroPlaceholder(),
                  )
                : _heroPlaceholder(),
            // Gradiente inferior para legibilidad
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                  stops: [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPlaceholder() => Container(
    color: AppTheme.lightGray,
    child: const Icon(
      Icons.image_not_supported_outlined,
      size: 64,
      color: AppTheme.textGray,
    ),
  );

  // ── Nombre, científico y estado ────────────────────────────────────────────

  Widget _buildNombreYEstado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre común + badge de categoría
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _especie!.nombreComun,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textCream,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildBadge(
              _formatCategoria(_especie!.categoria),
              AppTheme.accentOrange,
            ),
          ],
        ),
        // Nombre científico
        if (_especie!.nombreCientifico != null) ...[
          const SizedBox(height: 4),
          Text(
            _especie!.nombreCientifico!,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppTheme.textCream,
            ),
          ),
        ],
        // Estado de conservación
        if (_especie!.estadoConservacion != null) ...[
          const SizedBox(height: 8),
          _buildBadge(_especie!.estadoConservacion!, AppTheme.textGray),
        ],
      ],
    );
  }

  Widget _buildBadge(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── Tamaño y peso ──────────────────────────────────────────────────────────

  Widget _buildTamanioYPeso() {
    if (_especie!.tamanio == null && _especie!.peso == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildDatoFisico(
              'Tamaño',
              _especie!.tamanio ?? '—',
              Icons.straighten_outlined,
            ),
            VerticalDivider(width: 1, color: AppTheme.lightGray),
            _buildDatoFisico(
              'Peso',
              _especie!.peso ?? '—',
              Icons.monitor_weight_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatoFisico(String label, String valor, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.textGray),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: AppTheme.textGray),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Descripción ────────────────────────────────────────────────────────────

  Widget _buildDescripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('DESCRIPCIÓN'),
        const SizedBox(height: 8),
        Text(
          _especie!.descripcion!,
          style: TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.6),
        ),
      ],
    );
  }

  // ── Hábitat y distribución ─────────────────────────────────────────────────

  Widget _buildHabitat() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hábitat y Distribución',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Chips de hábitat
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _especie!.habitats
                .map(
                  (h) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      h.nombre,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          // Descripción del primer hábitat si existe
          if (_especie!.habitats.first.descripcion != null) ...[
            const SizedBox(height: 10),
            Text(
              _especie!.habitats.first.descripcion!,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGray,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mis avistamientos ──────────────────────────────────────────────────────

  Widget _buildMisAvistamientos() {
    final lista = _especie!.misAvistamientos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          'MIS AVISTAMIENTOS${lista.isNotEmpty ? ' (${lista.length})' : ''}',
        ),
        const SizedBox(height: 12),
        lista.isEmpty
            ? Text(
                'Aún no has avistado esta especie.',
                style: TextStyle(fontSize: 14, color: AppTheme.textGray),
              )
            : SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _buildAvistamientoChip(lista[i]),
                ),
              ),
      ],
    );
  }

  Widget _buildAvistamientoChip(AvistamientoDetalleModel a) {
    final ubicacion = (a.latitud != null && a.longitud != null)
        ? '${a.latitud!.toStringAsFixed(2)}, ${a.longitud!.toStringAsFixed(2)}'
        : 'Sin ubicación';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            a.fechaFormateada,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 11,
                color: AppTheme.textGray,
              ),
              const SizedBox(width: 3),
              Text(
                ubicacion,
                style: TextStyle(fontSize: 11, color: AppTheme.textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) => Text(
    label,
    style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppTheme.successGreen,
        letterSpacing: 0.8,
      )
  );

  Widget _buildError() => const Center(
    child: Text(
      'No se pudo cargar la especie.',
      style: TextStyle(color: AppTheme.textGray),
    ),
  );

  String _formatCategoria(String categoria) => switch (categoria) {
    'FLORA' => 'Flora',
    'MAMIFERO' => 'Mamífero',
    'AVE' => 'Ave',
    'REPTIL' => 'Reptil',
    'ANFIBIO' => 'Anfibio',
    'INSECTO' => 'Insecto',
    _ => categoria,
  };
}
