/// Avistamiento con información básica de la especie.
/// Se usa para mostrar markers en el mapa y cards en el bottom sheet.
class AvistamientoMapaModel {
  final String id;
  final double latitud;
  final double longitud;
  final String fecha;
  final String? fotografiaUrl;

  // Datos de la especie asociada
  final int    especieId;
  final String especieNombre;
  final String especieCategoria;
  final String? especieFotoPortada;

  const AvistamientoMapaModel({
    required this.id,
    required this.latitud,
    required this.longitud,
    required this.fecha,
    this.fotografiaUrl,
    required this.especieId,
    required this.especieNombre,
    required this.especieCategoria,
    this.especieFotoPortada,
  });

  factory AvistamientoMapaModel.fromJson(Map<String, dynamic> json) {
    final especie = json['especie'] as Map<String, dynamic>;
    return AvistamientoMapaModel(
      id:                 json['id']             as String,
      latitud:            double.parse(json['latitud'].toString()),
      longitud:           double.parse(json['longitud'].toString()),
      fecha:              json['fecha']           as String,
      fotografiaUrl:      json['fotografia_url']  as String?,
      especieId:          especie['id']           as int,
      especieNombre:      especie['nombre_comun'] as String,
      especieCategoria:   especie['categoria']    as String,
      especieFotoPortada: especie['foto_portada'] as String?,
    );
  }

  /// Tiempo relativo desde el avistamiento (ej: "Visto hace 2 días")
  String get tiempoRelativo {
    final dt   = DateTime.tryParse(fecha);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0)    return 'Visto hoy';
    if (diff.inDays == 1)    return 'Visto hace 1 día';
    if (diff.inDays < 30)    return 'Visto hace ${diff.inDays} días';
    if (diff.inDays < 365)   return 'Visto hace ${(diff.inDays / 30).floor()} meses';
    return 'Visto hace ${(diff.inDays / 365).floor()} años';
  }
}