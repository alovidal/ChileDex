/// Logro recién desbloqueado
class LogroNuevoModel {
  final int id;
  final String nombre;
  final String? icono;

  const LogroNuevoModel({required this.id, required this.nombre, this.icono});

  factory LogroNuevoModel.fromJson(Map<String, dynamic> json) =>
      LogroNuevoModel(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        icono: json['icono'] as String?,
      );
}

/// Resultado de marcar una especie como vista
class MarcarVistaModel {
  final bool esNueva;
  final int totalEspecies;
  final List<LogroNuevoModel> logrosNuevos;

  const MarcarVistaModel({
    required this.esNueva,
    required this.totalEspecies,
    required this.logrosNuevos,
  });

  factory MarcarVistaModel.fromJson(Map<String, dynamic> json) =>
      MarcarVistaModel(
        esNueva: json['es_nueva'] as bool,
        totalEspecies: json['total_especies'] as int,
        logrosNuevos: (json['logros_nuevos'] as List<dynamic>)
            .map((l) => LogroNuevoModel.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}

/// Progreso general de especies del usuario
class ProgresoEspeciesModel {
  final int totalApp;
  final int totalVistas;

  const ProgresoEspeciesModel({
    required this.totalApp,
    required this.totalVistas,
  });

  /// Porcentaje completado entre 0.0 y 1.0
  double get porcentaje => totalApp == 0 ? 0 : totalVistas / totalApp;

  factory ProgresoEspeciesModel.fromJson(Map<String, dynamic> json) =>
      ProgresoEspeciesModel(
        totalApp: json['total_app'] as int,
        totalVistas: json['total_vistas'] as int,
      );
}

class RachaResultModel {
  final int rachaActual;
  final String cambio; // 'sin_cambio' | 'incremento' | 'reset' | 'inicio'
  final List<LogroNuevoModel> logrosNuevos;

  const RachaResultModel({
    required this.rachaActual,
    required this.cambio,
    required this.logrosNuevos,
  });

  bool get subio => cambio == 'incremento';
  bool get reseteo => cambio == 'reset';

  factory RachaResultModel.fromJson(Map<String, dynamic> json) =>
      RachaResultModel(
        rachaActual: json['racha_actual'] as int,
        cambio: json['cambio'] as String,
        logrosNuevos: (json['logros_nuevos'] as List<dynamic>? ?? [])
            .map((l) => LogroNuevoModel.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}
