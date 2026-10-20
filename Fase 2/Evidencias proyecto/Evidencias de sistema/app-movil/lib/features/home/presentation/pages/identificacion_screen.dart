import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/navigation/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/especie_model.dart';
import '../../../../core/models/progreso_model.dart';
import '../../../../core/services/identificacion_service.dart';
import '../../../../core/services/progreso_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/app_button.dart';
import '../widgets/logro_toast.dart';
import '../widgets/main_scaffold.dart';

class IdentificacionScreen extends StatefulWidget {
  const IdentificacionScreen({super.key});

  @override
  State<IdentificacionScreen> createState() => _IdentificacionScreenState();
}

class _IdentificacionScreenState extends State<IdentificacionScreen> {
  CameraController? _camara;
  bool _camaraLista = false;
  bool _flashActivo = false;

  // ── Estado — agregar estas variables ──────────────────────────────────────
  double _zoomActual = 1.0;
  double _zoomMinimo = 1.0;
  double _zoomMaximo = 1.0;

  File? _fotoCapturada;
  bool _identificando = false;
  Map<String, dynamic>? _resultadoIA;
  EspecieModel? _especie;
  String? _error;
  List<LogroNuevoModel> _logrosNuevos = []; // ← declarar aquí

  @override
  void initState() {
    super.initState();
    _inicializarCamara();
  }

  // ── En _inicializarCamara, obtener los límites de zoom ────────────────────
  Future<void> _inicializarCamara() async {
    final camaras = await availableCameras();
    if (camaras.isEmpty) return;
    _camara = CameraController(
      camaras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _camara!.initialize();

    // Obtener límites de zoom del dispositivo
    _zoomMinimo = await _camara!.getMinZoomLevel();
    _zoomMaximo = await _camara!.getMaxZoomLevel();

    if (mounted) setState(() => _camaraLista = true);
  }

  // ── Método para aplicar zoom ───────────────────────────────────────────────
  Future<void> _aplicarZoom(double zoom) async {
    if (_camara == null) return;
    final zoomClamped = zoom.clamp(_zoomMinimo, _zoomMaximo);
    await _camara!.setZoomLevel(zoomClamped);
    setState(() => _zoomActual = zoomClamped);
  }

  Future<void> _tomarFoto() async {
    if (_camara == null || !_camaraLista) return;
    try {
      final foto = await _camara!.takePicture();
      setState(() {
        _fotoCapturada = File(foto.path);
        _resultadoIA = null;
        _especie = null;
        _error = null;
        _logrosNuevos = [];
      });
      await _identificar();
    } catch (e) {
      setState(() => _error = 'Error al tomar la foto');
    }
  }

  Future<void> _identificar() async {
    if (_fotoCapturada == null) return;
    setState(() => _identificando = true);

    // ── Variables para mostrar el toast luego del spinner ──────────────
    List<LogroNuevoModel> logrosParaMostrar = [];
    int? usuarioIdParaToast;

    try {
      final service = IdentificacionService();
      final resultado = await service.identificarEspecie(_fotoCapturada!);
      _resultadoIA = resultado;

      if (resultado != null && resultado['identificado'] == true) {
        final especie = await service.buscarEspeciePorNombre(
          resultado['especie'] as String,
        );
        setState(() => _especie = especie);

        if (especie != null) {
          final usuario = await SessionService().obtenerSesion();
          if (usuario != null) {
            double? latitud;
            double? longitud;
            try {
              final pos = await Geolocator.getCurrentPosition();
              latitud = pos.latitude;
              longitud = pos.longitude;
            } catch (_) {}

            final progreso = await ProgresoService().marcarEspecieVista(
              idUsuario: usuario.id,
              idEspecie: especie.id,
              latitud: latitud,
              longitud: longitud,
              fotografiaUrl: null,
            );

            if (progreso.logrosNuevos.isNotEmpty) {
              setState(() => _logrosNuevos = progreso.logrosNuevos);
              // ← Solo guardar; el toast se muestra después del spinner
              logrosParaMostrar = progreso.logrosNuevos;
              usuarioIdParaToast = usuario.id;
            }
          }
        }
      }
    } catch (e) {
      setState(() => _error = 'No se pudo identificar. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _identificando = false);
    }

    // ── Mostrar toast después del primer frame sin spinner ──────────────
    if (mounted && logrosParaMostrar.isNotEmpty && usuarioIdParaToast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await LogroToast.mostrar(
            context,
            logrosParaMostrar,
            usuarioIdParaToast!,
          );
        }
      });
    }
  }

  void _cancelar() => setState(() {
    _fotoCapturada = null;
    _resultadoIA = null;
    _especie = null;
    _error = null;
    _logrosNuevos = [];
  });

  Future<void> _toggleFlash() async {
    if (_camara == null) return;
    _flashActivo = !_flashActivo;
    await _camara!.setFlashMode(_flashActivo ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  @override
  void dispose() {
    _camara?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fotoCapturada != null) {
      return MainScaffold(
        currentIndex: 2,
        child: _PantallaResultado(
          foto: _fotoCapturada!,
          identificando: _identificando,
          resultadoIA: _resultadoIA,
          especie: _especie,
          error: _error,
          onCancelar: _cancelar,
          onVerDetalle: _especie == null
              ? null
              : () => Navigator.pushNamed(
                  context,
                  AppRoutes.especieDetalle,
                  arguments: _especie!.id,
                ),
        ),
      );
    }

    return MainScaffold(
      currentIndex: 2,
      child: Stack(
        children: [
          Container(color: Colors.black),

          // Preview con GestureDetector para pinch-to-zoom
          if (_camaraLista && _camara != null)
            Positioned.fill(
              child: GestureDetector(
                onScaleUpdate: (details) {
                  // Pinch to zoom — escalar el zoom actual
                  final nuevoZoom = (_zoomActual * details.scale).clamp(
                    _zoomMinimo,
                    _zoomMaximo,
                  );
                  _aplicarZoom(nuevoZoom);
                },
                child: CameraPreview(_camara!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          const Positioned.fill(child: _FrameEnfoque()),

          // AppBar flotante — igual que antes
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _BotonFlotante(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cámara de Identificación',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _BotonFlotante(
                      icon: _flashActivo ? Icons.flash_on : Icons.flash_off,
                      color: _flashActivo ? Colors.yellow : Colors.white,
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Control de zoom ─────────────────────────────────────────────
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(child: _buildControlZoom()),
          ),

          // Botón de captura + indicador de zoom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Indicador de zoom actual
                if (_zoomActual > 1.0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_zoomActual.toStringAsFixed(1)}×',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Text(
                  'Apunta a una especie y toma la foto',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _tomarFoto,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: AppTheme.accentOrange,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentOrange.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Slider vertical para controlar el zoom manualmente
  Widget _buildControlZoom() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícono zoom in
        _BotonFlotante(
          icon: Icons.zoom_in,
          onTap: () => _aplicarZoom(_zoomActual + 0.5),
        ),
        const SizedBox(height: 8),

        // Slider vertical
        SizedBox(
          height: 150,
          child: RotatedBox(
            quarterTurns: 3, // rotar para que sea vertical
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: AppTheme.accentOrange,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 2,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: _zoomActual,
                min: _zoomMinimo,
                max: _zoomMaximo,
                onChanged: _aplicarZoom,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Ícono zoom out
        _BotonFlotante(
          icon: Icons.zoom_out,
          onTap: () => _aplicarZoom(_zoomActual - 0.5),
        ),
      ],
    );
  }
}

// ── Botón flotante ─────────────────────────────────────────────────────────
class _BotonFlotante extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BotonFlotante({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

// ── Frame de enfoque ───────────────────────────────────────────────────────
class _FrameEnfoque extends StatelessWidget {
  const _FrameEnfoque();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _FramePainter());
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const margin = 60.0;
    const cornerSize = 24.0;
    final left = margin;
    final top = size.height * 0.25;
    final right = size.width - margin;
    final bottom = size.height * 0.75;

    canvas.drawLine(Offset(left, top + cornerSize), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerSize, top), paint);
    canvas.drawLine(Offset(right - cornerSize, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerSize), paint);
    canvas.drawLine(
      Offset(left, bottom - cornerSize),
      Offset(left, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + cornerSize, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(right - cornerSize, bottom),
      Offset(right, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right, bottom - cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Pantalla de resultado ──────────────────────────────────────────────────
class _PantallaResultado extends StatelessWidget {
  final File foto;
  final bool identificando;
  final Map<String, dynamic>? resultadoIA;
  final EspecieModel? especie;
  final String? error;
  final VoidCallback onCancelar;
  final VoidCallback? onVerDetalle;

  const _PantallaResultado({
    required this.foto,
    required this.identificando,
    required this.resultadoIA,
    required this.especie,
    required this.error,
    required this.onCancelar,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.file(foto, fit: BoxFit.cover)),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (identificando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.primaryGreen,
                            strokeWidth: 2,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Escaneando...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (resultadoIA != null)
                    _ContenidoResultado(
                      resultadoIA: resultadoIA!,
                      especie: especie,
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        if (onVerDetalle != null && !identificando) ...[
                          AppButton(
                            label: 'Ver ficha de la especie',
                            width: double.infinity,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 52,
                            onPressed: onVerDetalle,
                          ),
                          const SizedBox(height: 8),
                        ],
                        AppButton(
                          label: 'Tomar otra foto',
                          icon: Icons.camera_alt_outlined,
                          width: double.infinity,
                          type: AppButtonType.outline,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 52,
                          onPressed: onCancelar,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Contenido del resultado ────────────────────────────────────────────────
class _ContenidoResultado extends StatelessWidget {
  final Map<String, dynamic> resultadoIA;
  final EspecieModel? especie;

  const _ContenidoResultado({required this.resultadoIA, required this.especie});

  @override
  Widget build(BuildContext context) {
    final identificado = resultadoIA['identificado'] as bool;
    final confianza = (resultadoIA['confianza_pct'] as num).toDouble();

    if (!identificado) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No se identificó la especie',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Intenta con mejor iluminación o más cerca',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '¡ESPECIE DETECTADA!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${confianza.toStringAsFixed(0)}% coincidencia',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: especie?.fotoPortada != null
                      ? Image.network(
                          especie!.fotoPortada!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        especie?.nombreComun ??
                            (resultadoIA['especie'] as String).replaceAll(
                              '_',
                              ' ',
                            ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (especie?.nombreCientifico != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          especie!.nombreCientifico!,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (especie?.categoria != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            especie!.categoria,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: AppTheme.lightGray,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 28),
  );
}
