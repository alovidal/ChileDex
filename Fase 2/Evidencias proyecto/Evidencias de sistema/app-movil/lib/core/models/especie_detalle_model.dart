import 'especie_model.dart'; // reutiliza FotografiaModel

class HabitatModel {
  final int     id;
  final String  nombre;
  final String? descripcion;

  const HabitatModel({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory HabitatModel.fromJson(Map<String, dynamic> json) => HabitatModel(
        id:          json['id']          as int,
        nombre:      json['nombre']      as String,
        descripcion: json['descripcion'] as String?,
      );
}

class AvistamientoDetalleModel {
  final String  id;
  final String  fecha;
  final double? latitud;
  final double? longitud;
  final String? fotografiaUrl;

  const AvistamientoDetalleModel({
    required this.id,
    required this.fecha,
    this.latitud,
    this.longitud,
    this.fotografiaUrl,
  });

  factory AvistamientoDetalleModel.fromJson(Map<String, dynamic> json) =>
      AvistamientoDetalleModel(
        id:            json['id']              as String,
        fecha:         json['fecha']           as String,
        latitud:       json['latitud'] != null
            ? double.parse(json['latitud'].toString())
            : null,
        longitud:      json['longitud'] != null
            ? double.parse(json['longitud'].toString())
            : null,
        fotografiaUrl: json['fotografia_url']  as String?,
      );

  /// Fecha formateada (ej: "18 Ago 2026")
  String get fechaFormateada {
    final dt = DateTime.tryParse(fecha);
    if (dt == null) return '';
    const meses = ['Ene','Feb','Mar','Abr','May','Jun',
                   'Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${dt.day.toString().padLeft(2,'0')} '
           '${meses[dt.month - 1]} ${dt.year}';
  }
}

class EspecieDetalleModel {
  final int     id;
  final String  nombreComun;
  final String? nombreCientifico;
  final String? descripcion;
  final String  categoria;
  final String? estadoConservacion;
  final String? tamanio;
  final String? peso;
  final List<FotografiaModel>          fotografias;
  final List<HabitatModel>             habitats;
  final List<AvistamientoDetalleModel> misAvistamientos;

  const EspecieDetalleModel({
    required this.id,
    required this.nombreComun,
    this.nombreCientifico,
    this.descripcion,
    required this.categoria,
    this.estadoConservacion,
    this.tamanio,
    this.peso,
    required this.fotografias,
    required this.habitats,
    required this.misAvistamientos,
  });

  /// Primera fotografía para el hero
  String? get fotoHero =>
      fotografias.isNotEmpty ? fotografias.first.url : null;

  /// Fuente de la fotografía de portada
  String? get fuentePortada =>
      fotografias.isNotEmpty ? fotografias.first.fuente : null;

  /// Hábitats como texto unido (ej: "Bosque · Humedal")
  String get habitatsTexto =>
      habitats.map((h) => h.nombre).join(' · ');

  factory EspecieDetalleModel.fromJson(Map<String, dynamic> json) =>
      EspecieDetalleModel(
        id:                 json['id']                  as int,
        nombreComun:        json['nombre_comun']         as String,
        nombreCientifico:   json['nombre_cientifico']    as String?,
        descripcion:        json['descripcion']          as String?,
        categoria:          json['categoria']            as String,
        estadoConservacion: json['estado_conservacion']  as String?,
        tamanio:            json['tamanio']              as String?,
        peso:               json['peso']                 as String?,
        fotografias: (json['fotografias'] as List<dynamic>)
            .map((f) => FotografiaModel.fromJson(f as Map<String, dynamic>))
            .toList(),
        habitats: (json['habitats'] as List<dynamic>)
            .map((h) => HabitatModel.fromJson(h as Map<String, dynamic>))
            .toList(),
        misAvistamientos: (json['mis_avistamientos'] as List<dynamic>)
            .map((a) => AvistamientoDetalleModel.fromJson(
                a as Map<String, dynamic>))
            .toList(),
      );
}