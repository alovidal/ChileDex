import 'package:flutter/material.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/especie_model.dart';

class EspecieCard extends StatelessWidget {
  final EspecieCatalogoModel especie;

  const EspecieCard({super.key, required this.especie});

  /// Color del badge según el estado de conservación
  Color _badgeColor(String? estado) {
    return switch (estado?.toLowerCase()) {
      'en peligro' => Colors.red.shade700,
      'vulnerable' => Colors.orange.shade700,
      'común' => Colors.green.shade600,
      _ => AppTheme.textGray,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.especieDetalle,
            arguments: especie.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Foto de la especie
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: especie.fotoUrl != null
                      ? Image.network(
                          especie.fotoUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre común + badge estado
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              especie.nombreComun,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (especie.estadoConservacion != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _badgeColor(especie.estadoConservacion)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                especie.estadoConservacion!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _badgeColor(
                                    especie.estadoConservacion,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Nombre científico
                      if (especie.nombreCientifico != null)
                        Text(
                          especie.nombreCientifico!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      // Hábitat
                      if (especie.habitatNombre != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppTheme.textGray,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              especie.habitatNombre!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.lightGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppTheme.lightGray,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.textGray,
        size: 28,
      ),
    );
  }
}
