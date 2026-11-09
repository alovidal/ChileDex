import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/especie_model.dart';
import '../../../../core/models/region_model.dart';
import '../../../../core/services/especie_service.dart';
import 'app_button.dart';

class FiltrosSheet extends StatefulWidget {
  final List<String> estadosSeleccionados;
  final List<int>    habitatsSeleccionados;
  final List<int>    regionesSeleccionadas;
  final bool?        soloVistas;
  final int?         idUsuario;
  final void Function(
    List<String> estados,
    List<int>    habitats,
    List<int>    regiones,
    bool?        soloVistas,
  ) onAplicar;

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
  late List<int>    _habitats;
  late List<int>    _regiones;
  bool?             _soloVistas;

  List<ConteoEstadoModel>    _conteos      = [];
  List<Map<String, dynamic>> _habitatsList = [];
  List<RegionModel>          _regionesList = [];
  bool                       _cargando     = true;

  @override
  void initState() {
    super.initState();
    _estados    = List.from(widget.estadosSeleccionados);
    _habitats   = List.from(widget.habitatsSeleccionados);
    _regiones   = List.from(widget.regionesSeleccionadas);
    _soloVistas = widget.soloVistas;
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    final results = await Future.wait([
      _service.obtenerConteoEstados(),
      _service.obtenerHabitats(),
      _service.obtenerRegiones(),
    ]);
    if (mounted) setState(() {
      _conteos      = results[0] as List<ConteoEstadoModel>;
      _habitatsList = results[1] as List<Map<String, dynamic>>;
      _regionesList = results[2] as List<RegionModel>;
      _cargando     = false;
    });
  }

  void _limpiar() => setState(() {
    _estados    = [];
    _habitats   = [];
    _regiones   = [];
    _soloVistas = null;
  });

  /// Texto resumen de los seleccionados para mostrar en el combo
  String _resumenEstados() {
    if (_estados.isEmpty) return 'Todos';
    if (_estados.length == 1) return _estados.first;
    return '${_estados.length} seleccionados';
  }

  String _resumenHabitats() {
    if (_habitats.isEmpty) return 'Todos';
    if (_habitats.length == 1) {
      return _habitatsList
          .firstWhere((h) => h['id'] == _habitats.first,
              orElse: () => {'nombre': ''})['nombre'] as String;
    }
    return '${_habitats.length} seleccionados';
  }

  String _resumenRegiones() {
    if (_regiones.isEmpty) return 'Todas';
    if (_regiones.length == 1) {
      final r = _regionesList.firstWhere(
          (r) => r.id == _regiones.first,
          orElse: () => RegionModel(id: 0, nombre: ''));
      return r.nombre
          .replaceAll('Región de la ', '')
          .replaceAll('Región del ', '')
          .replaceAll('Región de ', '')
          .replaceAll('Región ', '');
    }
    return '${_regiones.length} seleccionadas';
  }

  String _resumenVistas() {
    if (_soloVistas == null)  return 'Todas';
    if (_soloVistas == true)  return 'Vistas';
    return 'No vistas';
  }

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
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Text('Filtrar especies',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    )),
                const Spacer(),
                Icon(Icons.tune, color: AppTheme.textGray),
              ],
            ),
          ),

          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCombo(
                      label:   'ESTADO DE CONSERVACIÓN',
                      resumen: _resumenEstados(),
                      child:   _buildEstados(),
                    ),
                    const SizedBox(height: 12),
                    _buildCombo(
                      label:   'REGIÓN DE AVISTAMIENTO',
                      resumen: _resumenRegiones(),
                      child:   _buildRegiones(),
                    ),
                    const SizedBox(height: 12),
                    _buildCombo(
                      label:   'HÁBITAT',
                      resumen: _resumenHabitats(),
                      child:   _buildHabitats(),
                    ),
                    if (widget.idUsuario != null) ...[
                      const SizedBox(height: 12),
                      _buildCombo(
                        label:   'MIS ESPECIES',
                        resumen: _resumenVistas(),
                        child:   _buildDescubrimiento(),
                      ),
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

  /// Envuelve cualquier sección en un ExpansionTile estilo combo
  Widget _buildCombo({
    required String label,
    required String resumen,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:        AppTheme.backgroundCream,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppTheme.lightGray),
      ),
      child: ExpansionTile(
        tilePadding:      const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding:  const EdgeInsets.fromLTRB(16, 0, 16, 12),
        collapsedShape:   RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        shape:            RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        iconColor:        AppTheme.primaryGreen,
        collapsedIconColor: AppTheme.textGray,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen, letterSpacing: 0.8,
              ),
            ),
            Text(
              resumen,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: resumen == 'Todas' || resumen == 'Todos'
                    ? AppTheme.textGray
                    : AppTheme.textDark,
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildEstados() {
    return Column(
      children: _conteos.map((c) {
        final selected = _estados.contains(c.estado);
        return CheckboxListTile(
          value:          selected,
          dense:          true,
          contentPadding: EdgeInsets.zero,
          activeColor:    AppTheme.primaryGreen,
          title: Row(
            children: [
              Expanded(child: Text(c.estado,
                  style: const TextStyle(fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:        AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${c.cantidad}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textGray)),
              ),
            ],
          ),
          onChanged: (v) => setState(() {
            v! ? _estados.add(c.estado) : _estados.remove(c.estado);
          }),
        );
      }).toList(),
    );
  }

  Widget _buildRegiones() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _regionesList.map((r) {
        final selected = _regiones.contains(r.id);
        return FilterChip(
          label: Text(
            r.nombre
                .replaceAll('Región de la ', '')
                .replaceAll('Región del ', '')
                .replaceAll('Región de ', '')
                .replaceAll('Región ', ''),
            style: TextStyle(
              fontSize: 12,
              color: selected ? AppTheme.primaryGreen : AppTheme.textGray,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected:      selected,
          onSelected:    (_) => setState(() {
            selected ? _regiones.remove(r.id) : _regiones.add(r.id);
          }),
          selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
          checkmarkColor: AppTheme.primaryGreen,
          side: BorderSide(
            color: selected ? AppTheme.primaryGreen : AppTheme.lightGray,
          ),
          backgroundColor: AppTheme.cardWhite,
        );
      }).toList(),
    );
  }

  Widget _buildHabitats() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _habitatsList.map((h) {
        final id       = h['id'] as int;
        final selected = _habitats.contains(id);
        return FilterChip(
          label: Text(
            h['nombre'] as String,
            style: TextStyle(
              fontSize: 12,
              color: selected ? AppTheme.primaryGreen : AppTheme.textGray,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected:       selected,
          onSelected:     (_) => setState(() {
            selected ? _habitats.remove(id) : _habitats.add(id);
          }),
          selectedColor:  AppTheme.primaryGreen.withOpacity(0.15),
          checkmarkColor: AppTheme.primaryGreen,
          side: BorderSide(
            color: selected ? AppTheme.primaryGreen : AppTheme.lightGray,
          ),
          backgroundColor: AppTheme.cardWhite,
        );
      }).toList(),
    );
  }

  Widget _buildDescubrimiento() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        _chipVistas(label: 'Todas',     valor: null),
        _chipVistas(label: 'Vistas',    valor: true),
        _chipVistas(label: 'No vistas', valor: false),
      ],
    );
  }

  Widget _chipVistas({required String label, required bool? valor}) {
    final selected = _soloVistas == valor;
    return FilterChip(
      label: Text(label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppTheme.primaryGreen : AppTheme.textGray,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          )),
      selected:       selected,
      onSelected:     (_) => setState(() => _soloVistas = valor),
      selectedColor:  AppTheme.primaryGreen.withOpacity(0.15),
      checkmarkColor: AppTheme.primaryGreen,
      side: BorderSide(
        color: selected ? AppTheme.primaryGreen : AppTheme.lightGray,
      ),
      backgroundColor: AppTheme.cardWhite,
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label:     'Limpiar',
            type:      AppButtonType.outline,
            height:    48,
            onPressed: _limpiar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label:     'Aplicar',
            icon:      Icons.check,
            height:    48,
            onPressed: () {
              Navigator.pop(context);
              widget.onAplicar(
                _estados, _habitats, _regiones, _soloVistas,
              );
            },
          ),
        ),
      ],
    );
  }
}