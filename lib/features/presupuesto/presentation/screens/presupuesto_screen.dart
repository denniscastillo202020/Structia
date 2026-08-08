import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/presupuesto/domain/actividad_mano_de_obra.dart';
import 'package:structia/features/presupuesto/domain/calcular_planificacion.dart';

String _formatoL(double valor) {
  final entero = valor.round();
  final texto = entero.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write(',');
    buffer.write(texto[i]);
  }
  return 'L ${buffer.toString()}';
}

class PresupuestoScreen extends StatefulWidget {
  const PresupuestoScreen({super.key});

  @override
  State<PresupuestoScreen> createState() => _PresupuestoScreenState();
}

class _PresupuestoScreenState extends State<PresupuestoScreen> {
  // --- Planificación ---
  final _montoObraController = TextEditingController(text: '1500000');
  ResultadoPlanificacion? _resultadoPlanificacion;

  // --- Mano de obra ---
  late final List<TextEditingController> _controladoresPrecio;
  late final List<TextEditingController> _controladoresCantidad;

  // --- Área de muros calculada en "Muros y bloques" ---
  double? _areaMurosGuardadaM2;

  @override
  void initState() {
    super.initState();
    _controladoresPrecio = ActividadManoDeObra.tabla
        .map((a) => TextEditingController(text: a.precioReferenciaL.toStringAsFixed(0)))
        .toList();
    _controladoresCantidad =
        ActividadManoDeObra.tabla.map((_) => TextEditingController()).toList();
    _cargarAreaMuros();
  }

  Future<void> _cargarAreaMuros() async {
    final calculos = await RepositorioCalculosGuardados.listar();
    final total = calculos
        .where((c) => c.tipo == 'Mampostería')
        .fold(0.0, (s, c) => s + (c.areaNetaM2 ?? 0));
    if (mounted) setState(() => _areaMurosGuardadaM2 = total > 0 ? total : null);
  }

  int get _indiceActividadBloque =>
      ActividadManoDeObra.tabla.indexWhere((a) => a.nombre.startsWith('Pega de bloque'));

  void _usarAreaDeMuros() {
    final indice = _indiceActividadBloque;
    if (indice == -1 || _areaMurosGuardadaM2 == null) return;
    setState(() {
      _controladoresCantidad[indice].text = _areaMurosGuardadaM2!.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _montoObraController.dispose();
    for (final c in _controladoresPrecio) {
      c.dispose();
    }
    for (final c in _controladoresCantidad) {
      c.dispose();
    }
    super.dispose();
  }

  void _calcularPlanificacion() {
    final monto = double.tryParse(_montoObraController.text.replaceAll(',', ''));
    if (monto == null || monto <= 0) return;
    setState(() {
      _resultadoPlanificacion = CalcularPlanificacion()(montoObraL: monto);
    });
  }

  double get _totalManoDeObra {
    var total = 0.0;
    for (var i = 0; i < ActividadManoDeObra.tabla.length; i++) {
      final precio = double.tryParse(_controladoresPrecio[i].text.replaceAll(',', '')) ?? 0;
      final cantidad = double.tryParse(_controladoresCantidad[i].text.replaceAll(',', '.')) ?? 0;
      total += precio * cantidad;
    }
    return total;
  }

  List<Map<String, String>> get _filasConCantidad {
    final filas = <Map<String, String>>[];
    for (var i = 0; i < ActividadManoDeObra.tabla.length; i++) {
      final actividad = ActividadManoDeObra.tabla[i];
      final precio = double.tryParse(_controladoresPrecio[i].text.replaceAll(',', '')) ?? 0;
      final cantidad = double.tryParse(_controladoresCantidad[i].text.replaceAll(',', '.')) ?? 0;
      if (cantidad <= 0) continue;
      filas.add({
        'etiqueta': '${actividad.nombre} (${cantidad.toStringAsFixed(2)} ${actividad.unidad})',
        'valor': _formatoL(precio * cantidad),
      });
    }
    return filas;
  }

  Future<void> _guardarPresupuesto() async {
    final filas = _filasConCantidad;
    if (filas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa al menos una cantidad para guardar')),
      );
      return;
    }
    await RepositorioCalculosGuardados.guardar(CalculoGuardado(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      tipo: 'Presupuesto',
      titulo: 'Presupuesto de mano de obra',
      subtitulo: '${filas.length} actividades · ${_formatoL(_totalManoDeObra)}',
      fecha: DateTime.now(),
      filas: filas,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado en "Mis cálculos guardados"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Costos y mano de obra')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text('Planificación profesional', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _montoObraController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Costo total estimado de la obra',
              prefixText: 'L ',
            ),
            onChanged: (_) => _calcularPlanificacion(),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          FilledButton.icon(
            onPressed: _calcularPlanificacion,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular'),
          ),
          if (_resultadoPlanificacion != null) ...[
            const SizedBox(height: AppConstants.paddingMd),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilaPresupuesto('Honorario (3%, menor experiencia)',
                        _formatoL(_resultadoPlanificacion!.honorarioMinimoL)),
                    _FilaPresupuesto('Honorario (5%, mayor trayectoria)',
                        _formatoL(_resultadoPlanificacion!.honorarioMaximoL)),
                    const Divider(),
                    _FilaPresupuesto(
                      'Riesgo de no planificar (sobrecosto 7-10%)',
                      '${_formatoL(_resultadoPlanificacion!.sobrecostoMinimoNoPlanificarL)} – ${_formatoL(_resultadoPlanificacion!.sobrecostoMaximoNoPlanificarL)}',
                    ),
                    _FilaPresupuesto(
                      'Supervisión de un profesional (15-30%)',
                      '${_formatoL(_resultadoPlanificacion!.supervisionMinimaL)} – ${_formatoL(_resultadoPlanificacion!.supervisionMaximaL)}',
                    ),
                    const SizedBox(height: AppConstants.paddingSm),
                    Text(
                      'El 3%-5% típicamente incluye anteproyecto, planos firmados y timbrados, '
                      'lista de actividades con precios unitarios, lista de materiales y '
                      'especificaciones técnicas. NO incluye levantamiento topográfico, estudio '
                      'de suelos, cálculos especializados ni trámites de permisos.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppConstants.paddingXl),
          Text('Mano de obra por actividad', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Precios de referencia (editables) para obra continua, casas desde 120 m². '
            'No incluyen materiales ni fletes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          ...List.generate(ActividadManoDeObra.tabla.length, (i) {
            final actividad = ActividadManoDeObra.tabla[i];
            final esPegaDeBloque = i == _indiceActividadBloque;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(actividad.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (esPegaDeBloque && _areaMurosGuardadaM2 != null) ...[
                      const SizedBox(height: 4),
                      ActionChip(
                        avatar: const Icon(Icons.grid_view_outlined, size: 16),
                        label: Text(
                            'Usar área de "Muros y bloques": ${_areaMurosGuardadaM2!.toStringAsFixed(2)} m²'),
                        onPressed: _usarAreaDeMuros,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _controladoresCantidad[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Cantidad',
                              suffixText: actividad.unidad,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSm),
                        Expanded(
                          child: TextFormField(
                            controller: _controladoresPrecio[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Precio unitario',
                              prefixText: 'L ',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppConstants.paddingMd),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Total mano de obra', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(
                    _formatoL(_totalManoDeObra),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          OutlinedButton.icon(
            onPressed: () => exportarResultadosPdf(
              titulo: 'Presupuesto de mano de obra',
              subtitulo: 'Total: ${_formatoL(_totalManoDeObra)}',
              filas: _filasConCantidad.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
              nota: 'Precios de referencia, editables por el usuario. No incluye materiales, fletes ni '
                  'sobrecostos de supervisión. Confirma precios vigentes con tu contratista o proveedor local.',
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Guardar / imprimir como PDF'),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          FilledButton.tonalIcon(
            onPressed: _guardarPresupuesto,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar en mi proyecto'),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          Text(
            'Precios de mano de obra tal como los proporcionaste — StructIA no fija ni recomienda '
            'tarifas de mercado. Varían por zona, temporada y contratista; confírmalos siempre antes '
            'de presupuestar formalmente.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _FilaPresupuesto extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _FilaPresupuesto(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(etiqueta)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
