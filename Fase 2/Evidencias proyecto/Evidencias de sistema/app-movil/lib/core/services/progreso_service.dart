import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/navigation/api_config.dart';
import '../models/progreso_model.dart';

class ProgresoService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// POST /progreso/marcar-vista
  /// Registra el avistamiento y evalúa logros.
  /// Se llama justo después de identificar una especie con la cámara.
  Future<MarcarVistaModel> marcarEspecieVista({
    required int idUsuario,
    required int idEspecie,
    double? latitud,
    double? longitud,
    String? fotografiaUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/progreso/marcar-vista'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_usuario': idUsuario,
        'id_especie': idEspecie,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
        if (fotografiaUrl != null) 'fotografia_url': fotografiaUrl,
      }),
    );

    if (response.statusCode == 200) {
      return MarcarVistaModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al registrar avistamiento');
  }

  /// GET /progreso/{id}/especies
  /// Devuelve cuántas especies ha visto el usuario vs el total de la app.
  Future<ProgresoEspeciesModel> obtenerProgreso(int idUsuario) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/progreso/$idUsuario/especies'),
    );

    if (response.statusCode == 200) {
      return ProgresoEspeciesModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al cargar progreso');
  }
}
