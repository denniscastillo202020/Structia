import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_cielo_pvc/domain/calcular_cielo_pvc.dart';

class CalculadoraCieloPvcScreen extends StatefulWidget {
  const CalculadoraCieloPvcScreen({super.key});

  @override
  State<CalculadoraCieloPvcScreen> createState() => _CalculadoraCieloPvcScreenState();
}

class _CalculadoraCieloPvcScreenState extends State<CalculadoraCieloPvcScreen> {
  final List<AmbienteCieloPvc> _ambientes = [];
  int _contador = 0;

  final _desperdicioController = TextEditingController(text: '10');
  bool _climaCaliente = false;

  ResultadoCieloPvc? _resultado;

  @override
  void dispose() {
    _desperdicioController.dispose();
    super.dispose();
  }

  double? _num(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  Future<void> _agregarAmbiente() async {
    final resultado = await _mostrarDialogoAmbiente();
    if (resultado == null || !mounted) return;
    setState(() {
      _contador++;
      _ambientes.add(AmbienteCieloPvc(
        id: 'a$_contador',
        etiqueta: resultado.etiqueta,
        largoM: resultado.largo,
        anchoM: resultado.ancho,
        cantidad: resultado.cantidad,
      ));
      _resultado = null;
    });
  }

  Future<_DatosAmbiente?> _mostrarDialogoAmbiente() {
    final nombreController =
        TextEditingController(text: 'Ambiente ${_ambientes.length + 1}');
    final largoController = TextEditingController();
    final anchoController = TextEditingController();
    final cantidadController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    return showDialog<_DatosAmbiente>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir ambiente'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre / referencia'),
                ),
                const SizedBox(height: AppConstants.paddingSm),
                TextFormField(
                  controller: largoController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Largo', suffixText: 'm'),
                  validator: (v) {
                    final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Requerido';
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingSm),
                TextFormField(
                  controller: anchoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Ancho', suffixText: 'm'),
                  validator: (v) {
                    final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Requerido';
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingSm),
                TextFormField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de ambientes iguales',
                  ),
                  validator: (v) {
                    final val = int.tryParse((v ?? '').trim());
                    if (val == null || val <= 0) return 'Requerido';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                _DatosAmbiente(
                  etiqueta: nombreController.text.trim().isEmpty
                      ? 'Ambiente'
                      : nombreController.text.trim(),
                  largo: double.parse(largoController.text.replaceAll(',', '.')),
                  ancho: double.parse(anchoController.text.replaceAll(',', '.')),
                  cantidad: int.parse(cantidadController.text.trim()),
                ),
              );
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _calcular() {
    if (_ambientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un ambiente')),
      );
      return;
    }
    final desperdicio = _num(_desperdicioController.text);
    if (desperdicio == null || desperdicio < 0) return;
    final resultado = CalcularCieloPvc()(
      ambientes: _ambientes,
      porcentajeDesperdicio: desperdicio,
      climaCaliente: _climaCaliente,
    );
    setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cielo falso PVC')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text('Ambientes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          if (_ambientes.isEmpty)
            Text('Aún no has añadido ambientes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ..._ambientes.map((a) => Card(
                child: ListTile(
                  title: Text(a.etiqueta),
                  subtitle: Text(
                    '${a.largoM.toStringAsFixed(2)} × ${a.anchoM.toStringAsFixed(2)} m'
                    '${a.cantidad > 1 ? '  ×${a.cantidad}' : ''}'
                    '  ·  ${a.areaM2.toStringAsFixed(1)} m²',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      _ambientes.remove(a);
                      _resultado = null;
                    }),
                  ),
                ),
              )),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton.icon(
            onPressed: _agregarAmbiente,
            icon: const Icon(Icons.add),
            label: const Text('Añadir ambiente'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Opciones', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _desperdicioController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Desperdicio', suffixText: '%'),
            onChanged: (_) => setState(() => _resultado = null),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Clima caliente'),
            subtitle: const Text('Reduce el espaciado del furring channel (omega) a 0.40 m'),
            value: _climaCaliente,
            onChanged: (v) => setState(() {
              _climaCaliente = v;
              _resultado = null;
            }),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular materiales'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoCieloPvc(
              resultado: _resultado!,
              ambientes: List.of(_ambientes),
            ),
          ],
        ],
      ),
    );
  }
}

class _DatosAmbiente {
  final String etiqueta;
  final double largo;
  final double ancho;
  final int cantidad;
  const _DatosAmbiente({
    required this.etiqueta,
    required this.largo,
    required this.ancho,
    required this.cantidad,
  });
}

class _TarjetaResultadoCieloPvc extends StatelessWidget {
  final ResultadoCieloPvc resultado;
  final List<AmbienteCieloPvc> ambientes;

  const _TarjetaResultadoCieloPvc({required this.resultado, required this.ambientes});

  List<Map<String, String>> get _filasDetalladas {
    final filas = <Map<String, String>>[
      {'etiqueta': 'Área total', 'valor': '${resultado.areaTotalM2.toStringAsFixed(1)} m²'},
      {'etiqueta': 'Tablillas PVC', 'valor': resultado.tablillasNecesarias.toString()},
      {'etiqueta': 'Uniones H', 'valor': resultado.unionesH.toString()},
      {
        'etiqueta': 'Cornisa perimetral',
        'valor': '${resultado.cornisaUnidades} unidad(es) (5.95 m c/u)',
      },
      {
        'etiqueta': 'Ángulo perimetral',
        'valor': '${resultado.anguloUnidades} unidad(es) (3.00 m c/u)',
      },
      {
        'etiqueta': 'Furring channel (omega)',
        'valor': '${resultado.metrosOmega.toStringAsFixed(1)} m'
            ' · cada ${resultado.espaciadoOmegaM.toStringAsFixed(2)} m',
      },
      {
        'etiqueta': 'Viguetas metálicas',
        'valor': '${resultado.viguetaUnidades} unidad(es) (3.66 m c/u) '
            '· ${resultado.metrosVigueta.toStringAsFixed(1)} m',
      },
      {'etiqueta': 'Tornillos — tablillas (cabeza lenteja)', 'valor': resultado.tornillosTablillas.toString()},
      {'etiqueta': 'Tornillos — omega a vigueta', 'valor': resultado.amarresOmegaVigueta.toString()},
      {'etiqueta': 'Tornillos — cornisa', 'valor': resultado.tornillosCornisa.toString()},
      {'etiqueta': 'Tarugos/puntillas — ángulo a pared', 'valor': resultado.fijacionesAngulo.toString()},
      {'etiqueta': 'Total tornillos/fijaciones', 'valor': resultado.tornillosTotal.toString()},
    ];
    return filas;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${resultado.areaTotalM2.toStringAsFixed(1)} m² de cielo falso',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.paddingMd),
            if (resultado.detallesPorAmbiente.isNotEmpty) ...[
              Text('Orientación recomendada', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppConstants.paddingSm),
              ...resultado.detallesPorAmbiente.map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(AppConstants.paddingSm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(
                        color: d.requiereUnionH
                            ? Theme.of(context).colorScheme.error.withOpacity(0.4)
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          d.requiereUnionH ? Icons.info_outline : Icons.lightbulb_outline,
                          size: 20,
                          color: d.requiereUnionH
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppConstants.paddingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.etiqueta,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(d.orientacionSugerida,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: AppConstants.paddingLg),
            ],
            Text('Materiales', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            ..._filasDetalladas.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(f['etiqueta']!)),
                      Text(f['valor']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Cielo falso PVC',
                subtitulo: '${ambientes.length} ambiente(s), '
                    '${resultado.areaTotalM2.toStringAsFixed(1)} m² totales',
                filas: _filasDetalladas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota: 'Estimación de campo de materiales para cielo falso de PVC (tablilla 20 cm '
                    'útil × 5.95 m, cornisa y ángulo perimetral, omega cada '
                    '${resultado.espaciadoOmegaM.toStringAsFixed(2)} m, viguetas metálicas de 3.66 m). '
                    'Las medidas comerciales exactas varían según marca y proveedor — confírmalas '
                    'antes de comprar. La estructura de colgado (canal U, tensores) debe '
                    'dimensionarla el instalador según el techo/cercha real.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Cielo falso PVC',
                  titulo: 'Cielo PVC ${resultado.areaTotalM2.toStringAsFixed(1)} m²',
                  subtitulo:
                      '${resultado.tablillasNecesarias} tablillas · ${resultado.cornisaUnidades} cornisas · ${resultado.viguetaUnidades} viguetas',
                  fecha: DateTime.now(),
                  filas: _filasDetalladas,
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Guardado en "Mis cálculos guardados"')),
                  );
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar en mi proyecto'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            Text(
              '⚠ Estimación de campo. Confirma las medidas comerciales exactas del producto '
              '(varían por marca) y la estructura de colgado con tu instalador.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
