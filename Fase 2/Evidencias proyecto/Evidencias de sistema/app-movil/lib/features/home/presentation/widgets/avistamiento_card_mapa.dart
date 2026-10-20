import 'package:flutter/material.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/avistamiento_model.dart';

/// Card compacta de avistamiento para el bottom sheet del mapa
class AvistamientoCardMapa extends StatelessWidget {
  final AvistamientoMapaModel avistamiento;

  const AvistamientoCardMapa({super.key, required this.avistamiento});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.especieDetalle,
        arguments: avistamiento.especieId,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Foto de la especie
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: avistamiento.especieFotoPortada != null
                  ? Image.network(
                      avistamiento.especieFotoPortada!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            // Nombre + tiempo
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
                  const SizedBox(height: 3),
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
    width: 52,
    height: 52,
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
