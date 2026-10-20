import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/perfil_model.dart';

class InsigniaCard extends StatelessWidget {
  final LogroModel logro;
  final bool obtenido; // ← nuevo parámetro

  const InsigniaCard({
    super.key,
    required this.logro,
    this.obtenido = true, // por defecto obtenida (para el perfil)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: obtenido
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Ícono — imagen con filtro gris si bloqueado
          _buildIcono(),
          const SizedBox(height: 6),
          Text(
            logro.nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: obtenido ? AppTheme.textDark : AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            obtenido ? logro.fechaFormateada : '- - -',
            style: TextStyle(fontSize: 10, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildIcono() {
    // Si tiene URL de imagen
    if (logro.icono != null && logro.icono!.startsWith('http')) {
      return ColorFiltered(
        // Filtro gris si bloqueado
        colorFilter: obtenido
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
          opacity: obtenido ? 1.0 : 0.4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              logro.icono!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _iconoFallback(),
            ),
          ),
        ),
      );
    }

    // Fallback: emoji o ícono por defecto
    return Opacity(
      opacity: obtenido ? 1.0 : 0.4,
      child: Text(
        obtenido ? (logro.icono ?? '🏅') : '🔒',
        style: const TextStyle(fontSize: 28),
      ),
    );
  }

  Widget _iconoFallback() => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: AppTheme.lightGray,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      obtenido ? Icons.emoji_events : Icons.lock_outline,
      color: obtenido ? AppTheme.primaryGreen : AppTheme.textGray,
      size: 24,
    ),
  );
}
