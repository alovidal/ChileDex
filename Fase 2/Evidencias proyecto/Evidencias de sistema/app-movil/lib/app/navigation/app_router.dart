import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/catalogo_screen.dart';
import '../../features/home/presentation/pages/editar_perfil_screen.dart';
import '../../features/home/presentation/pages/especie_detalle_screen.dart';
import '../../features/home/presentation/pages/evento_detalle_screen.dart';
import '../../features/home/presentation/pages/forgot_password_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/home/presentation/pages/identificacion_screen.dart';
import '../../features/home/presentation/pages/insignias_screen.dart';
import '../../features/home/presentation/pages/login_screen.dart';
import '../../features/home/presentation/pages/mapa_screen.dart';
import '../../features/home/presentation/pages/perfil_screen.dart';
import '../../features/home/presentation/pages/region_detalle_screen.dart';
import '../../features/home/presentation/pages/register_screen.dart';
import '../../features/home/presentation/pages/reset_password_screen.dart';
import '../../features/home/presentation/pages/verificar_token_screen.dart';
import 'app_routes.dart';


// Genera la pantalla correspondiente a cada ruta nombrada.
// Se registra en MaterialApp como onGenerateRoute.
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());

    case AppRoutes.register:
      return MaterialPageRoute(builder: (_) => const RegisterScreen());

    case AppRoutes.forgotPassword:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

    case AppRoutes.resetPassword:
      final args = settings.arguments as Map<String, String>;
      return MaterialPageRoute(
        builder: (_) =>
            ResetPasswordScreen(correo: args['correo']!, token: args['token']!),
      );

    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const HomeScreen());

    case AppRoutes.catalogo:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CatalogoScreen(
          regionIds: args?['regionIds'] as List<int>?,
          soloVistas: args?['soloVistas'] as bool?,
          idUsuario: args?['idUsuario'] as int?,
        ),
      );

    case AppRoutes.mapa:
      return MaterialPageRoute(builder: (_) => const MapaScreen());

    case AppRoutes.perfil:
      return MaterialPageRoute(builder: (_) => const PerfilScreen());

    case AppRoutes.insignias:
      final idUsuario = settings.arguments as int;
      return MaterialPageRoute(
        builder: (_) => InsigniasScreen(idUsuario: idUsuario),
      );

    case AppRoutes.especieDetalle:
      final id = settings.arguments as int;
      return MaterialPageRoute(
        builder: (_) => EspecieDetalleScreen(idEspecie: id),
      );

    case AppRoutes.editarPerfil:
      return MaterialPageRoute(builder: (_) => const EditarPerfilScreen());

    case AppRoutes.camara:
      return MaterialPageRoute(builder: (_) => const IdentificacionScreen());

    case AppRoutes.eventoDetalle:
      final id = settings.arguments as int;
      return MaterialPageRoute(
        builder: (_) => EventoDetalleScreen(idEvento: id),
      );

    case AppRoutes.regionDetalle:
      final id = settings.arguments as int;
      return MaterialPageRoute(
        builder: (_) => RegionDetalleScreen(idRegion: id),
      );

    case AppRoutes.verificarToken:
      final correo = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => VerificarTokenScreen(correo: correo),
      );

    default:
      // Ruta no encontrada — pantalla de error genérica
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('Ruta "${settings.name}" no encontrada')),
        ),
      );
  }
}
