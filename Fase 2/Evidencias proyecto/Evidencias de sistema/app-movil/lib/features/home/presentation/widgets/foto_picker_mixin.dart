import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Mixin que agrega la lógica de selección de foto a cualquier State.
/// Se usa en RegisterScreen y EditarPerfilScreen.
mixin FotoPickerMixin<T extends StatefulWidget> on State<T> {
  File? fotoSeleccionada;
  final _picker = ImagePicker();

  /// Muestra bottom sheet para elegir entre cámara o galería
  void mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarFoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source:    source,
      maxWidth:  800,
      maxHeight: 800,
      imageQuality: 85,  // Comprimir para no subir imágenes muy pesadas
    );
    if (picked != null && mounted) {
      setState(() => fotoSeleccionada = File(picked.path));
    }
  }
}