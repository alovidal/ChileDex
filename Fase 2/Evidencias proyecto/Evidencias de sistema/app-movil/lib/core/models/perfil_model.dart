/// Logro obtenido por el usuario
class LogroModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final String fechaObtencion;

  const LogroModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
    required this.fechaObtencion,
  });

  factory LogroModel.fromJson(Map<String, dynamic> json) => LogroModel(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    icono: json['icono'] as String?,
    fechaObtencion: json['fecha_obtencion'] as String,
  );

  /// Formato legible de la fecha (ej: "22/06/26")
  String get fechaFormateada {
    final dt = DateTime.tryParse(fechaObtencion);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year.toString().substring(2)}';
  }
}

/// Avistamiento resumido para el perfil
class AvistamientoPerfilModel {
  final String id;
  final String fecha;
  final String? fotoUrl;
  final int especieId;
  final String especieNombre;

  const AvistamientoPerfilModel({
    required this.id,
    required this.fecha,
    this.fotoUrl,
    required this.especieId,
    required this.especieNombre,
  });

  factory AvistamientoPerfilModel.fromJson(Map<String, dynamic> json) =>
      AvistamientoPerfilModel(
        id: json['id'] as String,
        fecha: json['fecha'] as String,
        fotoUrl: json['foto_url'] as String?,
        especieId: json['especie_id'] as int,
        especieNombre: json['especie_nombre'] as String,
      );

  /// Tiempo relativo (ej: "Hace 2 días")
  String get tiempoRelativo {
    final dt = DateTime.tryParse(fecha);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Hace 1 día';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 14) return 'Hace 1 semana';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} semanas';
    return 'Hace ${(diff.inDays / 30).floor()} meses';
  }
}

/// Modelo completo del perfil
class PerfilModel {
  final int idUsuario;
  final String nombre;
  final String? apPaterno;
  final String? fotoPerfilUrl;
  final int rachaActual;
  final int totalEspecies;
  final int totalAvistamientos;
  final int totalLogros;
  final String? regionNombre;
  final List<LogroModel> logros;
  final List<AvistamientoPerfilModel> ultimosAvistamientos;

  const PerfilModel({
    required this.idUsuario,
    required this.nombre,
    this.apPaterno,
    this.fotoPerfilUrl,
    required this.rachaActual,
    required this.totalEspecies,
    required this.totalAvistamientos,
    required this.totalLogros,
    this.regionNombre,
    required this.logros,
    required this.ultimosAvistamientos,
  });

  String get nombreCompleto =>
      apPaterno != null ? '$nombre $apPaterno' : nombre;

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    final u = json['usuario'] as Map<String, dynamic>;
    return PerfilModel(
      idUsuario: u['id'] as int,
      nombre: u['nombre'] as String,
      apPaterno: u['ap_paterno'] as String?,
      fotoPerfilUrl: u['foto_perfil_url'] as String?,
      rachaActual: u['racha_actual'] as int,
      totalEspecies: json['total_especies'] as int,
      totalAvistamientos: json['total_avistamientos'] as int,
      totalLogros: json['total_logros'] as int,
      regionNombre: u['region_nombre'] as String?,
      logros: (json['logros'] as List<dynamic>)
          .map((l) => LogroModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      ultimosAvistamientos: (json['ultimos_avistamientos'] as List<dynamic>)
          .map(
            (a) => AvistamientoPerfilModel.fromJson(a as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
