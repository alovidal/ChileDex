import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/perfil_model.dart';
import '../../../../core/models/progreso_model.dart';
import '../../../../core/services/perfil_service.dart';
import '../../../../core/services/progreso_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/avistamiento_perfil_card.dart';
import '../widgets/insignia_card.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/racha_widget.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _perfilService = PerfilService();
  final _sessionService = SessionService();

  PerfilModel? _perfil;
  ProgresoEspeciesModel? _progreso; // ← declarar aquí
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final usuario = await _sessionService.obtenerSesion();
      if (usuario == null) return;

      // Cargar perfil y progreso en paralelo
      final results = await Future.wait([
        _perfilService.obtenerPerfil(usuario.id),
        ProgresoService().obtenerProgreso(usuario.id),
      ]);

      if (mounted) {
        setState(() {
          _perfil = results[0] as PerfilModel;
          _progreso = results[1] as ProgresoEspeciesModel;
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
      currentIndex: 4,
      child: AppBackground(
        imagePath: AppBackgrounds.profile,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _perfil == null
            ? _buildError()
            : RefreshIndicator(
                color: AppTheme.primaryGreen,
                onRefresh: _cargarPerfil,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 20),
                      _buildContadores(),
                      const SizedBox(height: 28),
                      _buildRacha(),
                      const SizedBox(height: 28),
                      _buildInsignias(),
                      const SizedBox(height: 28),
                      _buildUltimosAvistamientos(),
                      const SizedBox(height: 32),
                      _buildCerrarSesion(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // ── Sombra sobre la foto de perfil ──────────────────────
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.lightGray,
                  backgroundImage: _perfil!.fotoPerfilUrl != null
                      ? NetworkImage(_perfil!.fotoPerfilUrl!)
                      : null,
                  child: _perfil!.fotoPerfilUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 48,
                          color: AppTheme.textGray,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.editarPerfil,
                  ).then((_) => _cargarPerfil()),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _perfil!.nombreCompleto,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textCream,
            ),
          ),
          const SizedBox(height: 4),
          if (_perfil!.regionNombre != null)
            Text(
              _perfil!.regionNombre!,
              style: TextStyle(fontSize: 15, color: AppTheme.textCream),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _nivelNaturalista(_progreso?.totalVistas ?? 0),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _nivelNaturalista(int especiesVistas) {
    if (especiesVistas >= 100) return 'Naturalista Experto';
    if (especiesVistas >= 50) return 'Naturalista Avanzado';
    if (especiesVistas >= 20) return 'Naturalista Intermedio';
    return 'Naturalista Principiante';
  }

  Widget _buildContadores() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Especies vistas / total app
          Expanded(
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_progreso?.totalVistas ?? 0}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${_progreso?.totalApp ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Especies descubiertas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.lightGray),
          // Logros
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_perfil?.totalLogros ?? 0}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Insignias',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRacha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('RACHA DE AVISTAMIENTOS'),
        const SizedBox(height: 12),
        RachaWidget(rachaActual: _perfil!.rachaActual),
      ],
    );
  }

  Widget _buildInsignias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('INSIGNIAS DE CAMPO'),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.insignias,
                arguments: _perfil!.idUsuario,
              ),
              child: Text(
                'Ver más >',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _perfil!.logros.isEmpty
            ? Text(
                'Aún no tienes insignias.',
                style: TextStyle(color: AppTheme.textGray, fontSize: 14),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _perfil!.logros
                      .map(
                        (l) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InsigniaCard(logro: l, obtenido: true),
                        ),
                      )
                      .toList(),
                ),
              ),
      ],
    );
  }

  Widget _buildUltimosAvistamientos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('ÚLTIMOS AVISTAMIENTOS'),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.catalogo,
                arguments: {
                  'soloVistas': true,
                  'idUsuario': _perfil!.idUsuario,
                },
              ),
              child: Text(
                'Ver >',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _perfil!.ultimosAvistamientos.isEmpty
            ? Text(
                'Aún no tienes avistamientos.',
                style: TextStyle(color: AppTheme.textGray, fontSize: 14),
              )
            : Column(
                children: _perfil!.ultimosAvistamientos
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AvistamientoPerfilCard(avistamiento: a),
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }

  Future<void> _handleCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: AppTheme.textGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    await _sessionService.cerrarSesion();
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Widget _buildCerrarSesion() {
    return AppButton(
      label: 'Cerrar sesión',
      type: AppButtonType.primary,
      height: 56,
      width: double.infinity,
      fontSize: 15,
      fontWeight: FontWeight.w900,
      onPressed: _handleCerrarSesion,
    );
  }

  Widget _buildSectionLabel(String label) => Text(
    label,
    style: GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w900,
      color: AppTheme.successGreen,
      letterSpacing: 0.8,
    ),
  );

  Widget _buildError() => const Center(
    child: Text(
      'No se pudo cargar el perfil.',
      style: TextStyle(color: AppTheme.textGray),
    ),
  );
}
