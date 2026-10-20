import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/evento_model.dart';
import '../../../../core/services/especie_service.dart';
import '../widgets/app_background.dart';
import '../widgets/main_scaffold.dart';

class EventoDetalleScreen extends StatefulWidget {
  final int idEvento;

  const EventoDetalleScreen({super.key, required this.idEvento});

  @override
  State<EventoDetalleScreen> createState() => _EventoDetalleScreenState();
}

class _EventoDetalleScreenState extends State<EventoDetalleScreen> {
  final _service = EspecieService();

  EventoModel? _evento;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEvento();
  }

  Future<void> _cargarEvento() async {
    try {
      final evento = await _service.obtenerEvento(widget.idEvento);
      if (mounted) {
        setState(() {
          _evento = evento;
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
            : _evento == null
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
              _buildNombreYCategoria(),
              const SizedBox(height: 16),
              _buildInfoCard(),
              if (_evento!.descripcion != null) ...[
                const SizedBox(height: 24),
                _buildDescripcion(),
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
        background: _evento!.imagenUrl != null
            ? Image.network(
                _evento!.imagenUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _heroPlaceholder(),
              )
            : _heroPlaceholder(),
      ),
    );
  }

  /// Placeholder con color según categoría cuando no hay imagen
  Widget _heroPlaceholder() {
    return Container(
      color: _colorCategoria(_evento!.categoria),
      child: Center(
        child: Text(
          _evento!.iconoCategoria,
          style: const TextStyle(fontSize: 64),
        ),
      ),
    );
  }

  // ── Nombre y categoría ─────────────────────────────────────────────────────

  Widget _buildNombreYCategoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _evento!.nombre,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textCream,
                ),
              ),
            ),
            if (_evento!.categoria != null) ...[
              const SizedBox(width: 8),
              _buildBadge(_evento!.categoria!, AppTheme.primaryGreen),
            ],
          ],
        ),
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── Card de información ────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        children: [
          // Fecha
          _buildInfoFila(
            Icons.calendar_today_outlined,
            'Fecha',
            _evento!.fechaFormateada,
          ),
          if (_evento!.lugar != null) ...[
            Divider(height: 1, color: AppTheme.lightGray),
            // Lugar
            _buildInfoFila(
              Icons.location_on_outlined,
              'Lugar',
              _evento!.lugar!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoFila(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: AppTheme.textGray),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
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
          _evento!.descripcion!,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textDark,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _colorCategoria(String? categoria) => switch (categoria) {
    'CONSERVACION' => AppTheme.primaryGreen,
    'EDUCACION' => const Color(0xFF2E7D9F),
    'AVISTAMIENTO' => AppTheme.accentOrange,
    _ => AppTheme.textGray,
  };

  Widget _buildError() => const Center(
    child: Text(
      'No se pudo cargar el evento.',
      style: TextStyle(color: AppTheme.textGray),
    ),
  );
}
