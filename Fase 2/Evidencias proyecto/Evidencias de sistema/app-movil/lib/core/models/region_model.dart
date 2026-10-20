class RegionModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;

  const RegionModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) => RegionModel(
        id:          json['id']          as int,
        nombre:      json['nombre']      as String,
        descripcion: json['descripcion'] as String?,
        imagenUrl:   json['imagen_url']  as String?,
      );
}