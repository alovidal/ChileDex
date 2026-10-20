import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/navigation/api_config.dart';
import '../models/avistamiento_model.dart';

class AvistamientoService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// GET /avistamientos/mapa — todos los avistamientos con coordenadas
  Future<List<AvistamientoMapaModel>> obtenerMapa() async {
    final response = await http.get(Uri.parse('$_baseUrl/avistamientos/mapa'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => AvistamientoMapaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar avistamientos');
  }

  /// GET /avistamientos/zona — avistamientos dentro de un bounding box
  Future<Map<String, dynamic>> obtenerEnZona({
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
    int pagina = 1,
    int porPagina = 10,
  }) async {
    final uri = Uri.parse('$_baseUrl/avistamientos/zona').replace(
      queryParameters: {
        'lat_min': '$latMin',
        'lat_max': '$latMax',
        'lon_min': '$lonMin',
        'lon_max': '$lonMax',
        'pagina': '$pagina',
        'por_pagina': '$porPagina',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'avistamientos': (data['avistamientos'] as List<dynamic>)
            .map(
              (e) => AvistamientoMapaModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        'total': data['total'] as int,
        'hayMas': data['hay_mas'] as bool,
      };
    }
    throw Exception('Error al cargar avistamientos en zona');
  }
}
