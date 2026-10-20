import 'package:chiledex/features/home/presentation/widgets/app_button.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/especie_model.dart';
import '../../../../core/models/region_model.dart';
import '../../../../core/services/especie_service.dart';

class FiltrosSheet extends StatefulWidget {
  final List<String> estadosSeleccionados;
  final List<int> habitatsSeleccionados;
  final List<int> regionesSeleccionadas;
  final bool? soloVistas; // ← nuevo
  final int? idUsuario; // ← nuevo
  final void Function(
    List<String> estados,
    List<int> habitats,
    List<int> regiones,
    bool? soloVistas, // ← nuevo
  )
  onAplicar;

  const FiltrosSheet({
    super.key,
    required this.estadosSeleccionados,
    required this.habitatsSeleccionados,
    required this.regionesSeleccionadas,
    required this.onAplicar,
    this.soloVistas,
    this.idUsuario,
  });

  @override
  State<FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<FiltrosSheet> {
  final _service = EspecieService();

  late List<String> _estados;
  late List<int> _habitats;
  late List<int> _regiones;
  bool? _soloVistas; // ← nuevo

  List<ConteoEstadoModel> _conteos = [];
  List<Map<String, dynamic>> _habitatsList = [];
  List<RegionModel> _regionesList = [];

  @override
  void initState() {
    super.initState();
    _estados = List.from(widget.estadosSeleccionados);
    _habitats = List.from(widget.habitatsSeleccionados);
    _regiones = List.from(widget.regionesSeleccionadas);
    _soloVistas = widget.soloVistas; // ← nuevo
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    final results = await Future.wait([
      _service.obtenerConteoEstados(),
      _service.obtenerHabitats(),
      _service.obtenerRegiones(),
    ]);
    if (mounted) {
      setState(() {
        _conteos = results[0] as List<ConteoEstadoModel>;
        _habitatsList = results[1] as List<Map<String, dynamic>>;
        _regionesList = results[2] as List<RegionModel>;
      });
    }
  }

  void _limpiar() => setState(() {
    _estados = [];
    _habitats = [];
    _regiones = [];
    _soloVistas = null; // ← limpiar también
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Text(
                  'Filtrar especies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                Icon(Icons.settings_outlined, color: AppTheme.textGray),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEstados(),
                  const SizedBox(height: 20),
                  _buildRegiones(),
                  const SizedBox(height: 20),
                  _buildHabitats(),
                  // Solo mostrar si hay usuario logueado
                  if (widget.idUsuario != null) ...[
                    const SizedBox(height: 20),
                    _buildDescubrimiento(), // ← nuevo
                  ],
                  const SizedBox(height: 24),
                  _buildBotones(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryGreen,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _buildEstados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('ESTADO DE CONSERVACIÓN'),
        ..._conteos.map((c) {
          final selected = _estados.contains(c.estado);
          return CheckboxListTile(
            value: selected,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primaryGreen,
            title: Row(
              children: [
                Expanded(
                  child: Text(c.estado, style: const TextStyle(fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${c.cantidad}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                ),
              ],
            ),
            onChanged: (v) => setState(() {
              v! ? _estados.add(c.estado) : _estados.remove(c.estado);
            }),
          );
        }),
      ],
    );
  }

  Widget _buildRegiones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('REGIÓN DE AVISTAMIENTO'),
        _regionesList.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2,
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _regionesList.map((r) {
                  final selected = _regiones.contains(r.id);
                  return ChoiceChip(
                    label: Text(
                      r.nombre
                          .replaceAll('Región de la ', '')
                          .replaceAll('Región del ', '')
                          .replaceAll('Región de ', '')
                          .replaceAll('Región ', ''),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      selected ? _regiones.remove(r.id) : _regiones.add(r.id);
                    }),
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.primaryGreen
                          : AppTheme.textGray,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.primaryGreen
                          : AppTheme.lightGray,
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildHabitats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('HÁBITAT'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _habitatsList.map((h) {
            final id = h['id'] as int;
            final selected = _habitats.contains(id);
            return ChoiceChip(
              label: Text(h['nombre'] as String),
              selected: selected,
              onSelected: (_) => setState(() {
                selected ? _habitats.remove(id) : _habitats.add(id);
              }),
              selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected ? AppTheme.primaryGreen : AppTheme.textGray,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? AppTheme.primaryGreen : AppTheme.lightGray,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Filtro de especies vistas/no vistas — solo aparece si hay usuario
  Widget _buildDescubrimiento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('MIS ESPECIES'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chipVistas(label: 'Todas', valor: null),
            _chipVistas(label: 'Vistas', valor: true),
            _chipVistas(label: 'No vistas', valor: false),
          ],
        ),
      ],
    );
  }

  Widget _chipVistas({required String label, required bool? valor}) {
    final selected = _soloVistas == valor;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _soloVistas = valor),
      selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryGreen : AppTheme.textGray,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? AppTheme.primaryGreen : AppTheme.lightGray,
      ),
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Limpiar',
            type: AppButtonType.outline,
            height: 48,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            onPressed: _limpiar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Aplicar',
            height: 48,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            onPressed: () {
              Navigator.pop(context);
              widget.onAplicar(
                _estados,
                _habitats,
                _regiones,
                _soloVistas, // ← pasar el nuevo filtro
              );
            },
          ),
        ),
      ],
    );
  }
}
