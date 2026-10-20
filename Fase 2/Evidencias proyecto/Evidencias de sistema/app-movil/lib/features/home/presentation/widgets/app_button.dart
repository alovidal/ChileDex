import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

// ============ Tipos de botones que se usaran ============
enum AppButtonType {
  primary, // Fondo naranja
  secondary, // Fondo verde
  outline, // Sin fondo pero con borde
  ghost, // Sin fondo ni borde
}

// ============ Boton reutilizable de la app ============
class AppButton extends StatelessWidget {
  // Atributos
  final String? label;
  final Widget? child;
  final String? route;
  final Object? routeArguments;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;

  const AppButton({
    super.key,
    this.label,
    this.child,
    this.route,
    this.routeArguments,
    this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.width,
    this.height,
    this.fontSize,
    this.fontWeight, 
  }) : assert(
         label != null || child != null,
         'AppButton requiere el label o el child',
       );

  // ============ Colores ============

  Color _resolveBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    return switch (type) {
      AppButtonType.primary => AppTheme.accentOrange,
      AppButtonType.secondary => AppTheme.lightGray,
      AppButtonType.outline => Colors.transparent,
      AppButtonType.ghost => Colors.transparent,
    };
  }

  Color _resolveForegroundColor() {
    if (foregroundColor != null) return foregroundColor!;
    return switch (type) {
      AppButtonType.primary => Colors.white,
      AppButtonType.secondary => AppTheme.textDark,
      AppButtonType.outline => AppTheme.primaryGreen,
      AppButtonType.ghost => AppTheme.textGray,
    };
  }

  BorderSide _resolveBorderSide() {
    return switch (type) {
      AppButtonType.outline => const BorderSide(
        color: AppTheme.lightGray,
        width: 1.5,
      ),
      _ => BorderSide.none,
    };
  }

  // ============ Acciones al presionar el boton ============

  VoidCallback? _resolveOnPressed(BuildContext context) {
    if (isLoading) return null;
    if (onPressed != null) return onPressed;
    if (route != null) {
      return () =>
          Navigator.pushNamed(context, route!, arguments: routeArguments);
    }
    return null;
  }

  // ============ Contenido interno del boton ============

  Widget _buildContent(Color fg) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(color: fg, strokeWidth: 2.5),
      );
    }

    if (child != null) return child!;

    // ── Text con fontSize y fontWeight opcionales ──────────────────────────
    final labelWidget = Text(
      label!,
      style: TextStyle(
        fontSize: fontSize, // null → hereda el default del tema
        fontWeight: fontWeight, // null → hereda el default del tema
      ),
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
          labelWidget, // ← usa el Text con estilo
        ],
      );
    }

    return labelWidget; // ← caso base
  }

  @override
  Widget build(BuildContext context) {
    final bg = _resolveBackgroundColor();
    final fg = _resolveForegroundColor();

    final button = ElevatedButton(
      onPressed: _resolveOnPressed(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation:
            (type == AppButtonType.outline || type == AppButtonType.ghost)
            ? 0
            : 2,
        minimumSize: width == null ? Size.zero : null,
        tapTargetSize: width == null
            ? MaterialTapTargetSize.shrinkWrap
            : MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: _resolveBorderSide(),
        ),
      ),
      child: _buildContent(fg),
    );

    if (width == null) {
      return IntrinsicWidth(
        child: SizedBox(height: height ?? 52, child: button),
      );
    }

    return SizedBox(width: width, height: height ?? 52, child: button);
  }
}
