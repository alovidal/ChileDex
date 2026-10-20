import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/especie_model.dart';
import '../../../../core/services/especie_service.dart';
import '../../../../core/services/session_service.dart';
import '../widgets/app_background.dart';
import '../widgets/especie_card.dart';
import '../widgets/filtros_sheet.dart';
import '../widgets/main_scaffold.dart';

class CatalogoScreen extends StatefulWidget {
  final List<int>? regionIds;
  final bool? soloVistas;
  final int? idUsuario;

  const CatalogoScreen({
    super.key,
    this.regionIds,
    this.soloVistas,
    this.idUsuario,
  });

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _service = EspecieService();
  final _searchController = TextEditingController();

  // ── Estado de filtros ─────────────────────────────────────────────────────
  Timer? _debounce;
  String? _categoriaActiva; // null = todas
  String _orden = 'asc';
  List<String> _estadosFiltro = [];
  List<int> _habitatsFiltro = [];
  List<int> _regionesFiltro = [];

  // ── Datos ─────────────────────────────────────────────────────────────────
  List<EspecieCatalogoModel> _especies = [];
  int _totalEspecies = 0;
  bool _isLoading = true;

  // ── Estado de paginación ──────────────────────────────────────────────
  int _paginaActual = 1;
  bool _hayMas = true;
  bool _cargandoMas = false;

  // ScrollController para detectar cuando llega al final
  final _scrollController = ScrollController();

  // Categorías disponibles para los chips
  static const List<Map<String, String>> _categorias = [
    {'valor': '', 'label': 'Todas'},
    {'valor': 'AVE', 'label': 'Aves'},
    {'valor': 'MAMIFERO', 'label': 'Mamíferos'},
    {'valor': 'FLORA', 'label': 'Flora'},
    {'valor': 'REPTIL', 'label': 'Reptiles'},
    {'valor': 'ANFIBIO', 'label': 'Anfibios'},
    {'valor': 'INSECTO', 'label': 'Insectos'},
  ];

  bool? _soloVistas;
  int? _idUsuario;

  @override
  void initState() {
    super.initState();
    if (widget.regionIds != null) _regionesFiltro = widget.regionIds!;
    if (widget.soloVistas != null) _soloVistas = widget.soloVistas;
    if (widget.idUsuario != null) _idUsuario = widget.idUsuario;
    _cargarUsuarioYEspecies();

    // Listener para paginación
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Se ejecuta cuando el usuario hace scroll
  void _onScroll() {
    // Cuando está a 200px del final, cargar más
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMas();
    }
  }

  Future<void> _cargarUsuarioYEspecies() async {
    // Obtener usuario de la sesión si no vino por argumento
    if (_idUsuario == null) {
      final usuario = await SessionService().obtenerSesion();
      if (mounted) _idUsuario = usuario?.id;
    }
    _cargarEspecies();
  }

  Future<void> _cargarEspecies() async {
    setState(() {
      _isLoading = true;
      _paginaActual = 1;
      _especies = [];
      _hayMas = true;
    });

    try {
      final data = await _service.obtenerCatalogo(
        categoria: _categoriaActiva?.isEmpty == true ? null : _categoriaActiva,
        estadoConservacion: _estadosFiltro.isEmpty ? null : _estadosFiltro,
        habitatIds: _habitatsFiltro.isEmpty ? null : _habitatsFiltro,
        regionIds: _regionesFiltro.isEmpty ? null : _regionesFiltro,
        busqueda: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        orden: _orden,
        pagina: 1,
        porPagina: 6,
        idUsuario: _idUsuario,
        soloVistas: _soloVistas,
      );

      if (mounted) {
        setState(() {
          _especies = data['especies'] as List<EspecieCatalogoModel>;
          _totalEspecies = data['total'] as int;
          _hayMas = data['hayMas'] as bool;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarMas() async {
    if (!_hayMas || _cargandoMas || _isLoading) return;
    setState(() => _cargandoMas = true);

    try {
      final siguientePagina = _paginaActual + 1;
      final data = await _service.obtenerCatalogo(
        categoria: _categoriaActiva?.isEmpty == true ? null : _categoriaActiva,
        estadoConservacion: _estadosFiltro.isEmpty ? null : _estadosFiltro,
        habitatIds: _habitatsFiltro.isEmpty ? null : _habitatsFiltro,
        regionIds: _regionesFiltro.isEmpty ? null : _regionesFiltro,
        busqueda: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        orden: _orden,
        pagina: siguientePagina,
        porPagina: 6,
        idUsuario: _idUsuario,
        soloVistas: _soloVistas,
      );

      if (mounted) {
        setState(() {
          // Agregar al final, no reemplazar
          _especies.addAll(data['especies'] as List<EspecieCatalogoModel>);
          _paginaActual = siguientePagina;
          _hayMas = data['hayMas'] as bool;
          _cargandoMas = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  /// Abre el bottom sheet de filtros
  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltrosSheet(
        estadosSeleccionados: _estadosFiltro,
        habitatsSeleccionados: _habitatsFiltro,
        regionesSeleccionadas: _regionesFiltro,
        soloVistas: _soloVistas,
        idUsuario: _idUsuario,
        onAplicar: (estados, habitats, regiones, soloVistas) {
          setState(() {
            _estadosFiltro = estados;
            _habitatsFiltro = habitats;
            _regionesFiltro = regiones;
            _soloVistas = soloVistas;
          });
          _cargarEspecies();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      child: AppBackground(
        imagePath: AppBackgrounds.catalog,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildBuscador(),
              _buildCategoriaChips(),
              _buildOrdenYFiltros(),
              const Divider(height: 1),
              Expanded(child: _buildListado()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catálogo de Especies',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.successGreen,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$_totalEspecies especies registradas',
            style: TextStyle(fontSize: 13, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      // ── Sombra sobre el campo de búsqueda ──────────────────────────────
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) {
            _debounce?.cancel();
            _cargarEspecies();
          },
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 400),
              _cargarEspecies,
            );
          },
          decoration: InputDecoration(
            hintText: 'Buscar especie...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.textGray),
            // Quitar borde propio del TextField para que no compita con la sombra
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _debounce?.cancel();
                      _searchController.clear();
                      _cargarEspecies();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriaChips() {
    return Padding(
      // Mismo padding horizontal que buscador y botones de filtrado
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 52, // altura extra para que la sombra inferior no se recorte
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          // Sin Clip.none — el Padding horizontal delimita el área scroll
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          itemCount: _categorias.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = _categorias[i];
            final isActive =
                _categoriaActiva == cat['valor'] ||
                (_categoriaActiva == null && cat['valor'] == '');
            // ── Sombra en cada chip de categoría ───────────────────────
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FilterChip(
                label: Text(cat['label']!),
                selected: isActive,
                onSelected: (_) {
                  setState(
                    () => _categoriaActiva = cat['valor']!.isEmpty
                        ? null
                        : cat['valor'],
                  );
                  _cargarEspecies();
                },
                selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.primaryGreen,
                labelStyle: TextStyle(
                  color: isActive ? AppTheme.primaryGreen : AppTheme.textGray,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isActive ? AppTheme.primaryGreen : AppTheme.lightGray,
                ),
                backgroundColor: AppTheme.cardWhite,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrdenYFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Row(
        children: [
          // ── Toggle de orden con sombra ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() => _orden = _orden == 'asc' ? 'desc' : 'asc');
                _cargarEspecies();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Text(
                      'Ordenar por: ${_orden == 'asc' ? 'A-Z' : 'Z-A'}',
                      style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // ── Botón de filtros con sombra ─────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _abrirFiltros,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 16, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Badge si hay filtros activos
                    if (_estadosFiltro.isNotEmpty ||
                        _habitatsFiltro.isNotEmpty ||
                        _regionesFiltro.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_estadosFiltro.length + _habitatsFiltro.length + _regionesFiltro.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListado() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_especies.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _cargarEspecies,
      child: ListView.builder(
        controller: _scrollController, // ← conectar el controller
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        // +1 para el spinner al final
        itemCount: _especies.length + (_hayMas ? 1 : 0),
        itemBuilder: (_, i) {
          // Último item — spinner de carga
          if (i == _especies.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EspecieCard(especie: _especies[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppTheme.lightGray),
            const SizedBox(height: 16),
            Text(
              'Información no encontrada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron especies que coincidan con tu búsqueda. Intenta con otros términos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
