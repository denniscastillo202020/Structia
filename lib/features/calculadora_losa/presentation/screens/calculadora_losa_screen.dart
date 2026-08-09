import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';
import 'package:structia/features/calculadora_losa/domain/calcular_losa_lamina.dart';

class CalculadoraLosaScreen extends StatefulWidget {
  const CalculadoraLosaScreen({super.key});

  @override
  State<CalculadoraLosaScreen> createState() => _CalculadoraLosaScreenState();
}

class _CalculadoraLosaScreenState extends State<CalculadoraLosaScreen> {
  final List<AmbienteLosa> _ambientes = [];
  int _contador = 0;

  final _separacionController = TextEditingController(text: '0.50');
  final _espesorController = TextEditingController(text: '0.06');
  final _desperdicioController = TextEditingController(text: '10');
  TipoTubo _tipoTubo = TipoTubo.cuadrado4x4;
  DosificacionConcreto _dosificacion = DosificacionConcreto.tabla[2]; // f'c=210, uso general

  ResultadoLosa? _resultado;

  @override
  void dispose() {
    _separacionController.dispose();
    _espesorController.dispose();
    _desperdicioController.dispose();
    super.dispose();
  }

  double? _num(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  Future<void> _agregarAmbiente() async {
    final resultado = await _mostrarDialogoAmbiente();
    if (resultado == null || !mounted) return;
    setState(() {
      _contador++;
      _ambientes.add(AmbienteLosa(
        id: 'l$_contador',
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
                  decoration: const InputDecoration(labelText: 'Cantidad de ambientes iguales'),
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
    final separacion = _num(_separacionController.text);
    final espesor = _num(_espesorController.text);
    final desperdicio = _num(_desperdicioController.text);
    if (separacion == null || separacion <= 0) return;
    if (espesor == null || espesor <= 0) return;
    if (desperdicio == null || desperdicio < 0) return;

    final resultado = CalcularLosaLamina()(
      ambientes: _ambientes,
      separacionTubosM: separacion,
      espesorConcretoM: espesor,
      tipoTubo: _tipoTubo,
      dosificacion: _dosificacion,
      porcentajeDesperdicio: desperdicio,
    );
    setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Losa con lámina y tubo')),
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
          Text('Estructura', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          DropdownButtonFormField<TipoTubo>(
            initialValue: _tipoTubo,
            decoration: const InputDecoration(labelText: 'Tipo de tubo (vigueta)'),
            items: TipoTubo.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.etiqueta)))
                .toList(),
            onChanged: (v) => setState(() {
              _tipoTubo = v ?? _tipoTubo;
              _resultado = null;
            }),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _separacionController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Separación entre tubos',
              suffixText: 'm',
              helperText: 'Ej. 0.50 o 0.60 — según tu diseño',
            ),
            onChanged: (_) => setState(() => _resultado = null),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _espesorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Espesor del concreto sobre la lámina',
              suffixText: 'm',
              helperText: 'Ej. 0.05 a 0.07 m (5 a 7 cm)',
            ),
            onChanged: (_) => setState(() => _resultado = null),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          DropdownButtonFormField<DosificacionConcreto>(
            initialValue: _dosificacion,
            decoration: const InputDecoration(labelText: 'Resistencia del concreto'),
            items: DosificacionConcreto.tabla
                .map((d) => DropdownMenuItem(value: d, child: Text(d.etiqueta)))
                .toList(),
            onChanged: (v) => setState(() {
              _dosificacion = v ?? _dosificacion;
              _resultado = null;
            }),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _desperdicioController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Desperdicio (tubo, lámina, malla)',
              suffixText: '%',
            ),
            onChanged: (_) => setState(() => _resultado = null),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular materiales'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoLosa(resultado: _resultado!, ambientes: List.of(_ambientes)),
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

class _TarjetaResultadoLosa extends StatelessWidget {
  final ResultadoLosa resultado;
  final List<AmbienteLosa> ambientes;

  const _TarjetaResultadoLosa({required this.resultado, required this.ambientes});

  List<Map<String, String>> get _filasDetalladas {
    return [
      {'etiqueta': 'Área total', 'valor': '${resultado.areaTotalM2.toStringAsFixed(1)} m²'},
      {
        'etiqueta': resultado.tipoTubo.etiqueta,
        'valor': '${resultado.tuboPiezas} piezas (6 m c/u) · '
            '${resultado.tuboMetrosLineales.toStringAsFixed(1)} m',
      },
      {
        'etiqueta': 'Separación entre tubos',
        'valor': '${resultado.separacionTubosM.toStringAsFixed(2)} m',
      },
      {
        'etiqueta': 'Lámina aluzín',
        'valor': '${resultado.laminaPiezas} piezas · '
            '${resultado.laminaMetrosLineales.toStringAsFixed(1)} m lineales',
      },
      {
        'etiqueta': 'Malla electrosoldada',
        'valor': '${resultado.mallaHojas} hoja(s) (2.30 × 6.00 m)',
      },
      {'etiqueta': 'Tornillos', 'valor': resultado.tornillos.toString()},
      {
        'etiqueta': 'Volumen de concreto',
        'valor': '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³',
      },
      {
        'etiqueta': 'Cemento (sacos 42.5 kg)',
        'valor': resultado.concreto.bolsasCemento.toStringAsFixed(1),
      },
      {'etiqueta': 'Arena', 'valor': '${resultado.concreto.arenaM3.toStringAsFixed(2)} m³'},
      {'etiqueta': 'Grava', 'valor': '${resultado.concreto.gravaM3.toStringAsFixed(2)} m³'},
      {'etiqueta': 'Agua', 'valor': '${resultado.concreto.aguaLitros.toStringAsFixed(0)} L'},
    ];
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
            Text('${resultado.areaTotalM2.toStringAsFixed(1)} m² de losa',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.paddingMd),
            ..._filasDetalladas.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(f['etiqueta']!)),
                      Text(f['valor']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Losa con lámina y tubo',
                subtitulo: '${ambientes.length} ambiente(s), '
                    '${resultado.areaTotalM2.toStringAsFixed(1)} m² totales',
                filas: _filasDetalladas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota: 'Estimación de campo de materiales para losa con estructura de tubo, '
                    'lámina troquelada (aluzín) como cimbra permanente, malla electrosoldada y '
                    'concreto. El diseño estructural real (calibre de tubo y lámina, separación '
                    'máxima según carga y claro, refuerzo adicional) debe confirmarlo un '
                    'ingeniero estructural antes de construir.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Losa',
                  titulo: 'Losa ${resultado.areaTotalM2.toStringAsFixed(1)} m²',
                  subtitulo: '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³ concreto · '
                      '${resultado.tuboPiezas} tubos',
                  fecha: DateTime.now(),
                  filas: _filasDetalladas,
                  areaNetaM2: resultado.areaTotalM2,
                  volumenConcretoM3: resultado.volumenConcretoM3,
                  bolsasCemento: resultado.concreto.bolsasCemento,
                  arenaM3: resultado.concreto.arenaM3,
                  gravaM3: resultado.concreto.gravaM3,
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
              '⚠ Estimación de campo. El diseño estructural (calibre de tubo/lámina, separación '
              'máxima según carga y claro) debe confirmarlo un ingeniero.',
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
