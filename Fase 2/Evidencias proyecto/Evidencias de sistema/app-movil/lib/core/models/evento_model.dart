class EventoModel {
  final int id;
  final String nombre;
  final String fecha;
  final String? lugar;
  final String? descripcion;
  final String? categoria;
  final String? imagenUrl;

  const EventoModel({
    required this.id,
    required this.nombre,
    required this.fecha,
    this.lugar,
    this.descripcion,
    this.categoria,
    this.imagenUrl,
  });

  factory EventoModel.fromJson(Map<String, dynamic> json) => EventoModel(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    fecha: json['fecha'] as String,
    lugar: json['lugar'] as String?,
    descripcion: json['descripcion'] as String?,
    categoria: json['categoria'] as String?,
    imagenUrl: json['imagen_url'] as String?,
  );

  /// Fecha formateada para mostrar en la card (ej: "22 Jun 2026")
  String get fechaFormateada {
    final dt = DateTime.tryParse(fecha);
    if (dt == null) return '';
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
  }

  /// Ícono según categoría del evento
  String get iconoCategoria => switch (categoria) {
    'CONSERVACION' => '',
    'EDUCACION' => '',
    'AVISTAMIENTO' => '',
    _ => '',
  };
}
