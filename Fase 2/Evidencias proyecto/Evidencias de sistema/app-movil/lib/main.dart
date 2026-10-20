import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/navigation/app_router.dart';
import 'app/navigation/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/services/session_service.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final session  = SessionService();
  final expirada = await session.sesionExpirada(diasLimite: 30);
  final usuario  = expirada ? null : await session.obtenerSesion();

  if (expirada) await session.cerrarSesion();

  runApp(ChileDexApp(
    initialRoute: usuario != null ? AppRoutes.home : AppRoutes.login,
  ));

  FlutterNativeSplash.remove(); 
}

class ChileDexApp extends StatelessWidget {
  final String initialRoute;

  const ChileDexApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'ChileDex',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.theme,
      initialRoute:               initialRoute,
      onGenerateRoute:            generateRoute,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CL'),
        Locale('en', 'US'),
      ],
    );
  }
}