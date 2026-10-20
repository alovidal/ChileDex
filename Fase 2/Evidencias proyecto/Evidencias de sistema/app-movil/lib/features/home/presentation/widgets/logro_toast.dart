import 'package:flutter/material.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/progreso_model.dart';

/// Muestra un toast para cada logro desbloqueado.
/// Al tocarlo navega a InsigniasScreen.
class LogroToast {
  /// Mostrar un toast por cada logro nuevo.
  /// Se encola si hay varios para que no se superpongan.
  static Future<void> mostrar(
    BuildContext context,
    List<LogroNuevoModel> logros,
    int idUsuario,
  ) async {
    for (final logro in logros) {
      if (!context.mounted) return;
      await _mostrarUno(context, logro, idUsuario);
      // Pequeña pausa entre toasts si hay varios
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  static Future<void> _mostrarUno(
    BuildContext context,
    LogroNuevoModel logro,
    int idUsuario,
  ) async {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _LogroToastWidget(
        logro:      logro,
        onTap: () {
          entry.remove();
          Navigator.pushNamed(
            context,
            AppRoutes.insignias,
            arguments: idUsuario,
          );
        },
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Auto-cerrar después de 4 segundos
    await Future.delayed(const Duration(seconds: 4));
    if (entry.mounted) entry.remove();
  }
}

class _LogroToastWidget extends StatefulWidget {
  final LogroNuevoModel logro;
  final VoidCallback    onTap;
  final VoidCallback    onDismiss;

  const _LogroToastWidget({
    required this.logro,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_LogroToastWidget> createState() => _LogroToastWidgetState();
}

class _LogroToastWidgetState extends State<_LogroToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller, curve: Curves.easeOut));

    _fadeAnim = CurvedAnimation(
      parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16, right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap:              widget.onTap,
            onHorizontalDragEnd: (_) => widget.onDismiss(),
            child: Material(
              color:        Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:        AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Ícono del logro
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color:        Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: widget.logro.icono != null &&
                                widget.logro.icono!.startsWith('http')
                            ? Image.network(
                                widget.logro.icono!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.emoji_events,
                                        color: Colors.white, size: 24),
                              )
                            : Text(
                                widget.logro.icono ?? '🏅',
                                style: const TextStyle(fontSize: 24),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡Logro desbloqueado!',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.logro.nombre,
                            style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Flecha — indica que es tappable
                    const Icon(Icons.chevron_right,
                        color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}