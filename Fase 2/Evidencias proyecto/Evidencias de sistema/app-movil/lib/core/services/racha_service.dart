import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/navigation/api_config.dart';
import '../models/progreso_model.dart';

class RachaService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// POST /racha/actualizar
  /// Llamar al abrir la app. Devuelve la racha actualizada
  /// y los logros nuevos si se desbloquearon.
  Future<RachaResultModel> actualizarRacha(int idUsuario) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/racha/actualizar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_usuario': idUsuario}),
    );

    if (response.statusCode == 200) {
      return RachaResultModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al actualizar racha');
  }
}
