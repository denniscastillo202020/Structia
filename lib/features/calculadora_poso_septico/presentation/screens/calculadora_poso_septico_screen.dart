import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';
import 'package:structia/features/calculadora_mamposteria/domain/calcular_mamposteria.dart';
import 'package:structia/features/calculadora_poso_septico/domain/calcular_poso_septico.dart';

class CalculadoraPosoSepticoScreen extends StatefulWidget {
  const CalculadoraPosoSepticoScreen({super.key});

  @override
  State<CalculadoraPosoSepticoScreen> createState() => _CalculadoraPosoSepticoScreenState();
}

class _CalculadoraPosoSepticoScreenState extends State<CalculadoraPosoSepticoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _largoController = TextEditingController(text: '1.20');
  final _anchoController = TextEditingController(text: '1.20');
  final _profundidadController = TextEditingController(text: '2');

  final _espesorJuntaController = TextEditingController(text: '1');
  final _desperdicioBloqueController = TextEditingController(text: '5');

  final _separacionVerticalController = TextEditingController(text: '40');

  final _espesorLosaController = TextEditingController(text: '10');
  final _separacionLosaController = TextEditingController(text: '15');
  final _recubrimientoLosaController = TextEditingController(text: '3');

  TipoBloque _tipoBloque = TipoBloque.presets[2]; // 40x20x20, muro de carga
  DosificacionMortero _dosificacionMortero = DosificacionMortero.tabla[0]; // 1:3, mayor resistencia
  DiametroVarilla _diametroVertical = DiametroVarilla.n4;
  DiametroVarilla _diametroLosa = DiametroVarilla.n4;
  DosificacionConcreto _dosificacionLosa = DosificacionConcreto.tabla[2]; // f'c=210

  ResultadoPosoSeptico? _resultado;
  DatosPosoSeptico? _datosVista;

  @override
  void dispose() {
    _largoController.dispose();
    _anchoController.dispose();
    _profundidadController.dispose();
    _espesorJuntaController.dispose();
    _desperdicioBloqueController.dispose();
    _separacionVerticalController.dispose();
    _espesorLosaController.dispose();
    _separacionLosaController.dispose();
    _recubrimientoLosaController.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    final largo = _num(_largoController);
    final ancho = _num(_anchoController);
    final profundidad = _num(_profundidadController);
    final espesorJunta = _num(_espesorJuntaController);
    final desperdicioBloque = _num(_desperdicioBloqueController);
    final separacionVertical = _num(_separacionVerticalController);
    final espesorLosa = _num(_espesorLosaController);
    final separacionLosa = _num(_separacionLosaController);
    final recubrimientoLosa = _num(_recubrimientoLosaController);

    if (largo == null ||
        ancho == null ||
        profundidad == null ||
        espesorJunta == null ||
        desperdicioBloque == null ||
        separacionVertical == null ||
        espesorLosa == null ||
        separacionLosa == null ||
        recubrimientoLosa == null) {
      return;
    }

    final datos = DatosPosoSeptico(
      largoInternoM: largo,
      anchoInternoM: ancho,
      profundidadM: profundidad,
      tipoBloque: _tipoBloque,
      espesorJuntaCm: espesorJunta,
      porcentajeDesperdicioBloque: desperdicioBloque,
      dosificacionMortero: _dosificacionMortero,
      diametroVertical: _diametroVertical,
      separacionVerticalCm: separacionVertical,
      espesorLosaCm: espesorLosa,
      diametroLosa: _diametroLosa,
      separacionLosaCm: separacionLosa,
      recubrimientoLosaCm: recubrimientoLosa,
      dosificacionConcretoLosa: _dosificacionLosa,
    );
    setState(() {
      _datosVista = datos;
      _resultado = CalcularPosoSeptico()(datos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pozo séptico')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          children: [
            Text(
              'Pozo rectangular, paredes de bloque con refuerzo vertical en las celdas, '
              'y tapadera de concreto armada.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Dimensiones internas', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
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
              controller: _profundidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Profundidad', suffixText: 'm'),
              validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Paredes de bloque', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TipoBloque.presets.map((b) {
                return ChoiceChip(
                  label: Text(b.etiqueta),
                  selected: _tipoBloque.etiqueta == b.etiqueta,
                  onSelected: (_) => setState(() => _tipoBloque = b),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _espesorJuntaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Espesor de junta', suffixText: 'cm'),
                    validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSm),
                Expanded(
                  child: TextFormField(
                    controller: _desperdicioBloqueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Desperdicio bloque', suffixText: '%'),
                    validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSm),
            Text('Mortero de pega', style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 8,
              children: DosificacionMortero.tabla.map((d) {
                return ChoiceChip(
                  label: Text(d.proporcion),
                  selected: _dosificacionMortero.proporcion == d.proporcion,
                  onSelected: (_) => setState(() => _dosificacionMortero = d),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Refuerzo vertical (dentro de las celdas del bloque)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DiametroVarilla.values.map((d) {
                return ChoiceChip(
                  label: Text(d.etiqueta),
                  selected: _diametroVertical == d,
                  onSelected: (_) => setState(() => _diametroVertical = d),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            TextFormField(
              controller: _separacionVerticalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Separación entre varillas verticales',
                suffixText: 'cm',
                helperText: 'Típico: 40 cm (cada 2 celdas de bloque de 20 cm)',
              ),
              validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Tapadera de concreto armada', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _espesorLosaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Espesor', suffixText: 'cm'),
                    validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSm),
                Expanded(
                  child: TextFormField(
                    controller: _recubrimientoLosaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Recubrimiento', suffixText: 'cm'),
                    validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSm),
            Text('Cama de varillas de la tapadera', style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DiametroVarilla.values.map((d) {
                return ChoiceChip(
                  label: Text(d.etiqueta),
                  selected: _diametroLosa == d,
                  onSelected: (_) => setState(() => _diametroLosa = d),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            TextFormField(
              controller: _separacionLosaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Separación de la cama (dos direcciones)',
                suffixText: 'cm',
              ),
              validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
            ),
            const SizedBox(height: AppConstants.paddingSm),
            Text("Resistencia del concreto de la tapadera (f'c)", style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 8,
              children: DosificacionConcreto.tabla.map((d) {
                return ChoiceChip(
                  label: Text("${d.fc}"),
                  selected: _dosificacionLosa.fc == d.fc,
                  onSelected: (_) => setState(() => _dosificacionLosa = d),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingLg),
            FilledButton.icon(
              onPressed: _calcular,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular pozo séptico'),
            ),
            if (_resultado != null && _datosVista != null) ...[
              const SizedBox(height: AppConstants.paddingLg),
              _TarjetaResultadoPoso(resultado: _resultado!, datos: _datosVista!),
            ],
            const SizedBox(height: AppConstants.paddingMd),
            Text(
              'Cuantifica materiales para las dimensiones y refuerzo que definiste. La '
              'profundidad, capacidad y el diseño sanitario del pozo dependen del terreno y '
              'la normativa local — confírmalo con un ingeniero antes de construir.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaResultadoPoso extends StatelessWidget {
  final ResultadoPosoSeptico resultado;
  final DatosPosoSeptico datos;

  const _TarjetaResultadoPoso({required this.resultado, required this.datos});

  List<Map<String, String>> get _filas {
    return [
      {'etiqueta': 'Área de paredes', 'valor': '${datos.areaParedesM2.toStringAsFixed(1)} m²'},
      {'etiqueta': 'Bloques a comprar', 'valor': '${resultado.paredes.bloquesTotalComprar} (${datos.tipoBloque.etiqueta})'},
      {'etiqueta': 'Mortero de pega', 'valor': '${resultado.paredes.morteroTotalM3.toStringAsFixed(2)} m³'},
      {'etiqueta': 'Cemento (mortero)', 'valor': '${resultado.paredes.sacosCementoMortero.ceil()} sacos de 42.5 kg'},
      {'etiqueta': 'Arena (mortero)', 'valor': '${resultado.paredes.arenaMorteroM3.toStringAsFixed(2)} m³'},
      {
        'etiqueta': 'Varillas verticales (${datos.diametroVertical.etiqueta})',
        'valor': '${resultado.cantidadVarillasVerticales} de ${datos.profundidadM.toStringAsFixed(2)} m',
      },
      {
        'etiqueta': 'Varillas COMERCIALES verticales',
        'valor': '${resultado.aceroVertical.varillasComercialesNecesarias}',
      },
      {'etiqueta': 'Área de la tapadera', 'valor': '${datos.areaLosaM2.toStringAsFixed(2)} m²'},
      {
        'etiqueta': 'Cama tapadera dirección X',
        'valor': '${resultado.cantidadBarrasLosaDireccionX} de ${datos.diametroLosa.etiqueta}',
      },
      {
        'etiqueta': 'Cama tapadera dirección Y',
        'valor': '${resultado.cantidadBarrasLosaDireccionY} de ${datos.diametroLosa.etiqueta}',
      },
      {
        'etiqueta': 'Varillas COMERCIALES tapadera',
        'valor':
            '${resultado.aceroLosaDireccionX.varillasComercialesNecesarias + resultado.aceroLosaDireccionY.varillasComercialesNecesarias}',
      },
      {'etiqueta': 'Concreto de la tapadera', 'valor': '${resultado.volumenConcretoLosaM3.toStringAsFixed(2)} m³'},
      {'etiqueta': 'Cemento (tapadera)', 'valor': '${resultado.concretoLosa.bolsasCemento.ceil()} sacos de 42.5 kg'},
      {'etiqueta': 'Arena (tapadera)', 'valor': '${resultado.concretoLosa.arenaM3.toStringAsFixed(2)} m³'},
      {'etiqueta': 'Grava (tapadera)', 'valor': '${resultado.concretoLosa.gravaM3.toStringAsFixed(2)} m³'},
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
            Text('Material para el pozo séptico', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppConstants.paddingSm),
            ..._filas.map((f) => Padding(
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
                titulo: 'Pozo séptico ${datos.largoInternoM.toStringAsFixed(2)} x ${datos.anchoInternoM.toStringAsFixed(2)} m',
                subtitulo: 'Profundidad ${datos.profundidadM.toStringAsFixed(2)} m',
                filas: _filas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota: 'Cuantificación de materiales para el pozo séptico especificado. El '
                    'diseño sanitario y estructural real debe confirmarlo un ingeniero antes '
                    'de construir.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                final pesoAceroTotal = resultado.aceroVertical.pesoCompradoKg +
                    resultado.aceroLosaDireccionX.pesoCompradoKg +
                    resultado.aceroLosaDireccionY.pesoCompradoKg;
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Pozo séptico',
                  titulo: 'Pozo séptico ${datos.largoInternoM.toStringAsFixed(2)} x ${datos.anchoInternoM.toStringAsFixed(2)} m',
                  subtitulo: 'Profundidad ${datos.profundidadM.toStringAsFixed(2)} m',
                  fecha: DateTime.now(),
                  volumenConcretoM3: resultado.volumenConcretoLosaM3,
                  bolsasCemento: resultado.paredes.sacosCementoMortero + resultado.concretoLosa.bolsasCemento,
                  arenaM3: resultado.paredes.arenaMorteroM3 + resultado.concretoLosa.arenaM3,
                  gravaM3: resultado.concretoLosa.gravaM3,
                  pesoAceroKg: pesoAceroTotal,
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
