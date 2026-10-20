import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/navigation/api_config.dart';
import '../models/especie_detalle_model.dart';
import '../models/especie_model.dart';
import '../models/region_model.dart';
import '../models/evento_model.dart';

class EspecieService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// GET /especies/destacadas — devuelve las 3 especies fijas
  Future<List<EspecieModel>> obtenerDestacadas() async {
    final response = await http.get(Uri.parse('$_baseUrl/especies/destacadas'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => EspecieModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar especies destacadas');
  }

  /// GET /especies/regiones — devuelve todas las regiones
  Future<List<RegionModel>> obtenerRegiones() async {
    final response = await http.get(Uri.parse('$_baseUrl/especies/regiones'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((r) => RegionModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar regiones');
  }

  Future<RegionModel> obtenerRegion(int idRegion) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/especies/regiones/$idRegion'),
    );
    if (response.statusCode == 200) {
      return RegionModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al cargar la región');
  }

  /// GET /especies/catalogo con filtros opcionales
  Future<Map<String, dynamic>> obtenerCatalogo({
    String? categoria,
    List<String>? estadoConservacion,
    List<int>? habitatIds,
    List<int>? regionIds,
    String? busqueda,
    String orden = 'asc',
    int pagina = 1,
    int porPagina = 6,
    int? idUsuario,
    bool? soloVistas,
  }) async {
    final uri = Uri.parse('$_baseUrl/especies/catalogo').replace(
      queryParameters: {
        'categoria': ?categoria,
        'busqueda': ?busqueda,
        'orden': orden,
        'pagina': '$pagina',
        'por_pagina': '$porPagina',
        'estado_conservacion': ?estadoConservacion,
        if (habitatIds != null)
          'habitat_ids': habitatIds.map((e) => '$e').toList(),
        if (regionIds != null)
          'region_ids': regionIds.map((e) => '$e').toList(),
        if (idUsuario != null) 'id_usuario': '$idUsuario',
        if (soloVistas != null) 'solo_vistas': '$soloVistas',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'especies': (data['especies'] as List<dynamic>)
            .map(
              (e) => EspecieCatalogoModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        'hayMas': data['hay_mas'] as bool,
        'total': data['total'] as int,
      };
    }
    throw Exception('Error al cargar el catálogo');
  }

  /// GET /especies/habitats
  Future<List<Map<String, dynamic>>> obtenerHabitats() async {
    final response = await http.get(Uri.parse('$_baseUrl/especies/habitats'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Error al cargar hábitats');
  }

  /// GET /especies/conteo-estados
  Future<List<ConteoEstadoModel>> obtenerConteoEstados() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/especies/conteo-estados'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ConteoEstadoModel.fromJson(e)).toList();
    }
    throw Exception('Error al cargar conteos');
  }

  /// GET /eventos/
  Future<List<EventoModel>> obtenerEventos() async {
    final response = await http.get(Uri.parse('$_baseUrl/eventos/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => EventoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar eventos');
  }

  Future<EventoModel> obtenerEvento(int idEvento) async {
    final response = await http.get(Uri.parse('$_baseUrl/eventos/$idEvento'));
    if (response.statusCode == 200) {
      return EventoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al cargar el evento');
  }

  /// GET /especies/{id}?id_usuario={id}
  Future<EspecieDetalleModel> obtenerDetalle({
    required int idEspecie,
    int? idUsuario,
  }) async {
    final uri = Uri.parse('$_baseUrl/especies/$idEspecie').replace(
      queryParameters: idUsuario != null ? {'id_usuario': '$idUsuario'} : null,
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return EspecieDetalleModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al cargar la especie');
  }

  /// GET /especies/regiones?excluir=16
  /// Para el selector del registro — excluye la región con id 16
  Future<List<RegionModel>> obtenerRegionesRegistro() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/especies/regiones/usuario'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((r) => RegionModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar regiones');
  }
}
