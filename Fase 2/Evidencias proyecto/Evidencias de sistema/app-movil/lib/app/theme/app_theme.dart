import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Paleta Salvia y Niebla ─────────────────────────────────────────────────
  static const Color primaryGreen     = Color(0xFF27533B); // Verde Botánico — acción primaria
  static const Color accentOrange     = Color(0xFFC25B34); // Terracota Arcilla — acento cálido
  static const Color accentGold       = Color(0xFFC8A86B); // Ocre/Trigo — insignias y logros
  static const Color backgroundCream  = Color(0xFFE8ECE9); // Gris Salvia Niebla — fondo base
  static const Color cardWhite        = Color(0xFFFFFFFF); // Blanco Puro — cards e inputs
  static const Color textDark         = Color(0xFF1C3829); // Verde Bosque Profundo — títulos
  static const Color textGray         = Color(0xFF4D6357); // Salvia Medio — texto secundario
  static const Color lightGray        = Color(0xFFD5DCD7); // Gris Salvia Claro — bordes
  static const Color successGreen     = Color(0xFF27533B); // mismo que primary para consistencia
  static const Color textCream        = Color(0xFF633F32); // Color crema

  // ── Sombra estándar ────────────────────────────────────────────────────────
  /// Usar en BoxDecoration de cards y contenedores elevados.
  /// BoxShadow(color: AppTheme.shadowColor, blurRadius: 16, offset: Offset(0, 4))
  static const Color shadowColor      = Color(0x0F1C3829); // rgba(28,56,41,0.06)

  // ── Overlay para tarjetas con foto (regiones y eventos) ───────────────────
  /// Usar como ColorFilter o gradient encima de imágenes.
  static const List<Color> overlayGradient = [
    Color(0x0D000000), // rgba(0,0,0,0.05) — top
    Color(0xBF14231B), // rgba(20,35,27,0.75) — bottom
  ];

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: backgroundCream,

    colorScheme: ColorScheme.fromSeed(
      seedColor:   primaryGreen,
      primary:     primaryGreen,
      secondary:   accentOrange,
      surface:     cardWhite,
    ),

    textTheme: GoogleFonts.outfitTextTheme(),

    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundCream,
      foregroundColor: textDark,
      elevation:       0,
      centerTitle:     true,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,   // ← era accentOrange, ahora verde botánico
        foregroundColor: Colors.white,
        minimumSize:     const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled:    true,
      fillColor: cardWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DCD7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DCD7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
    ),
  );
}