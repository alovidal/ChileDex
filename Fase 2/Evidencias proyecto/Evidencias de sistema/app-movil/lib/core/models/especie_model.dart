/// Fotografía asociada a una especie
class FotografiaModel {
  final int id;
  final String url;
  final int orden;
  final String? fuente;

  const FotografiaModel({
    required this.id,
    required this.url,
    required this.orden,
    this.fuente,
  });

  factory FotografiaModel.fromJson(Map<String, dynamic> json) => FotografiaModel(
        id:    json['id']    as int,
        url:   json['url']   as String,
        orden: json['orden'] as int,
        fuente: json['fuente'] as String?,
      );
}

/// Especie con sus fotografías incluidas
class EspecieModel {
  final int id;
  final String nombreComun;
  final String? nombreCientifico;
  final String? descripcion;
  final String categoria;
  final String? estadoConservacion;
  final String? tamanio;
  final String? peso;
  final List<FotografiaModel> fotografias;

  const EspecieModel({
    required this.id,
    required this.nombreComun,
    this.nombreCientifico,
    this.descripcion,
    required this.categoria,
    this.estadoConservacion,
    this.tamanio,
    this.peso,
    required this.fotografias,
  });

  factory EspecieModel.fromJson(Map<String, dynamic> json) => EspecieModel(
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
      );

  /// URL de la primera fotografía, o null si no tiene
  String? get fotoPortada =>
      fotografias.isNotEmpty ? fotografias.first.url : null;
}

class EspecieCatalogoModel {
  final int id;
  final String nombreComun;
  final String? nombreCientifico;
  final String categoria;
  final String? estadoConservacion;
  final String? habitatNombre;
  final String? fotoUrl;

  const EspecieCatalogoModel({
    required this.id,
    required this.nombreComun,
    this.nombreCientifico,
    required this.categoria,
    this.estadoConservacion,
    this.habitatNombre,
    this.fotoUrl,
  });

  factory EspecieCatalogoModel.fromJson(Map<String, dynamic> json) {
    // Extraer primera foto del array anidado
    final fotos = json['especie_fotografia'] as List<dynamic>? ?? [];
    fotos.sort((a, b) => (a['orden'] as int).compareTo(b['orden'] as int));
    final fotoUrl = fotos.isNotEmpty ? fotos.first['url'] as String? : null;

    return EspecieCatalogoModel(
      id:                 json['id']                 as int,
      nombreComun:        json['nombre_comun']        as String,
      nombreCientifico:   json['nombre_cientifico']   as String?,
      categoria:          json['categoria']           as String,
      estadoConservacion: json['estado_conservacion'] as String?,
      habitatNombre:      json['habitat_nombre']      as String?,
      fotoUrl:            fotoUrl,
    );
  }
}

/// Conteo de especies por estado de conservación (para el panel de filtros)
class ConteoEstadoModel {
  final String estado;
  final int cantidad;

  const ConteoEstadoModel({required this.estado, required this.cantidad});

  factory ConteoEstadoModel.fromJson(Map<String, dynamic> json) =>
      ConteoEstadoModel(
        estado:   json['estado']   as String,
        cantidad: json['cantidad'] as int,
      );
}