import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../app/navigation/api_config.dart';

import 'package:http_parser/http_parser.dart';

import '../models/especie_model.dart';

class IdentificacionService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _baseUrl2 = 'http://192.168.1.18:8080';


  Future<Map<String, dynamic>?> identificarEspecie(File imagen) async {
    final uri = Uri.parse('$_baseUrl2/identificar');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'imagen',
        imagen.path,
        filename: 'foto.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al identificar: ${response.statusCode}');
  }

  Future<EspecieModel?> buscarEspeciePorNombre(String nombreCientifico) async {
    final uri = Uri.parse('$_baseUrl/especies/por-nombre/$nombreCientifico');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return EspecieModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    if (response.statusCode == 404) return null;
    throw Exception('Error al buscar especie');
  }
}
