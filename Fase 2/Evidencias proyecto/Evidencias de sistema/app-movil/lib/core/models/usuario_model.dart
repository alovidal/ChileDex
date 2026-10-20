class UsuarioModel {
  final int id;
  final String correo;
  final String nombre;
  final String? apPaterno;
  final String? apMaterno;
  final String? fotoPerfilUrl;
  final String? fechaNacimiento;
  final int rachaActual;
  final bool logeado;
  final bool esNuevo;
  final String createdAt;
  final int? idRegion;
  final String? regionNombre;

  const UsuarioModel({
    required this.id,
    required this.correo,
    required this.nombre,
    this.apPaterno,
    this.apMaterno,
    this.fotoPerfilUrl,
    this.fechaNacimiento,
    required this.rachaActual,
    required this.logeado,
    required this.esNuevo,
    required this.createdAt,
    this.idRegion,
    this.regionNombre,
  });

  /// Construye un UsuarioModel desde el Map JSON que devuelve el backend.
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as int,
      correo: json['correo'] as String,
      nombre: json['nombre'] as String,
      apPaterno: json['ap_paterno'] as String?,
      apMaterno: json['ap_materno'] as String?,
      fotoPerfilUrl: json['foto_perfil_url'] as String?,
      fechaNacimiento:  json['fecha_nacimiento']   as String?,
      rachaActual: json['racha_actual'] as int,
      logeado: json['logeado'] as bool,
      esNuevo: json['es_nuevo'] as bool? ?? true,
      createdAt: json['created_at'] as String,
      idRegion: json['id_region'] as int?,
      regionNombre: json['region_nombre'] as String?,
    );
  }

  /// Convierte el modelo a Map para guardarlo en SharedPreferences.
  Map<String, dynamic> toJson() => {
    'id': id,
    'correo': correo,
    'nombre': nombre,
    'ap_paterno': apPaterno,
    'ap_materno': apMaterno,
    'foto_perfil_url': fotoPerfilUrl,
    'fecha_nacimiento': fechaNacimiento,
    'racha_actual': rachaActual,
    'logeado': logeado,
    'es_nuevo': esNuevo,
    'created_at': createdAt,
    'id_region': idRegion,
    'region_nombre': regionNombre,
  };
}
