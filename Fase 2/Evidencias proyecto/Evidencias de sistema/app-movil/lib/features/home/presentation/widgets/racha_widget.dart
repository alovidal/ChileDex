import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Muestra la racha semanal con los días completados
class RachaWidget extends StatelessWidget {
  final int rachaActual;

  const RachaWidget({super.key, required this.rachaActual});

  static const _dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    // Día actual de la semana (1=lunes ... 7=domingo)
    final hoy         = DateTime.now().weekday;
    // Cuántos días de esta semana están cubiertos por la racha
    final diasActivos = rachaActual.clamp(0, 7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: ícono de fuego + texto de racha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '$rachaActual ${rachaActual == 1 ? 'Día' : 'Días'} seguidos',
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grilla de días
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              // i=0 → lunes, i=6 → domingo
              // Un día está activo si cae dentro de los diasActivos
              // contando hacia atrás desde hoy
              final diaPos    = i + 1; // 1=lunes
              final diasAtras = hoy - diaPos;
              final activo    = diasAtras >= 0 && diasAtras < diasActivos;

              return _buildDia(_dias[i], activo);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDia(String letra, bool activo) {
    return Column(
      children: [
        Text(letra,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            )),
        const SizedBox(height: 6),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: activo
                ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                : AppTheme.lightGray.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: activo ? AppTheme.primaryGreen : Colors.transparent,
            ),
          ),
          child: Center(
            child: activo
                ? const Text('', style: TextStyle(fontSize: 14))
                : const SizedBox(),
          ),
        ),
      ],
    );
  }
}