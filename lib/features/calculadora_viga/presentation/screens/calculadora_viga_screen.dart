import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';
import 'package:structia/features/calculadora_viga/domain/calcular_viga.dart';
import 'package:structia/features/calculadora_viga/presentation/widgets/seccion_viga_painter.dart';

class CalculadoraVigaScreen extends StatefulWidget {
  const CalculadoraVigaScreen({super.key});

  @override
  State<CalculadoraVigaScreen> createState() => _CalculadoraVigaScreenState();
}

class _CalculadoraVigaScreenState extends State<CalculadoraVigaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _anchoController = TextEditingController(text: '25');
  final _peralteController = TextEditingController(text: '40');
  final _luzController = TextEditingController(text: '4.0');
  final _recubrimientoController = TextEditingController(text: '4');
  final _cantidadSuperiorController = TextEditingController(text: '2');
  final _cantidadInferiorController = TextEditingController(text: '3');
  final _separacionEstribosController = TextEditingController(text: '15');
  final _cantidadVigasController = TextEditingController(text: '1');

  TipoApoyoViga _tipoApoyo = TipoApoyoViga.simplementeApoyada;
  DiametroVarilla _diametroSuperior = DiametroVarilla.n5;
  DiametroVarilla _diametroInferior = DiametroVarilla.n5;
  DiametroVarilla _diametroEstribo = DiametroVarilla.n3;

  DosificacionConcreto _dosificacion = DosificacionConcreto.tabla[2];
  DatosViga? _datosVista;
  ResultadoViga? _resultado;

  @override
  void dispose() {
    _anchoController.dispose();
    _peralteController.dispose();
    _luzController.dispose();
    _recubrimientoController.dispose();
    _cantidadSuperiorController.dispose();
    _cantidadInferiorController.dispose();
    _separacionEstribosController.dispose();
    _cantidadVigasController.dispose();
    super.dispose();
  }

  DatosViga? _leerDatos() {
    final ancho = double.tryParse(_anchoController.text.replaceAll(',', '.'));
    final peralte = double.tryParse(_peralteController.text.replaceAll(',', '.'));
    final luz = double.tryParse(_luzController.text.replaceAll(',', '.'));
    final recubrimiento = double.tryParse(_recubrimientoController.text.replaceAll(',', '.'));
    final cantidadSuperior = int.tryParse(_cantidadSuperiorController.text);
    final cantidadInferior = int.tryParse(_cantidadInferiorController.text);
    final separacionEstribos =
        double.tryParse(_separacionEstribosController.text.replaceAll(',', '.'));

    final cantidadVigas = int.tryParse(_cantidadVigasController.text) ?? 1;

    if (ancho == null ||
        peralte == null ||
        luz == null ||
        recubrimiento == null ||
        cantidadSuperior == null ||
        cantidadInferior == null ||
        separacionEstribos == null) {
      return null;
    }

    return DatosViga(
      anchoCm: ancho,
      peralteCm: peralte,
      luzM: luz,
      recubrimientoCm: recubrimiento,
      tipoApoyo: _tipoApoyo,
      diametroSuperior: _diametroSuperior,
      cantidadVarillasSuperiores: cantidadSuperior,
      diametroInferior: _diametroInferior,
      cantidadVarillasInferiores: cantidadInferior,
      diametroEstribo: _diametroEstribo,
      separacionEstribosCm: separacionEstribos,
      cantidadVigas: cantidadVigas,
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
      _resultado = CalcularViga()(datos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vigas')),
      body: Form(
        key: _formKey,
        onChanged: _actualizarVista,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: _datosVista != null
                  ? CustomPaint(
                      size: Size.infinite,
                      painter: SeccionVigaPainter(_datosVista!),
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
            const SizedBox(height: AppConstants.paddingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Leyenda(color: Color(0xFFFF6F00), texto: 'Superior'),
                SizedBox(width: 16),
                _Leyenda(color: Color(0xFF1565C0), texto: 'Inferior'),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Sección de la viga', style: Theme.of(context).textTheme.titleSmall),
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
                    controller: _peralteController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peralte (altura)', suffixText: 'cm'),
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
                    controller: _luzController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Largo de la viga (luz libre)',
                      helperText: 'Distancia entre columnas/apoyos',
                      suffixText: 'm',
                    ),
                    validator: (v) =>
                        double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSm),
                Expanded(
                  child: TextFormField(
                    controller: _recubrimientoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Recubrimiento', suffixText: 'cm'),
                    validator: (v) =>
                        double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMd),
            DropdownButtonFormField<TipoApoyoViga>(
              initialValue: _tipoApoyo,
              decoration: const InputDecoration(labelText: 'Condición de apoyo'),
              items: TipoApoyoViga.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.etiqueta)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _tipoApoyo = v);
                  _actualizarVista();
                }
              },
            ),
            const SizedBox(height: AppConstants.paddingSm),
            _NotaMomento(tipoApoyo: _tipoApoyo),
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
            Text('Acero superior', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DiametroVarilla.values.map((d) {
                return ChoiceChip(
                  label: Text(d.etiqueta),
                  selected: _diametroSuperior == d,
                  onSelected: (_) => setState(() {
                    _diametroSuperior = d;
                    _actualizarVista();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            TextFormField(
              controller: _cantidadSuperiorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad de varillas superiores'),
              validator: (v) => int.tryParse(v ?? '') == null ? 'Requerido' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            Text('Acero inferior', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppConstants.paddingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DiametroVarilla.values.map((d) {
                return ChoiceChip(
                  label: Text(d.etiqueta),
                  selected: _diametroInferior == d,
                  onSelected: (_) => setState(() {
                    _diametroInferior = d;
                    _actualizarVista();
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            TextFormField(
              controller: _cantidadInferiorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad de varillas inferiores'),
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
                helperText: 'Típico: más cerrado (10 cm) cerca de apoyos, más abierto (20 cm) al centro',
              ),
              validator: (v) =>
                  double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            TextFormField(
              controller: _cantidadVigasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de vigas iguales',
                helperText: 'Calcula UNA viga y multiplica el material por esta cantidad',
              ),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Mínimo 1' : null,
            ),
            const SizedBox(height: AppConstants.paddingLg),
            FilledButton.icon(
              onPressed: _calcular,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular acero de la viga'),
            ),
            if (_resultado != null && _datosVista != null) ...[
              const SizedBox(height: AppConstants.paddingLg),
              _TarjetaResultadoViga(resultado: _resultado!, datos: _datosVista!, dosificacion: _dosificacion),
            ],
            const SizedBox(height: AppConstants.paddingMd),
            Text(
              'Este cálculo cuantifica materiales para el armado que definiste (cantidad y diámetro de '
              'varillas arriba/abajo). Cuánto acero necesita realmente la viga depende del análisis '
              'estructural con las cargas reales — no lo calcula esta app. Confírmalo con un ingeniero '
              'estructural antes de construir.',
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

class _NotaMomento extends StatelessWidget {
  final TipoApoyoViga tipoApoyo;

  const _NotaMomento({required this.tipoApoyo});

  @override
  Widget build(BuildContext context) {
    final String texto;
    switch (tipoApoyo) {
      case TipoApoyoViga.simplementeApoyada:
        texto =
            'En una viga simplemente apoyada, el centro tiende a "abrirse hacia abajo" (momento positivo): '
            'normalmente necesita más acero ABAJO en el centro del tramo, y algo de acero mínimo ARRIBA por armado.';
        break;
      case TipoApoyoViga.continua:
        texto =
            'En una viga continua, cerca de las columnas la viga tiende a "abrirse hacia arriba" (momento '
            'negativo): normalmente necesita más acero ARRIBA cerca de los apoyos, y más acero ABAJO al centro del tramo.';
        break;
      case TipoApoyoViga.voladizo:
        texto =
            'En un voladizo, toda la viga tiende a "abrirse hacia arriba": normalmente necesita más acero '
            'ARRIBA en toda su longitud, especialmente cerca del empotramiento.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$texto\n\nEsto es una guía conceptual, no un cálculo — la cantidad exacta depende de las '
              'cargas reales sobre la viga. Defínela con tu ingeniero.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _Leyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TarjetaResultadoViga extends StatelessWidget {
  final ResultadoViga resultado;
  final DatosViga datos;
  final DosificacionConcreto dosificacion;

  const _TarjetaResultadoViga({
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
              datos.cantidadVigas > 1
                  ? 'Material para ${datos.cantidadVigas} vigas iguales'
                  : 'Material para 1 viga',
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
            Text('Acero superior', style: Theme.of(context).textTheme.titleSmall),
            _Fila(
              'Varillas colocadas (${datos.diametroSuperior.etiqueta})',
              '${datos.cantidadVarillasSuperiores * datos.cantidadVigas}',
            ),
            _Fila('Longitud lineal total', '${resultado.aceroSuperior.longitudUtilTotalM.toStringAsFixed(2)} m'),
            _Fila('Varillas COMERCIALES a comprar (9 m c/u)',
                '${resultado.aceroSuperior.varillasComercialesNecesarias}'),
            _Fila('Peso a comprar', '${resultado.aceroSuperior.pesoCompradoKg.toStringAsFixed(2)} kg'),
            const Divider(height: AppConstants.paddingLg),
            Text('Acero inferior', style: Theme.of(context).textTheme.titleSmall),
            _Fila(
              'Varillas colocadas (${datos.diametroInferior.etiqueta})',
              '${datos.cantidadVarillasInferiores * datos.cantidadVigas}',
            ),
            _Fila('Longitud lineal total', '${resultado.aceroInferior.longitudUtilTotalM.toStringAsFixed(2)} m'),
            _Fila('Varillas COMERCIALES a comprar (9 m c/u)',
                '${resultado.aceroInferior.varillasComercialesNecesarias}'),
            _Fila('Peso a comprar', '${resultado.aceroInferior.pesoCompradoKg.toStringAsFixed(2)} kg'),
            const Divider(height: AppConstants.paddingLg),
            Text('Estribos', style: Theme.of(context).textTheme.titleSmall),
            _Fila('Estribos por viga', '${resultado.cantidadEstribosPorViga}'),
            _Fila('Longitud lineal total', '${resultado.aceroEstribos.longitudUtilTotalM.toStringAsFixed(2)} m'),
            _Fila('Varillas COMERCIALES a comprar (${datos.diametroEstribo.etiqueta})',
                '${resultado.aceroEstribos.varillasComercialesNecesarias}'),
            _Fila('Peso a comprar', '${resultado.aceroEstribos.pesoCompradoKg.toStringAsFixed(2)} kg'),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Viga ${datos.anchoCm.toStringAsFixed(0)}x${datos.peralteCm.toStringAsFixed(0)} cm',
                subtitulo: 'Luz ${datos.luzM.toStringAsFixed(2)} m · ${datos.tipoApoyo.etiqueta} · ${datos.cantidadVigas} viga(s) igual(es)',
                filas: [
                  FilaPdf('Volumen de concreto', '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'),
                  FilaPdf("f'c", "${dosificacion.fc} kg/cm²"),
                  FilaPdf('Cemento', '${CalcularMaterialesConcreto()(volumenM3: resultado.volumenConcretoM3, dosificacion: dosificacion).bolsasCemento.ceil()} sacos de 42.5 kg'),
                  FilaPdf('Arena', '${CalcularMaterialesConcreto()(volumenM3: resultado.volumenConcretoM3, dosificacion: dosificacion).arenaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Grava', '${CalcularMaterialesConcreto()(volumenM3: resultado.volumenConcretoM3, dosificacion: dosificacion).gravaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Superior', '${datos.cantidadVarillasSuperiores} x ${datos.diametroSuperior.etiqueta}'),
                  FilaPdf('Longitud lineal total (superior)',
                      '${resultado.aceroSuperior.longitudUtilTotalM.toStringAsFixed(2)} m'),
                  FilaPdf('Varillas COMERCIALES a comprar (superior)',
                      '${resultado.aceroSuperior.varillasComercialesNecesarias}'),
                  FilaPdf('Peso superior', '${resultado.aceroSuperior.pesoCompradoKg.toStringAsFixed(2)} kg'),
                  FilaPdf('Inferior', '${datos.cantidadVarillasInferiores} x ${datos.diametroInferior.etiqueta}'),
                  FilaPdf('Longitud lineal total (inferior)',
                      '${resultado.aceroInferior.longitudUtilTotalM.toStringAsFixed(2)} m'),
                  FilaPdf('Varillas COMERCIALES a comprar (inferior)',
                      '${resultado.aceroInferior.varillasComercialesNecesarias}'),
                  FilaPdf('Peso inferior', '${resultado.aceroInferior.pesoCompradoKg.toStringAsFixed(2)} kg'),
                  FilaPdf('Estribo', datos.diametroEstribo.etiqueta),
                  FilaPdf('Separación', '${datos.separacionEstribosCm.toStringAsFixed(0)} cm'),
                  FilaPdf('Estribos por viga', '${resultado.cantidadEstribosPorViga}'),
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
                final pesoAceroTotal = resultado.aceroSuperior.pesoCompradoKg +
                    resultado.aceroInferior.pesoCompradoKg +
                    resultado.aceroEstribos.pesoCompradoKg;
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Viga',
                  titulo: 'Viga ${datos.anchoCm.toStringAsFixed(0)}x${datos.peralteCm.toStringAsFixed(0)} cm',
                  subtitulo: '${datos.cantidadVigas} unidad(es) · luz ${datos.luzM.toStringAsFixed(2)} m',
                  fecha: DateTime.now(),
                  volumenConcretoM3: resultado.volumenConcretoM3,
                  bolsasCemento: materiales.bolsasCemento,
                  arenaM3: materiales.arenaM3,
                  gravaM3: materiales.gravaM3,
                  pesoAceroKg: pesoAceroTotal,
                  varillasPorDiametro: () {
                    final mapa = <String, int>{};
                    void sumar(String etiqueta, int cantidad) {
                      mapa[etiqueta] = (mapa[etiqueta] ?? 0) + cantidad;
                    }
                    sumar(datos.diametroSuperior.etiqueta, resultado.aceroSuperior.varillasComercialesNecesarias);
                    sumar(datos.diametroInferior.etiqueta, resultado.aceroInferior.varillasComercialesNecesarias);
                    sumar(datos.diametroEstribo.etiqueta, resultado.aceroEstribos.varillasComercialesNecesarias);
                    return mapa;
                  }(),
                  filas: [
                    {'etiqueta': 'Volumen de concreto', 'valor': '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'},
                    {'etiqueta': 'Cemento', 'valor': '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'},
                    {'etiqueta': 'Arena', 'valor': '${materiales.arenaM3.toStringAsFixed(2)} m³'},
                    {'etiqueta': 'Grava', 'valor': '${materiales.gravaM3.toStringAsFixed(2)} m³'},
                    {'etiqueta': 'Acero superior', 'valor': '${datos.diametroSuperior.etiqueta} x ${datos.cantidadVarillasSuperiores * datos.cantidadVigas}'},
                    {
                      'etiqueta': 'Varillas superior COMERCIALES',
                      'valor': '${resultado.aceroSuperior.varillasComercialesNecesarias} de ${datos.diametroSuperior.etiqueta}',
                    },
                    {'etiqueta': 'Acero inferior', 'valor': '${datos.diametroInferior.etiqueta} x ${datos.cantidadVarillasInferiores * datos.cantidadVigas}'},
                    {
                      'etiqueta': 'Varillas inferior COMERCIALES',
                      'valor': '${resultado.aceroInferior.varillasComercialesNecesarias} de ${datos.diametroInferior.etiqueta}',
                    },
                    {
                      'etiqueta': 'Varillas estribos COMERCIALES',
                      'valor': '${resultado.aceroEstribos.varillasComercialesNecesarias} de ${datos.diametroEstribo.etiqueta}',
                    },
                    {'etiqueta': 'Peso total de acero', 'valor': '${pesoAceroTotal.toStringAsFixed(2)} kg'},
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
