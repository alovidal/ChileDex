import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/logro_completo_model.dart';
import '../../../../core/services/perfil_service.dart';
import '../widgets/app_background.dart';
import '../widgets/main_scaffold.dart';

class InsigniasScreen extends StatefulWidget {
  final int idUsuario;

  const InsigniasScreen({super.key, required this.idUsuario});

  @override
  State<InsigniasScreen> createState() => _InsigniasScreenState();
}

class _InsigniasScreenState extends State<InsigniasScreen> {
  final _service = PerfilService();

  List<LogroCompletoModel> _logros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarLogros();
  }

  Future<void> _cargarLogros() async {
    try {
      final data = await _service.obtenerTodosLogros(widget.idUsuario);
      if (mounted) {
        setState(() {
          _logros = data;
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
        imagePath: AppBackgrounds.badges,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const Divider(height: 1),
              Expanded(child: _buildContenido()),
            ],
          ),
        ),
      ),
    );
  }

  /// AppBar manual con botón de volver
  Widget _buildHeader(BuildContext context) {
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
            'Insignias de Campo',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
            ),
          ),
          const Spacer(),
          // Contador obtenidas / total
          Text(
            '${_logros.where((l) => l.obtenido).length}/${_logros.length}',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_logros.isEmpty) {
      return Center(
        child: Text(
          'No hay insignias disponibles.',
          style: TextStyle(color: AppTheme.textGray),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95, // Ligeramente más alto que ancho
      ),
      itemCount: _logros.length,
      itemBuilder: (_, i) => _InsigniaGridCard(logro: _logros[i]),
    );
  }
}

/// Card de insignia para el grid — maneja estado obtenida/bloqueada
class _InsigniaGridCard extends StatelessWidget {
  final LogroCompletoModel logro;

  const _InsigniaGridCard({required this.logro});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: logro.obtenido ? () => _mostrarDetalle(context) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: logro.obtenido
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : AppTheme.lightGray,
              width: logro.obtenido ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcono(),
              const SizedBox(height: 10),
              Text(
                logro.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: logro.obtenido ? AppTheme.textDark : AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                logro.fechaFormateada,
                style: TextStyle(
                  fontSize: 11,
                  color: logro.obtenido
                      ? AppTheme.textGray
                      : AppTheme.textGray.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcono() {
    final esUrl = logro.icono != null && logro.icono!.startsWith('http');

    if (esUrl) {
      return ColorFiltered(
        colorFilter: logro.obtenido
            ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
            : const ColorFilter.matrix([
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
        child: Opacity(
          opacity: logro.obtenido ? 1.0 : 0.35,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              logro.icono!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: logro.obtenido ? 1.0 : 0.35,
      child: Text(
        logro.obtenido ? (logro.icono ?? '🏅') : '🔒',
        style: const TextStyle(fontSize: 36),
      ),
    );
  }

  Widget _fallback() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: AppTheme.lightGray,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(
      logro.obtenido ? Icons.emoji_events : Icons.lock_outline,
      color: logro.obtenido ? AppTheme.primaryGreen : AppTheme.textGray,
      size: 28,
    ),
  );

  void _mostrarDetalle(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono grande en el detalle
            if (logro.icono != null && logro.icono!.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  logro.icono!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text(logro.icono ?? '🏅', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              logro.nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (logro.descripcion != null) ...[
              const SizedBox(height: 8),
              Text(
                logro.descripcion!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGray,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Obtenida el ${logro.fechaFormateada}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
