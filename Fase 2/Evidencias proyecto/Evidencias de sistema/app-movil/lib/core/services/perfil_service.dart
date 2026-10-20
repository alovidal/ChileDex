import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app/navigation/api_config.dart';
import '../models/logro_completo_model.dart';
import '../models/perfil_model.dart';

class PerfilService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<PerfilModel> obtenerPerfil(int idUsuario) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/perfil/$idUsuario'),
    );
    if (response.statusCode == 200) {
      return PerfilModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al cargar el perfil');
  }

  Future<List<LogroCompletoModel>> obtenerTodosLogros(int idUsuario) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/perfil/$idUsuario/logros'),
  );
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((l) => LogroCompletoModel.fromJson(l as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Error al cargar insignias');
}
}