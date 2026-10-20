import 'package:flutter/material.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/perfil_model.dart';

/// Card de avistamiento para la sección "Últimos avistamientos" del perfil
class AvistamientoPerfilCard extends StatelessWidget {
  final AvistamientoPerfilModel avistamiento;

  const AvistamientoPerfilCard({super.key, required this.avistamiento});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.especieDetalle,
        arguments: avistamiento.especieId,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto de la especie
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: avistamiento.fotoUrl != null
                  ? Image.network(
                      avistamiento.fotoUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avistamiento.especieNombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    avistamiento.tiempoRelativo,
                    style: TextStyle(fontSize: 12, color: AppTheme.textGray),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.lightGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: AppTheme.lightGray,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: AppTheme.textGray,
      size: 22,
    ),
  );
}
