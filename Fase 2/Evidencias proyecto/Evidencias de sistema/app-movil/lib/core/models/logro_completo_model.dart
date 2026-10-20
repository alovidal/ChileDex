/// Logro del sistema con estado de obtención para la pantalla de insignias
class LogroCompletoModel {
  final int     id;
  final String  nombre;
  final String? icono;
  final String? descripcion;
  final bool    obtenido;
  final String? fechaObtencion;

  const LogroCompletoModel({
    required this.id,
    required this.nombre,
    this.icono,
    this.descripcion,
    required this.obtenido,
    this.fechaObtencion,
  });

  factory LogroCompletoModel.fromJson(Map<String, dynamic> json) =>
      LogroCompletoModel(
        id:             json['id']              as int,
        nombre:         json['nombre']          as String,
        icono:          json['icono']           as String?,
        descripcion:    json['descripcion']     as String?,
        obtenido:       json['obtenido']        as bool,
        fechaObtencion: json['fecha_obtencion'] as String?,
      );

  /// Fecha formateada DD/MM/AA o "- - -" si no está obtenido
  String get fechaFormateada {
    if (fechaObtencion == null) return '- - -';
    final dt = DateTime.tryParse(fechaObtencion!);
    if (dt == null) return '- - -';
    return '${dt.day.toString().padLeft(2, '0')}/'
           '${dt.month.toString().padLeft(2, '0')}/'
           '${dt.year.toString().substring(2)}';
  }
}