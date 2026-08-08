import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';
import 'package:structia/features/calculadora_columna/domain/calcular_columna.dart';
import 'package:structia/features/calculadora_columna/presentation/widgets/seccion_columna_painter.dart';

class CalculadoraColumnaScreen extends StatefulWidget {
  const CalculadoraColumnaScreen({super.key});

  @override
  State<CalculadoraColumnaScreen> createState() => _CalculadoraColumnaScreenState();
}

class _CalculadoraColumnaScreenState extends State<CalculadoraColumnaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _anchoController = TextEditingController(text: '30');
  final _profundidadController = TextEditingController(text: '30');
  final _alturaController = TextEditingController(text: '2.6');
  final _recubrimientoController = TextEditingController(text: '4');
  final _cantidadVarillasController = TextEditingController(text: '4');
  final _separacionEstribosController = TextEditingController(text: '15');
  final _cantidadColumnasController = TextEditingController(text: '1');

  DiametroVarilla _diametroLongitudinal = DiametroVarilla.n5;
  DiametroVarilla _diametroEstribo = DiametroVarilla.n3;

  DosificacionConcreto _dosificacion = DosificacionConcreto.tabla[2];
  DatosColumna? _datosVista;
  ResultadoColumna? _resultado;

  @override
  void dispose() {
    _anchoController.dispose();
    _profundidadController.dispose();
    _alturaController.dispose();
    _recubrimientoController.dispose();
    _cantidadVarillasController.dispose();
    _separacionEstribosController.dispose();
    _cantidadColumnasController.dispose();
    super.dispose();
  }

  DatosColumna? _leerDatos() {
    final ancho = double.tryParse(_anchoController.text.replaceAll(',', '.'));
    final profundidad = double.tryParse(_profundidadController.text.replaceAll(',', '.'));
    final altura = double.tryParse(_alturaController.text.replaceAll(',', '.'));
    final recubrimiento = double.tryParse(_recubrimientoController.text.replaceAll(',', '.'));
    final cantidadVarillas = int.tryParse(_cantidadVarillasController.text);
    final separacionEstribos =
        double.tryParse(_separacionEstribosController.text.replaceAll(',', '.'));
    final cantidadColumnas = int.tryParse(_cantidadColumnasController.text) ?? 1;

    if (ancho == null ||
        profundidad == null ||
        altura == null ||
        recubrimiento == null ||
        cantidadVarillas == null ||
        separacionEstribos == null) {
      return null;
    }

    return DatosColumna(
      anchoCm: ancho,
      profundidadCm: profundidad,
      alturaM: altura,
      recubrimientoCm: recubrimiento,
      diametroLongitudinal: _diametroLongitudinal,
      cantidadVarillasLongitudinales: cantidadVarillas,
      diametroEstribo: _diametroEstribo,
      separacionEstribosCm: separacionEstribos,
      cantidadColumnas: cantidadColumnas,
    );
  }

  void _actualizarVista() {
    setState(() => _datosVista = _leerDatos());
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    final datos = _leerDatos();
    if (datos == null) return;

    setState(() {
      _datosVista = datos;
      _resultado = CalcularColumna()(datos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Columnas')),
      body: Form(
        key: _formKey,
        onChanged: _actualizarVista,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: _datosVista != null
                  ? CustomPaint(
                      size: Size.infinite,
                      painter: SeccionColumnaPainter(_datosVista!),
                    )
                  : Center(
                      child: Text(
                        'Completa los datos para ver la vista previa',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Sección de la columna', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anchoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Ancho', suffixText: 'cm'),
                    validator: (v) =>
                        double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSm),
                Expanded(
                  child: TextFormField(
                    controller: _profundidadController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Profundidad', suffixText: 'cm'),
                    validator: (v) =>
                        double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _alturaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Altura de la columna', suffixText: 'm'),
                    validator: (v) =>
                        double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSm),
                Expanded(
                  child: TextFormField(
                    controller: _recubrimientoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Recubrimiento',
                      suffixText: 'cm',
                      helperText: 'Típico: 4 cm (interior), 5 cm si va expuesta',
                    ),
                    validator: (v) =>
                        double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text("Resistencia del concreto (f'c)", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DosificacionConcreto.tabla.map((d) {
                return ChoiceChip(
                  label: Text("${d.fc}"),
                  selected: _dosificacion.fc == d.fc,
                  onSelected: (_) => setState(() => _dosificacion = d),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Acero longitudinal', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DiametroVarilla.values.map((d) {
                return ChoiceChip(
                  label: Text(d.etiqueta),
                  selected: _diametroLongitudinal == d,
                  onSelected: (_) => setState(() {
                    _diametroLongitudinal = d;
                    _actualizarVista();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            TextFormField(
              controller: _cantidadVarillasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de varillas',
                helperText: 'Mínimo típico 4 (una por esquina)',
              ),
              validator: (v) => int.tryParse(v ?? '') == null ? 'Requerido' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Estribos', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [DiametroVarilla.n3, DiametroVarilla.n4].map((d) {
                return ChoiceChip(
                  label: Text(d.etiqueta),
                  selected: _diametroEstribo == d,
                  onSelected: (_) => setState(() {
                    _diametroEstribo = d;
                    _actualizarVista();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            TextFormField(
              controller: _separacionEstribosController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Separación entre estribos',
                suffixText: 'cm',
                helperText: 'Típico: 10-15 cm (más cerrado en los extremos)',
              ),
              validator: (v) =>
                  double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            TextFormField(
              controller: _cantidadColumnasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de columnas iguales',
                helperText: 'Calcula UNA columna y multiplica el material por esta cantidad',
              ),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Mínimo 1' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            FilledButton.icon(
              onPressed: _calcular,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular acero de la columna'),
            ),
            if (_resultado != null && _datosVista != null) ...[
              const SizedBox(height: AppConstants.paddingLg),
              _TarjetaResultadoColumna(resultado: _resultado!, datos: _datosVista!, dosificacion: _dosificacion),
            ],
            const SizedBox(height: AppConstants.paddingMd),
            Text(
              'Este cálculo cuantifica materiales para el armado que definiste. No sustituye el diseño '
              'estructural (cantidad, diámetro y separación mínima que requiere la columna dependen de las '
              'cargas reales) — confírmalo con un ingeniero estructural antes de construir.',
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

class _TarjetaResultadoColumna extends StatelessWidget {
  final ResultadoColumna resultado;
  final DatosColumna datos;
  final DosificacionConcreto dosificacion;

  const _TarjetaResultadoColumna({
    required this.resultado,
    required this.datos,
    required this.dosificacion,
  });

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
              datos.cantidadColumnas > 1
                  ? 'Material para ${datos.cantidadColumnas} columnas iguales'
                  : 'Material para 1 columna',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            _Fila('Volumen de concreto', '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'),
            Builder(builder: (context) {
              final materiales = CalcularMaterialesConcreto()(
                volumenM3: resultado.volumenConcretoM3,
                dosificacion: dosificacion,
              );
              return Padding(
                padding: const EdgeInsets.only(left: AppConstants.paddingMd, top: 4, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("f'c = ${dosificacion.fc} kg/cm²", style: Theme.of(context).textTheme.bodySmall),
                    _Fila('Cemento', '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'),
                    _Fila('Arena', '${materiales.arenaM3.toStringAsFixed(2)} m³'),
                    _Fila('Grava', '${materiales.gravaM3.toStringAsFixed(2)} m³'),
                    _Fila('Agua', '${materiales.aguaLitros.toStringAsFixed(0)} L'),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppConstants.paddingSm),
            Text('Acero longitudinal', style: Theme.of(context).textTheme.titleSmall),
            _Fila(
              'Varillas colocadas (${datos.diametroLongitudinal.etiqueta})',
              '${datos.cantidadVarillasLongitudinales * datos.cantidadColumnas}',
            ),
            _Fila('Longitud lineal total', '${resultado.aceroLongitudinal.longitudUtilTotalM.toStringAsFixed(2)} m'),
            _Fila('Varillas COMERCIALES a comprar (9 m c/u)',
                '${resultado.aceroLongitudinal.varillasComercialesNecesarias}'),
            _Fila('Peso a comprar', '${resultado.aceroLongitudinal.pesoCompradoKg.toStringAsFixed(2)} kg'),
            const Divider(height: AppConstants.paddingLg),
            Text('Estribos', style: Theme.of(context).textTheme.titleSmall),
            _Fila('Estribos por columna', '${resultado.cantidadEstribosPorColumna}'),
            _Fila('Perímetro por estribo', '${resultado.perimetroEstriboM.toStringAsFixed(2)} m'),
            _Fila('Longitud lineal total', '${resultado.aceroEstribos.longitudUtilTotalM.toStringAsFixed(2)} m'),
            _Fila('Varillas COMERCIALES a comprar (${datos.diametroEstribo.etiqueta})',
                '${resultado.aceroEstribos.varillasComercialesNecesarias}'),
            _Fila('Peso a comprar', '${resultado.aceroEstribos.pesoCompradoKg.toStringAsFixed(2)} kg'),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Columna ${datos.anchoCm.toStringAsFixed(0)}x${datos.profundidadCm.toStringAsFixed(0)} cm',
                subtitulo: 'Altura ${datos.alturaM.toStringAsFixed(2)} m · ${datos.cantidadColumnas} columna(s) igual(es)',
                filas: [
                  FilaPdf('Volumen de concreto', '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'),
                  FilaPdf("f'c", "${dosificacion.fc} kg/cm²"),
                  FilaPdf('Cemento', '${CalcularMaterialesConcreto()(volumenM3: resultado.volumenConcretoM3, dosificacion: dosificacion).bolsasCemento.ceil()} sacos de 42.5 kg'),
                  FilaPdf('Arena', '${CalcularMaterialesConcreto()(volumenM3: resultado.volumenConcretoM3, dosificacion: dosificacion).arenaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Grava', '${CalcularMaterialesConcreto()(volumenM3: resultado.volumenConcretoM3, dosificacion: dosificacion).gravaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Longitudinal', datos.diametroLongitudinal.etiqueta),
                  FilaPdf('Varillas colocadas por columna', '${datos.cantidadVarillasLongitudinales}'),
                  FilaPdf('Longitud lineal total', '${resultado.aceroLongitudinal.longitudUtilTotalM.toStringAsFixed(2)} m'),
                  FilaPdf('Varillas COMERCIALES a comprar (longitudinal)',
                      '${resultado.aceroLongitudinal.varillasComercialesNecesarias}'),
                  FilaPdf('Peso longitudinal', '${resultado.aceroLongitudinal.pesoCompradoKg.toStringAsFixed(2)} kg'),
                  FilaPdf('Estribo', datos.diametroEstribo.etiqueta),
                  FilaPdf('Separación de estribos', '${datos.separacionEstribosCm.toStringAsFixed(0)} cm'),
                  FilaPdf('Estribos por columna', '${resultado.cantidadEstribosPorColumna}'),
                  FilaPdf('Varillas COMERCIALES a comprar (estribos)',
                      '${resultado.aceroEstribos.varillasComercialesNecesarias}'),
                  FilaPdf('Peso estribos', '${resultado.aceroEstribos.pesoCompradoKg.toStringAsFixed(2)} kg'),
                ],
                nota: 'Cuantificación de materiales para el armado especificado. No sustituye el diseño '
                    'estructural — confírmalo con un ingeniero antes de construir.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                final materiales = CalcularMaterialesConcreto()(
                  volumenM3: resultado.volumenConcretoM3,
                  dosificacion: dosificacion,
                );
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Columna',
                  titulo: 'Columna ${datos.anchoCm.toStringAsFixed(0)}x${datos.profundidadCm.toStringAsFixed(0)} cm',
                  subtitulo: '${datos.cantidadColumnas} unidad(es) · ${datos.alturaM.toStringAsFixed(2)} m de altura',
                  fecha: DateTime.now(),
                  volumenConcretoM3: resultado.volumenConcretoM3,
                  bolsasCemento: materiales.bolsasCemento,
                  arenaM3: materiales.arenaM3,
                  gravaM3: materiales.gravaM3,
                  pesoAceroKg: resultado.aceroLongitudinal.pesoCompradoKg + resultado.aceroEstribos.pesoCompradoKg,
                  varillasPorDiametro: {
                    for (final entry in <String, int>{
                      datos.diametroLongitudinal.etiqueta:
                          resultado.aceroLongitudinal.varillasComercialesNecesarias,
                      datos.diametroEstribo.etiqueta:
                          resultado.aceroEstribos.varillasComercialesNecesarias,
                    }.entries)
                      entry.key: entry.value
                  },
                  filas: [
                    {'etiqueta': 'Volumen de concreto', 'valor': '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'},
                    {'etiqueta': 'Cemento', 'valor': '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'},
                    {'etiqueta': 'Arena', 'valor': '${materiales.arenaM3.toStringAsFixed(2)} m³'},
                    {'etiqueta': 'Grava', 'valor': '${materiales.gravaM3.toStringAsFixed(2)} m³'},
                    {'etiqueta': 'Acero longitudinal', 'valor': '${datos.diametroLongitudinal.etiqueta} x ${datos.cantidadVarillasLongitudinales * datos.cantidadColumnas}'},
                    {'etiqueta': 'Peso longitudinal', 'valor': '${resultado.aceroLongitudinal.pesoCompradoKg.toStringAsFixed(2)} kg'},
                    {'etiqueta': 'Estribos', 'valor': '${resultado.cantidadEstribosPorColumna} x columna, ${datos.diametroEstribo.etiqueta}'},
                    {'etiqueta': 'Peso estribos', 'valor': '${resultado.aceroEstribos.pesoCompradoKg.toStringAsFixed(2)} kg'},
                  ],
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

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Fila(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
