import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/navigation/api_config.dart';
import '../models/usuario_model.dart';

class AuthService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// POST /usuarios/login
  Future<UsuarioModel> login({
    required String correo,
    required String contrasena,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/usuarios/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Error al iniciar sesión');
  }

  /// POST /usuarios/registro
  Future<UsuarioModel> registrar({
    required String correo,
    required String contrasena,
    required String nombre,
    String? apPaterno,
    String? apMaterno,
    String? fechaNacimiento,
    int? idRegion,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/usuarios/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'contrasena': contrasena,
        'nombre': nombre,
        'ap_paterno': apPaterno,
        'ap_materno': apMaterno,
        'fecha_nacimiento': fechaNacimiento,
        if (idRegion != null) 'id_region': idRegion,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return UsuarioModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    // Proteger contra body vacío o HTML
    if (response.body.isEmpty) {
      throw Exception('Error del servidor');
    }
    Map<String, dynamic>? error;
    try {
      error = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // body no es JSON (es HTML de 502, etc.)
    }
    throw Exception(
      error?['detail'] ?? 'Error del servidor: ${response.statusCode}',
    );
  }

  Future<void> buscarCorreo({required String correo}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/usuarios/recuperar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al buscar el correo');
    }
  }

  /// POST /usuarios/restablecer — actualiza la contraseña
  Future<void> restablecerContrasena({
    required String correo,
    required String nuevaContrasena,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/usuarios/restablecer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'nueva_contrasena': nuevaContrasena,
        'token': token,
      }),
    );
    if (response.statusCode != 200) {
      if (response.body.isEmpty) throw Exception('Error del servidor');
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al restablecer la contraseña');
    }
  }

  /// PUT /usuarios/{id} — actualiza los datos del perfil
  Future<UsuarioModel> editarPerfil({
    required int idUsuario,
    String? nombre,
    String? apPaterno,
    String? apMaterno,
    String? correo,
    String? fechaNacimiento,
    int? idRegion,
  }) async {
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (apPaterno != null) body['ap_paterno'] = apPaterno;
    if (apMaterno != null) body['ap_materno'] = apMaterno;
    if (correo != null) body['correo'] = correo;
    if (fechaNacimiento != null) body['fecha_nacimiento'] = fechaNacimiento;
    if (idRegion != null) body['id_region'] = idRegion;

    final response = await http.put(
      Uri.parse('$_baseUrl/usuarios/$idUsuario'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Error al actualizar el perfil');
  }

  Future<void> marcarUsuarioVisto(int idUsuario) async {
    await http.post(
      Uri.parse('$_baseUrl/usuarios/$idUsuario/marcar-visto'),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
