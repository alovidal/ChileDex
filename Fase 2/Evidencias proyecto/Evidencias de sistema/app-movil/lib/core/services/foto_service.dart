import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import '../../app/navigation/api_config.dart';
import 'dart:convert';

class FotoService {
  static const String _baseUrl = ApiConfig.baseUrl;

  Future<String> subirFotoPerfil({
    required int  idUsuario,
    required File foto,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/usuarios/$idUsuario/foto-perfil'),
    );

    // Determinar content type desde la extensión
    final extension = foto.path.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png'  => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _      => MediaType('image', 'jpeg'), 
    };

    request.files.add(await http.MultipartFile.fromPath(
      'archivo',
      foto.path,
      contentType: contentType,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['foto_perfil_url'] as String;
    }
    throw Exception('Error al subir la foto: ${response.body}');
  }
}