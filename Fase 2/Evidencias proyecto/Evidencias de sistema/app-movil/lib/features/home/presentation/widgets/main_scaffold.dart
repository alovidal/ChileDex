import 'package:flutter/material.dart';
import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';

/// Scaffold compartido para todas las pantallas internas de la app.
/// 
/// Envuelve el contenido de cada pantalla con el BottomNavigationBar
/// para que aparezca en todas las vistas sin repetir código.
/// 
/// Uso:
///   MainScaffold(
///     currentIndex: 0,       // índice de la pestaña activa
///     child: HomeScreen(),   // contenido de la pantalla
///   )
class MainScaffold extends StatelessWidget {
  /// Contenido de la pantalla actual
  final Widget child;

  /// Índice de la pestaña activa (0=Inicio, 1=Catálogo, 2=Cámara, 3=Mapa, 4=Perfil)
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  /// Rutas asociadas a cada pestaña del BottomNav
  static const List<String> _routes = [
    AppRoutes.home,
    AppRoutes.catalogo,
    AppRoutes.camara,
    AppRoutes.mapa,
    AppRoutes.perfil,
  ];

  void _onTabTapped(BuildContext context, int index) {
    // No navegar si ya estamos en esa pestaña
    if (index == currentIndex) return;
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_outlined,      Icons.home,             'Inicio'),
              _buildNavItem(context, 1, Icons.menu_book_outlined,  Icons.menu_book,        'Catálogo'),
              _buildCameraButton(context),
              _buildNavItem(context, 3, Icons.map_outlined,        Icons.map,              'Mapa'),
              _buildNavItem(context, 4, Icons.person_outlined,     Icons.person,           'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  /// Ítem estándar del BottomNav (ícono + label)
  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData iconOutlined,
    IconData iconFilled,
    String label,
  ) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconFilled : iconOutlined,
              color: isActive ? AppTheme.primaryGreen : AppTheme.textGray,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppTheme.primaryGreen : AppTheme.textGray,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón central de cámara — círculo naranja resaltado
  Widget _buildCameraButton(BuildContext context) {
    final isActive = currentIndex == 2;

    return GestureDetector(
      onTap: () => _onTabTapped(context, 2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentOrange,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentOrange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isActive ? Icons.camera_alt : Icons.camera_alt_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}