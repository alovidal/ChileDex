import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';

class SessionService {
  static const _kUsuario    = 'usuario_sesion';
  static const _kUltimaSync = 'ultima_sync';

  /// Guarda el usuario en local.
  Future<void> guardarSesion(UsuarioModel usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsuario, jsonEncode(usuario.toJson()));
    // Guardar timestamp de la última sincronización
    await prefs.setString(
      _kUltimaSync,
      DateTime.now().toIso8601String(),
    );
  }

  /// Recupera el usuario guardado.
  /// Devuelve null si no hay sesión o si los datos están corruptos.
  Future<UsuarioModel?> obtenerSesion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = prefs.getString(_kUsuario);
      if (json == null) return null;
      return UsuarioModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      // Si los datos están corruptos, limpiar y pedir login de nuevo
      await cerrarSesion();
      return null;
    }
  }

  /// Elimina la sesión guardada (logout).
  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsuario);
    await prefs.remove(_kUltimaSync);
  }

  /// Verifica si la sesión local tiene más de X días sin sincronizar.
  /// Útil para forzar re-login después de mucho tiempo inactivo.
  Future<bool> sesionExpirada({int diasLimite = 30}) async {
    final prefs       = await SharedPreferences.getInstance();
    final ultimaSync  = prefs.getString(_kUltimaSync);
    if (ultimaSync == null) return true;

    final fecha = DateTime.tryParse(ultimaSync);
    if (fecha == null) return true;

    return DateTime.now().difference(fecha).inDays > diasLimite;
  }
}