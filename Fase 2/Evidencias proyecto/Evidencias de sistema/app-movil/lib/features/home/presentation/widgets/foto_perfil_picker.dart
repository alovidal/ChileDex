import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Widget reutilizable para seleccionar y mostrar foto de perfil.
/// Se usa tanto en RegisterScreen como en EditarPerfilScreen.
class FotoPerfilPicker extends StatelessWidget {
  final File?    fotoLocal;    // Foto recién seleccionada (aún no subida)
  final String?  fotoUrl;      // URL de foto ya guardada
  final VoidCallback onTap;    // Acción al tocar

  const FotoPerfilPicker({
    super.key,
    this.fotoLocal,
    this.fotoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.lightGray,
                // Prioridad: foto local > url guardada > ícono por defecto
                backgroundImage: fotoLocal != null
                    ? FileImage(fotoLocal!) as ImageProvider
                    : fotoUrl != null
                        ? NetworkImage(fotoUrl!)
                        : null,
                child: (fotoLocal == null && fotoUrl == null)
                    ? const Icon(Icons.person,
                        size: 48, color: AppTheme.textGray)
                    : null,
              ),
              // Badge cámara
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Seleccionar foto de perfil',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}