import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';

class CalculadoraConcretoScreen extends StatefulWidget {
  const CalculadoraConcretoScreen({super.key});

  @override
  State<CalculadoraConcretoScreen> createState() => _CalculadoraConcretoScreenState();
}

class _CalculadoraConcretoScreenState extends State<CalculadoraConcretoScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _usarDimensiones = false;

  final _volumenController = TextEditingController();
  final _largoController = TextEditingController();
  final _anchoController = TextEditingController();
  final _altoController = TextEditingController();

  DosificacionConcreto _dosificacion = DosificacionConcreto.tabla[2]; // f'c 210, uso general
  ResultadoMaterialesConcreto? _resultado;

  @override
  void dispose() {
    _volumenController.dispose();
    _largoController.dispose();
    _anchoController.dispose();
    _altoController.dispose();
    super.dispose();
  }

  double? _obtenerVolumen() {
    if (_usarDimensiones) {
      final largo = double.tryParse(_largoController.text.replaceAll(',', '.'));
      final ancho = double.tryParse(_anchoController.text.replaceAll(',', '.'));
      final alto = double.tryParse(_altoController.text.replaceAll(',', '.'));
      if (largo == null || ancho == null || alto == null) return null;
      return largo * ancho * alto;
    }
    return double.tryParse(_volumenController.text.replaceAll(',', '.'));
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;

    final volumen = _obtenerVolumen();
    if (volumen == null || volumen <= 0) return;

    final resultado = CalcularMaterialesConcreto()(
      volumenM3: volumen,
      dosificacion: _dosificacion,
    );

    setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Concreto y agregados')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Volumen (m³)')),
                ButtonSegment(value: true, label: Text('Largo x Ancho x Alto')),
              ],
              selected: {_usarDimensiones},
              onSelectionChanged: (s) => setState(() {
                _usarDimensiones = s.first;
                _resultado = null;
              }),
            ),
            const SizedBox(height: AppConstants.paddingMd),
            if (!_usarDimensiones)
              TextFormField(
                controller: _volumenController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Volumen de concreto (m³)',
                  suffixText: 'm³',
                ),
                validator: (v) {
                  final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (val == null || val <= 0) return 'Ingresa un volumen válido';
                  return null;
                },
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _largoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Largo (m)'),
                      validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSm),
                  Expanded(
                    child: TextFormField(
                      controller: _anchoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Ancho (m)'),
                      validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSm),
                  Expanded(
                    child: TextFormField(
                      controller: _altoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Alto (m)'),
                      validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppConstants.paddingLg),
            Text("Resistencia del concreto (f'c)", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Según tabla práctica de dosificación en volumen, uso común en obra menor y mediana',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            ...DosificacionConcreto.tabla.map((d) {
              final seleccionada = _dosificacion.fc == d.fc;
              return Card(
                color: seleccionada
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                    : null,
                child: RadioListTile<int>(
                  value: d.fc,
                  groupValue: _dosificacion.fc,
                  onChanged: (_) => setState(() {
                    _dosificacion = d;
                    _resultado = null;
                  }),
                  title: Text("f'c = ${d.fc} kg/cm²  ·  ${d.proporcion}"),
                  subtitle: Text(d.usoTypico),
                ),
              );
            }),
            const SizedBox(height: AppConstants.paddingLg),
            FilledButton.icon(
              onPressed: _calcular,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular materiales'),
            ),
            if (_resultado != null) ...[
              const SizedBox(height: AppConstants.paddingLg),
              _TarjetaResultadoConcreto(resultado: _resultado!, dosificacion: _dosificacion),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaResultadoConcreto extends StatelessWidget {
  final ResultadoMaterialesConcreto resultado;
  final DosificacionConcreto dosificacion;

  const _TarjetaResultadoConcreto({required this.resultado, required this.dosificacion});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Materiales para ${resultado.volumenM3.toStringAsFixed(2)} m³',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              "f'c = ${dosificacion.fc} kg/cm² · grava recomendada ${dosificacion.tamanoAgregadoRecomendado}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppConstants.paddingMd),
            _FilaResultado(
              icono: Icons.inventory_2_outlined,
              etiqueta: 'Cemento (sacos de 42.5 kg)',
              valor: resultado.bolsasCemento.ceil().toString(),
            ),
            _FilaResultado(
              icono: Icons.grain,
              etiqueta: 'Arena',
              valor: '${resultado.arenaM3.toStringAsFixed(2)} m³',
            ),
            _FilaResultado(
              icono: Icons.landscape_outlined,
              etiqueta: 'Grava ${dosificacion.tamanoAgregadoRecomendado}',
              valor: '${resultado.gravaM3.toStringAsFixed(2)} m³',
            ),
            _FilaResultado(
              icono: Icons.water_drop_outlined,
              etiqueta: 'Agua',
              valor: '${resultado.aguaLitros.toStringAsFixed(0)} L',
            ),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Materiales de concreto',
                subtitulo:
                    "f'c = ${dosificacion.fc} kg/cm² · ${dosificacion.proporcion} · ${resultado.volumenM3.toStringAsFixed(2)} m³",
                filas: [
                  FilaPdf('Cemento (sacos de 42.5 kg)', resultado.bolsasCemento.ceil().toString()),
                  FilaPdf('Arena', '${resultado.arenaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Grava ${dosificacion.tamanoAgregadoRecomendado}',
                      '${resultado.gravaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Agua', '${resultado.aguaLitros.toStringAsFixed(0)} L'),
                ],
                nota:
                    'Tabla práctica de campo (proporción en volumen), alineada a criterios ACI 211.1 para obra menor y mediana. '
                    'Para elementos estructurales con resistencia garantizada, confirma la dosificación con un diseño de mezcla '
                    'de laboratorio y el criterio de un ingeniero — los agregados varían de una cantera a otra.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            Text(
              'Tabla práctica de campo (proporción en volumen). Para elementos estructurales con resistencia garantizada, confirma la dosificación con un diseño de mezcla de laboratorio — los agregados varían de una cantera a otra.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaResultado extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaResultado({required this.icono, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppConstants.paddingSm),
          Expanded(child: Text(etiqueta)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
