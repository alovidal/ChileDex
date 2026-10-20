import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/avistamiento_model.dart';
import '../../../../core/services/avistamiento_service.dart';
import '../widgets/avistamiento_card_mapa.dart';
import '../widgets/main_scaffold.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  // ── Constantes ───────────────────────────────────────────────────────────
  static const _centroChile = LatLng(-33.45, -70.65);

  // ── Controladores y servicios ────────────────────────────────────────────
  // Stream que alimenta el punto azul de ubicación actual en el mapa
  final _posicionController =
      StreamController<LocationMarkerPosition?>.broadcast();
  final _service        = AvistamientoService();
  final _mapController  = MapController();
  final _sheetController = DraggableScrollableController();

  // ── Estado del mapa ──────────────────────────────────────────────────────
  List<AvistamientoMapaModel> _avistamientos     = []; // todos (marcadores)
  List<AvistamientoMapaModel> _avistamientosZona = []; // visibles en zona
  bool _isLoading        = true;
  bool _sheetExpandido   = false;
  bool _cargandoUbicacion = false;
  bool _mapaListo        = false; // true una vez que onMapReady dispara

  // ── Buscador flotante ────────────────────────────────────────────────────
  final _buscadorController = TextEditingController();
  final _buscadorFocus      = FocusNode();
  final _buscadorKey        = GlobalKey(); // ancla para posicionar el overlay
  List<Map<String, dynamic>> _sugerencias = [];
  Timer?       _debounceBusqueda;
  OverlayEntry? _overlayEntry;

  // ── Paginación por zona ──────────────────────────────────────────────────
  int  _paginaZona   = 1;
  bool _hayMasEnZona = false;
  bool _cargandoMas  = false;
  int  _totalEnZona  = 0;

  // ── Debounce del movimiento del mapa ────────────────────────────────────
  // Almacena el instante del último movimiento; si cambió antes de 600 ms,
  // la carga de zona se cancela y se espera el siguiente reposo.
  DateTime? _ultimoMovimiento;

  // ════════════════════════════════════════════════════════════════════════
  // Ciclo de vida
  // ════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _cargarTodos(); // carga inicial de todos los marcadores
  }

  @override
  void dispose() {
    _debounceBusqueda?.cancel();
    _mapController.dispose();
    _sheetController.dispose();
    _posicionController.close();
    _buscadorController.dispose();
    _buscadorFocus.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  // Carga de datos
  // ════════════════════════════════════════════════════════════════════════

  /// Descarga todos los avistamientos para pintar los marcadores iniciales.
  Future<void> _cargarTodos() async {
    try {
      final data = await _service.obtenerMapa();
      if (!mounted) return;
      setState(() {
        _avistamientos     = data;
        _avistamientosZona = data;
        _isLoading         = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // Ubicación del usuario
  // ════════════════════════════════════════════════════════════════════════

  /// Pide permiso de GPS al arrancar la pantalla y, si se concede, centra el
  /// mapa y activa el stream continuo que mueve el punto azul.
  Future<void> _pedirUbicacion() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      final permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) return;

      // Stream continuo — solo emite si el usuario se movió ≥ 5 m
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy:       LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (pos) => _posicionController.add(
          LocationMarkerPosition(
            latitude:  pos.latitude,
            longitude: pos.longitude,
            accuracy:  pos.accuracy,
          ),
        ),
        onError: (_) {}, // errores de GPS momentáneos se ignoran
      );

      // Posición puntual para centrar el mapa en el arranque
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy:  LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted || !_mapaListo) return;
      _mapController.move(LatLng(pos.latitude, pos.longitude), 12);
    } catch (_) {}
  }

  /// Botón FAB — recentra el mapa en la posición actual del usuario.
  Future<void> _centrarEnUsuario() async {
    setState(() => _cargandoUbicacion = true);

    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy:  LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted || !_mapaListo) return;
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la ubicación')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // Buscador de ubicación (Nominatim)
  // ════════════════════════════════════════════════════════════════════════

  /// Dispara la carga de sugerencias con debounce de 400 ms.
  void _onTextoBuscador(String texto) {
    _debounceBusqueda?.cancel();
    if (texto.trim().length < 3) {
      _cerrarOverlay();
      return;
    }
    _debounceBusqueda = Timer(const Duration(milliseconds: 400), () {
      _cargarSugerencias(texto);
    });
  }

  /// Consulta Nominatim y almacena hasta 5 sugerencias para Chile.
  Future<void> _cargarSugerencias(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q':            query,
        'format':       'json',
        'limit':        '5',
        'countrycodes': 'cl',
      });
      final respuesta = await http.get(
        uri,
        headers: {'User-Agent': 'cl.chiledex.app'},
      );
      if (!mounted) return;

      final lista = jsonDecode(respuesta.body) as List;
      setState(() {
        _sugerencias = lista
            .map((e) => {
                  'nombre': e['display_name'] as String,
                  'lat':    double.parse(e['lat'] as String),
                  'lon':    double.parse(e['lon'] as String),
                })
            .toList();
      });
      _mostrarOverlay();
    } catch (_) {}
  }

  /// Mueve el mapa a la sugerencia seleccionada y cierra el overlay.
  void _seleccionarSugerencia(Map<String, dynamic> s) {
    _buscadorController.text = s['nombre'] as String;
    _buscadorFocus.unfocus();
    _cerrarOverlay();
    _mapController.move(LatLng(s['lat'] as double, s['lon'] as double), 13);
  }

  /// Limpia el campo de texto y descarta las sugerencias.
  void _limpiarBuscador() {
    _buscadorController.clear();
    _cerrarOverlay();
    setState(() => _sugerencias = []);
  }

  // ════════════════════════════════════════════════════════════════════════
  // Overlay de sugerencias
  // ════════════════════════════════════════════════════════════════════════

  /// Inserta el dropdown de sugerencias justo debajo del campo de búsqueda.
  void _mostrarOverlay() {
    _cerrarOverlay();
    if (_sugerencias.isEmpty) return;

    final renderBox =
        _buscadorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final ancho  = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top:   offset.dy + renderBox.size.height + 4,
        left:  offset.dx,
        width: ancho,
        child: Material(
          elevation:    6,
          borderRadius: BorderRadius.circular(12),
          child: ListView.separated(
            padding:          EdgeInsets.zero,
            shrinkWrap:       true,
            itemCount:        _sugerencias.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = _sugerencias[i];
              return ListTile(
                dense:   true,
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.primaryGreen,
                  size:  18,
                ),
                title: Text(
                  s['nombre'] as String,
                  style:    const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _seleccionarSugerencia(s),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _cerrarOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ════════════════════════════════════════════════════════════════════════
  // Filtro por zona visible del mapa
  // ════════════════════════════════════════════════════════════════════════

  /// Callback de `onPositionChanged` — aplica debounce para no disparar una
  /// petición en cada pixel del gesto de paneo o zoom.
  void _onMapaMoved(MapCamera camera) {
    _debounceZona(camera);
  }

  /// Espera 600 ms de reposo antes de cargar la zona; si el mapa sigue
  /// moviéndose, el timestamp cambia y la carga anterior se descarta.
  void _debounceZona(MapCamera camera) async {
    final ahora = DateTime.now();
    _ultimoMovimiento = ahora;

    await Future.delayed(const Duration(milliseconds: 600));
    if (_ultimoMovimiento != ahora) return; // mapa aún en movimiento

    final bounds = camera.visibleBounds;
    _cargarZona(
      latMin:   bounds.south,
      latMax:   bounds.north,
      lonMin:   bounds.west,
      lonMax:   bounds.east,
      resetear: true, // nueva zona → primera página
    );
  }

  /// Descarga los avistamientos dentro del bounding box visible.
  /// Con [resetear] = true empieza desde la página 1; false añade la siguiente.
  Future<void> _cargarZona({
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
    bool resetear = false,
  }) async {
    if (resetear) {
      setState(() {
        _avistamientosZona = [];
        _paginaZona        = 1;
        _hayMasEnZona      = false;
      });
    }

    try {
      final data = await _service.obtenerEnZona(
        latMin:    latMin,
        latMax:    latMax,
        lonMin:    lonMin,
        lonMax:    lonMax,
        pagina:    resetear ? 1 : _paginaZona + 1,
        porPagina: 10,
      );

      if (!mounted) return;
      setState(() {
        final nuevos = data['avistamientos'] as List<AvistamientoMapaModel>;

        if (resetear) {
          _avistamientosZona = nuevos;
          _paginaZona        = 1;
        } else {
          _avistamientosZona.addAll(nuevos);
          _paginaZona++;
        }

        _totalEnZona  = data['total']   as int;
        _hayMasEnZona = data['hayMas']  as bool;
        _cargandoMas  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  /// Carga la siguiente página de avistamientos dentro de la zona actual.
  Future<void> _cargarMasEnZona() async {
    if (!_hayMasEnZona || _cargandoMas) return;
    setState(() => _cargandoMas = true);

    final bounds = _mapController.camera.visibleBounds;
    await _cargarZona(
      latMin:   bounds.south,
      latMax:   bounds.north,
      lonMin:   bounds.west,
      lonMax:   bounds.east,
      resetear: false,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Build principal
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      child: Stack(
        children: [
          _buildMapa(),
          _buildBuscadorFlotante(),
          _buildBotonUbicacion(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Widgets privados — Mapa
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMapa() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:   _centroChile,
        initialZoom:     6,
        minZoom:         4,
        maxZoom:         18,
        onMapReady:      () {
          _mapaListo = true;
          _pedirUbicacion();
        },
        onPositionChanged: (camera, _) => _onMapaMoved(camera),
      ),
      children: [
        TileLayer(
          urlTemplate:        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'cl.chiledex.app',
        ),
        MarkerLayer(markers: _buildMarkers()),

        // Punto azul con círculo de precisión
        CurrentLocationLayer(
          positionStream: _posicionController.stream,
          style: const LocationMarkerStyle(
            marker: DefaultLocationMarker(
              color: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 14),
            ),
            markerSize:          Size(24, 24),
            accuracyCircleColor: Color(0x220000FF),
            headingSectorColor:  Color(0x880000FF),
          ),
        ),
      ],
    );
  }

  /// Genera un marcador naranja por cada avistamiento cargado.
  List<Marker> _buildMarkers() {
    return _avistamientos.map((a) {
      return Marker(
        point:  LatLng(a.latitud, a.longitud),
        width:  36,
        height: 36,
        child: GestureDetector(
          onTap: () => _mostrarDetalleMarker(a),
          child: Container(
            decoration: BoxDecoration(
              color:  AppTheme.accentOrange,
              shape:  BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color:     AppTheme.accentOrange.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset:    const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.flutter_dash, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();
  }

  // ── Foto de especie ──────────────────────────────────────────────────────

  /// Placeholder cuando no hay foto o falla la decodificación de la imagen.
  Widget _fotoPlaceholder() {
    return Container(
      width:  64,
      height: 64,
      color:  AppTheme.lightGray,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.textGray,
      ),
    );
  }

  /// Carga la foto de portada de la especie a tamaño reducido (menos memoria).
  /// El [errorBuilder] evita el crash por "Failed to decode image".
  Widget _buildFotoEspecie(String? url) {
    if (url == null || url.isEmpty) return _fotoPlaceholder();

    return Image.network(
      url,
      width:      64,
      height:     64,
      fit:        BoxFit.cover,
      cacheWidth: 128, // decodifica a resolución reducida
      errorBuilder: (_, _, _) => _fotoPlaceholder(),
    );
  }

  /// Popup al tocar un marcador — muestra nombre, foto y tiempo relativo.
  /// Al tocar la card navega a la ficha de la especie.
  void _mostrarDetalleMarker(AvistamientoMapaModel a) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(sheetContext);
          Navigator.pushNamed(
            context, // contexto de la pantalla, sigue montado
            AppRoutes.especieDetalle,
            arguments: a.especieId,
          );
        },
        child: Container(
          margin:    const EdgeInsets.all(16),
          padding:   const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildFotoEspecie(a.especieFotoPortada),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize:     MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.especieNombre,
                      style: const TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.tiempoRelativo,
                      style: TextStyle(fontSize: 13, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.lightGray),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Widgets privados — Buscador flotante
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBuscadorFlotante() {
    return Positioned(
      top:   48,
      left:  16,
      right: 16,
      child: Container(
        key:    _buscadorKey, // ancla del overlay de sugerencias
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:     Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset:    const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _buscadorController,
          focusNode:  _buscadorFocus,
          onChanged:  _onTextoBuscador,
          onSubmitted: (_) => _cerrarOverlay(),
          decoration: InputDecoration(
            filled:    true,
            fillColor: AppTheme.cardWhite,
            hintText:  'Buscar ubicación...',
            hintStyle: TextStyle(color: AppTheme.textGray, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search,
              color: AppTheme.textGray,
              size:  20,
            ),
            // Botón ✕ — solo visible cuando hay texto
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _buscadorController,
              builder: (_, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon:     const Icon(Icons.close, size: 18),
                      color:    AppTheme.textGray,
                      onPressed: _limpiarBuscador,
                    ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical:   14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:   BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:   BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Widgets privados — Botón de ubicación
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBotonUbicacion() {
    return Positioned(
      right:  16,
      bottom: 140, // por encima del bottom sheet expandido
      child: FloatingActionButton.small(
        onPressed:       _cargandoUbicacion ? null : _centrarEnUsuario,
        backgroundColor: AppTheme.cardWhite,
        foregroundColor: AppTheme.primaryGreen,
        elevation:       4,
        child: _cargandoUbicacion
            ? const SizedBox(
                width:  18,
                height: 18,
                child:  CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Widgets privados — Bottom sheet de avistamientos
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      controller:       _sheetController,
      initialChildSize: 0.12,
      minChildSize:     0.12,
      maxChildSize:     0.55,
      snap:             true,
      snapSizes:        const [0.12, 0.55],
      builder: (context, scrollController) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            setState(() => _sheetExpandido = n.extent > 0.2);
            return true;
          },
          child: Container(
            decoration: const BoxDecoration(
              color:        AppTheme.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color:     Colors.black12,
                  blurRadius: 12,
                  offset:    Offset(0, -2),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding:    EdgeInsets.zero,
              children: [
                _buildSheetHeader(),
                if (_sheetExpandido) ...[
                  const Divider(height: 1),

                  // Cards de avistamientos de la zona visible
                  ..._avistamientosZona.map(
                    (a) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child:   AvistamientoCardMapa(avistamiento: a),
                    ),
                  ),

                  // Paginación — botón "Ver más" o spinner de carga
                  if (_hayMasEnZona)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: _cargandoMas
                          ? const Center(
                              child: CircularProgressIndicator(
                                color:       AppTheme.primaryGreen,
                                strokeWidth: 2,
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: _cargarMasEnZona,
                              icon:      const Icon(Icons.expand_more),
                              label: Text(
                                'Ver más (${_totalEnZona - _avistamientosZona.length} restantes)',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                                side: BorderSide(color: AppTheme.primaryGreen),
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    )
                  // Mensaje de fin de lista
                  else if (_avistamientosZona.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Todos los avistamientos de la zona',
                          style: TextStyle(
                            fontSize: 12,
                            color:    AppTheme.textGray,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Encabezado del bottom sheet — muestra el conteo de avistamientos en zona.
  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flutter_dash,
              color: AppTheme.primaryGreen,
              size:  20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalEnZona avistamientos en esta zona',
                  style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                    color:      AppTheme.textDark,
                  ),
                ),
                if (_avistamientosZona.isNotEmpty)
                  Text(
                    'Mostrando ${_avistamientosZona.length} de $_totalEnZona',
                    style: TextStyle(fontSize: 11, color: AppTheme.textGray),
                  ),
              ],
            ),
          ),
          Icon(
            _sheetExpandido
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_up,
            color: AppTheme.textGray,
          ),
        ],
      ),
    );
  }
}