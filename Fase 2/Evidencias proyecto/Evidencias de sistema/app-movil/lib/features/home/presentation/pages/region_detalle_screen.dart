import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/region_model.dart';
import '../../../../core/services/especie_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/main_scaffold.dart';

class RegionDetalleScreen extends StatefulWidget {
  final int idRegion;

  const RegionDetalleScreen({super.key, required this.idRegion});

  @override
  State<RegionDetalleScreen> createState() => _RegionDetalleScreenState();
}

class _RegionDetalleScreenState extends State<RegionDetalleScreen> {
  final _service = EspecieService();

  RegionModel? _region;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarRegion();
  }

  Future<void> _cargarRegion() async {
    try {
      final region = await _service.obtenerRegion(widget.idRegion);
      if (mounted) {
        setState(() {
          _region = region;
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
      currentIndex: 0,
      child: AppBackground(
        imagePath: AppBackgrounds.detail,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _region == null
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
              _buildNombre(),
              const SizedBox(height: 4),
              if (_region!.descripcion != null) ...[
                const SizedBox(height: 24),
                _buildDescripcion(),
              ],
              const SizedBox(height: 16),
              _buildBotonDescubrir(), // ← nuevo
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonDescubrir() {
    return AppButton(
      label: 'Descubrir especies',
      type: AppButtonType.secondary,
      width: double.infinity,
      fontSize: 15,
      fontWeight: FontWeight.w900,
      height: 52,
      onPressed: () => Navigator.pushNamed(
        context,
        AppRoutes.catalogo,
        arguments: {
          'regionIds': [_region!.id],
        },
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

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
        background: _region!.imagenUrl != null
            ? Image.network(
                _region!.imagenUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _heroPlaceholder(),
              )
            : _heroPlaceholder(),
      ),
    );
  }

  Widget _heroPlaceholder() => Container(
    color: AppTheme.primaryGreen,
    child: const Center(
      child: Icon(Icons.map_outlined, size: 64, color: Colors.white54),
    ),
  );

  // ── Nombre ─────────────────────────────────────────────────────────────────

  Widget _buildNombre() {
    return Text(
      _region!.nombre,
      style: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppTheme.textCream,
      ),
    );
  }

  // ── Descripción ────────────────────────────────────────────────────────────

  Widget _buildDescripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIPCIÓN',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppTheme.successGreen,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _region!.descripcion!,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textDark,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildError() => const Center(
    child: Text(
      'No se pudo cargar la región.',
      style: TextStyle(color: AppTheme.textGray),
    ),
  );
}
