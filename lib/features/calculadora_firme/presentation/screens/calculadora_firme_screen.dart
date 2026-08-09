import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';
import 'package:structia/features/calculadora_firme/domain/calcular_firme.dart';

class CalculadoraFirmeScreen extends StatefulWidget {
  const CalculadoraFirmeScreen({super.key});

  @override
  State<CalculadoraFirmeScreen> createState() => _CalculadoraFirmeScreenState();
}

class _CalculadoraFirmeScreenState extends State<CalculadoraFirmeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _largoController = TextEditingController(text: '4');
  final _anchoController = TextEditingController(text: '3');
  final _espesorController = TextEditingController(text: '8');
  final _cantidadController = TextEditingController(text: '1');

  bool _llevaMalla = false;
  DosificacionConcreto _dosificacion = DosificacionConcreto.tabla[1]; // f'c=180, típico de firme

  ResultadoFirme? _resultado;
  DatosFirme? _datosVista;

  @override
  void dispose() {
    _largoController.dispose();
    _anchoController.dispose();
    _espesorController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    final largo = _num(_largoController);
    final ancho = _num(_anchoController);
    final espesor = _num(_espesorController);
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 1;
    if (largo == null || ancho == null || espesor == null) return;

    final datos = DatosFirme(
      largoM: largo,
      anchoM: ancho,
      espesorCm: espesor,
      llevaMalla: _llevaMalla,
      cantidadTramos: cantidad,
    );
    setState(() {
      _datosVista = datos;
      _resultado = CalcularFirme()(datos: datos, dosificacion: _dosificacion);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firme (contrapiso)')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          children: [
            Text(
              'Volumen = largo x ancho x espesor. Solo concreto sobre el terreno compactado, '
              'con malla electrosoldada opcional.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: AppConstants.paddingMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _largoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Largo', suffixText: 'm'),
                    validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSm),
                Expanded(
                  child: TextFormField(
                    controller: _anchoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Ancho', suffixText: 'm'),
                    validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMd),
            TextFormField(
              controller: _espesorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Espesor',
                suffixText: 'cm',
                helperText: 'Típico: 6 a 10 cm',
              ),
              validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text("Resistencia del concreto (f'c)", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Wrap(
              spacing: 8,
              children: DosificacionConcreto.tabla.map((d) {
                return ChoiceChip(
                  label: Text("${d.fc}"),
                  selected: _dosificacion.fc == d.fc,
                  onSelected: (_) => setState(() => _dosificacion = d),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingLg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Llevar malla electrosoldada'),
              subtitle: const Text('Paneles de 2.30 x 6.00 m'),
              value: _llevaMalla,
              onChanged: (v) => setState(() => _llevaMalla = v),
            ),
            const SizedBox(height: AppConstants.paddingMd),
            TextFormField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de tramos iguales',
                helperText: 'Si tienes varios tramos de firme iguales',
              ),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Mínimo 1' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            FilledButton.icon(
              onPressed: _calcular,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular firme'),
            ),
            if (_resultado != null && _datosVista != null) ...[
              const SizedBox(height: AppConstants.paddingLg),
              _TarjetaResultadoFirme(resultado: _resultado!, datos: _datosVista!, dosificacion: _dosificacion),
            ],
            const SizedBox(height: AppConstants.paddingMd),
            Text(
              'Elemento de piso, no estructural. Cuantifica materiales para las dimensiones '
              'que definiste — confirma el espesor y la necesidad de malla con un ingeniero '
              'si el firme irá sometido a cargas importantes.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaResultadoFirme extends StatelessWidget {
  final ResultadoFirme resultado;
  final DatosFirme datos;
  final DosificacionConcreto dosificacion;

  const _TarjetaResultadoFirme({required this.resultado, required this.datos, required this.dosificacion});

  List<Map<String, String>> get _filas {
    return [
      {'etiqueta': 'Área', 'valor': '${resultado.areaM2.toStringAsFixed(1)} m²'},
      {'etiqueta': 'Volumen de concreto', 'valor': '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'},
      {'etiqueta': "f'c", 'valor': "${dosificacion.fc} kg/cm²"},
      {'etiqueta': 'Cemento', 'valor': '${resultado.concreto.bolsasCemento.ceil()} sacos de 42.5 kg'},
      {'etiqueta': 'Arena', 'valor': '${resultado.concreto.arenaM3.toStringAsFixed(2)} m³'},
      {'etiqueta': 'Grava', 'valor': '${resultado.concreto.gravaM3.toStringAsFixed(2)} m³'},
      if (datos.llevaMalla)
        {'etiqueta': 'Malla electrosoldada', 'valor': '${resultado.panelesMallaNecesarios} panel(es) (2.30 × 6.00 m)'},
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
            Text('Material para el firme', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.paddingSm),
            ..._filas.map((f) => Padding(
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
                titulo: 'Firme ${datos.largoM.toStringAsFixed(2)} x ${datos.anchoM.toStringAsFixed(2)} m',
                subtitulo: '${datos.cantidadTramos} tramo(s) · espesor ${datos.espesorCm.toStringAsFixed(0)} cm',
                filas: _filas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota: 'Cuantificación de materiales para el firme especificado. Elemento no '
                    'estructural — confirma espesor y refuerzo con un ingeniero si aplica.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Firme',
                  titulo: 'Firme ${datos.largoM.toStringAsFixed(2)} x ${datos.anchoM.toStringAsFixed(2)} m',
                  subtitulo: '${resultado.areaM2.toStringAsFixed(1)} m²',
                  fecha: DateTime.now(),
                  volumenConcretoM3: resultado.volumenConcretoM3,
                  bolsasCemento: resultado.concreto.bolsasCemento,
                  arenaM3: resultado.concreto.arenaM3,
                  gravaM3: resultado.concreto.gravaM3,
                  areaNetaM2: resultado.areaM2,
                  filas: _filas,
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
          ],
        ),
      ),
    );
  }
}
