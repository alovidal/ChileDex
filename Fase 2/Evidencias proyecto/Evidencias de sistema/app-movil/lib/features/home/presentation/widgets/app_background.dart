import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    required this.imagePath,
  });

  final Widget child;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(imagePath, fit: BoxFit.cover),
        child,
      ],
    );
  }
}

class AppBackgrounds {
  AppBackgrounds._();

  static const String login    = 'lib/app/assets/images/backgrounds/background_login.webp';
  static const String register = 'lib/app/assets/images/backgrounds/background_register.webp';
  static const String recover  = 'lib/app/assets/images/backgrounds/background_recuperar.webp';
  static const String home     = 'lib/app/assets/images/backgrounds/background_home.webp';
  static const String catalog  = 'lib/app/assets/images/backgrounds/background_catalogo.webp';
  static const String detail   = 'lib/app/assets/images/backgrounds/background_ficha.webp';
  static const String badges   = 'lib/app/assets/images/backgrounds/background_insignias.webp';
  static const String profile  = 'lib/app/assets/images/backgrounds/background_perfil.webp';
}