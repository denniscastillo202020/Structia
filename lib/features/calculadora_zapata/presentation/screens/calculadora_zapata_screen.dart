import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';
import 'package:structia/features/calculadora_zapata/domain/calcular_zapata.dart';
import 'package:structia/features/calculadora_zapata/presentation/widgets/planta_zapata_aislada_painter.dart';

class CalculadoraZapataScreen extends StatefulWidget {
  const CalculadoraZapataScreen({super.key});

  @override
  State<CalculadoraZapataScreen> createState() => _CalculadoraZapataScreenState();
}

class _CalculadoraZapataScreenState extends State<CalculadoraZapataScreen> {
  TipoZapata _tipo = TipoZapata.aislada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zapatas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            child: SegmentedButton<TipoZapata>(
              segments: TipoZapata.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.etiqueta)))
                  .toList(),
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
          ),
          Expanded(
            child: _tipo == TipoZapata.aislada
                ? const _FormularioAislada()
                : const _FormularioCorrida(),
          ),
        ],
      ),
    );
  }
}

// ============================= AISLADA =============================

class _FormularioAislada extends StatefulWidget {
  const _FormularioAislada();

  @override
  State<_FormularioAislada> createState() => _FormularioAisladaState();
}

class _FormularioAisladaState extends State<_FormularioAislada> {
  final _formKey = GlobalKey<FormState>();
  final _ladoXController = TextEditingController(text: '120');
  final _ladoYController = TextEditingController(text: '120');
  final _profundidadController = TextEditingController(text: '40');
  final _recubrimientoController = TextEditingController(text: '7.5');
  final _separacionController = TextEditingController(text: '15');
  final _cantidadController = TextEditingController(text: '1');

  DiametroVarilla _diametroCama = DiametroVarilla.n5;
  DosificacionConcreto _dosificacion = DosificacionConcreto.tabla[2];

  DatosZapataAislada? _datosVista;
  ResultadoZapataAislada? _resultado;

  @override
  void dispose() {
    _ladoXController.dispose();
    _ladoYController.dispose();
    _profundidadController.dispose();
    _recubrimientoController.dispose();
    _separacionController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  DatosZapataAislada? _leerDatos() {
    final ladoX = double.tryParse(_ladoXController.text.replaceAll(',', '.'));
    final ladoY = double.tryParse(_ladoYController.text.replaceAll(',', '.'));
    final profundidad = double.tryParse(_profundidadController.text.replaceAll(',', '.'));
    final recubrimiento = double.tryParse(_recubrimientoController.text.replaceAll(',', '.'));
    final separacion = double.tryParse(_separacionController.text.replaceAll(',', '.'));
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;

    if (ladoX == null || ladoY == null || profundidad == null || recubrimiento == null || separacion == null) {
      return null;
    }

    return DatosZapataAislada(
      ladoXCm: ladoX,
      ladoYCm: ladoY,
      profundidadCm: profundidad,
      recubrimientoCm: recubrimiento,
      diametroCama: _diametroCama,
      separacionCamaCm: separacion,
      cantidadZapatas: cantidad,
    );
  }

  void _actualizarVista() => setState(() => _datosVista = _leerDatos());

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    final datos = _leerDatos();
    if (datos == null) return;
    setState(() {
      _datosVista = datos;
      _resultado = CalcularZapataAislada()(datos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
                    painter: PlantaZapataAisladaPainter(_datosVista!),
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
              _Leyenda(color: Color(0xFF1565C0), texto: 'Dirección X'),
              SizedBox(width: 16),
              _Leyenda(color: Color(0xFFFF6F00), texto: 'Dirección Y'),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Dimensiones en planta', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ladoXController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Lado X', suffixText: 'cm'),
                  validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                child: TextFormField(
                  controller: _ladoYController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Lado Y', suffixText: 'cm'),
                  validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMd),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _profundidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Espesor / profundidad', suffixText: 'cm'),
                  validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
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
                    helperText: 'Típico: 7.5 cm (fundida contra tierra)',
                  ),
                  validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                ),
              ),
            ],
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
          Text('Cama de varillas (malla en dos direcciones)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DiametroVarilla.values.map((d) {
              return ChoiceChip(
                label: Text(d.etiqueta),
                selected: _diametroCama == d,
                onSelected: (_) => setState(() {
                  _diametroCama = d;
                  _actualizarVista();
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _separacionController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Separación de la cama',
              suffixText: 'cm',
              helperText: 'Misma separación en ambas direcciones. Típico: 15-20 cm',
            ),
            validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
          ),
          const SizedBox(height: AppConstants.paddingLg),
          TextFormField(
            controller: _cantidadController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad de zapatas iguales',
              helperText: 'Calcula UNA zapata y multiplica el material por esta cantidad',
            ),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Mínimo 1' : null,
          ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular zapata aislada'),
          ),
          if (_resultado != null && _datosVista != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoAislada(resultado: _resultado!, datos: _datosVista!, dosificacion: _dosificacion),
          ],
          const SizedBox(height: AppConstants.paddingMd),
          Text(
            'Cuantifica materiales para las dimensiones y armado que definiste. El tamaño y armado real '
            'de la zapata depende de la capacidad portante del suelo y la carga de la columna — '
            'confírmalo con un ingeniero antes de construir.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _TarjetaResultadoAislada extends StatelessWidget {
  final ResultadoZapataAislada resultado;
  final DatosZapataAislada datos;
  final DosificacionConcreto dosificacion;

  const _TarjetaResultadoAislada({required this.resultado, required this.datos, required this.dosificacion});

  @override
  Widget build(BuildContext context) {
    final materiales = CalcularMaterialesConcreto()(volumenM3: resultado.volumenConcretoM3, dosificacion: dosificacion);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              datos.cantidadZapatas > 1 ? 'Material para ${datos.cantidadZapatas} zapatas iguales' : 'Material para 1 zapata',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            _Fila('Volumen de concreto', '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'),
            Text("f'c = ${dosificacion.fc} kg/cm²", style: Theme.of(context).textTheme.bodySmall),
            _Fila('Cemento', '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'),
            _Fila('Arena', '${materiales.arenaM3.toStringAsFixed(2)} m³'),
            _Fila('Grava', '${materiales.gravaM3.toStringAsFixed(2)} m³'),
            const Divider(height: AppConstants.paddingLg),
            Text('Cama de varillas (${datos.diametroCama.etiqueta})', style: Theme.of(context).textTheme.titleSmall),
            _Fila('Varillas dirección X', '${datos.cantidadBarrasDireccionX} de ${datos.longitudBarraDireccionXM.toStringAsFixed(2)} m'),
            _Fila('Varillas dirección Y', '${datos.cantidadBarrasDireccionY} de ${datos.longitudBarraDireccionYM.toStringAsFixed(2)} m'),
            _Fila('Varillas COMERCIALES a comprar (X)', '${resultado.aceroDireccionX.varillasComercialesNecesarias}'),
            _Fila('Varillas COMERCIALES a comprar (Y)', '${resultado.aceroDireccionY.varillasComercialesNecesarias}'),
            _Fila('Peso total de acero', '${(resultado.aceroDireccionX.pesoCompradoKg + resultado.aceroDireccionY.pesoCompradoKg).toStringAsFixed(2)} kg'),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Zapata aislada ${datos.ladoXCm.toStringAsFixed(0)}x${datos.ladoYCm.toStringAsFixed(0)} cm',
                subtitulo: '${datos.cantidadZapatas} unidad(es) · espesor ${datos.profundidadCm.toStringAsFixed(0)} cm',
                filas: [
                  FilaPdf('Volumen de concreto', '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'),
                  FilaPdf("f'c", "${dosificacion.fc} kg/cm²"),
                  FilaPdf('Cemento', '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'),
                  FilaPdf('Arena', '${materiales.arenaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Grava', '${materiales.gravaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Cama dirección X', '${datos.cantidadBarrasDireccionX} varillas ${datos.diametroCama.etiqueta}'),
                  FilaPdf('Cama dirección Y', '${datos.cantidadBarrasDireccionY} varillas ${datos.diametroCama.etiqueta}'),
                  FilaPdf('Peso total de acero', '${(resultado.aceroDireccionX.pesoCompradoKg + resultado.aceroDireccionY.pesoCompradoKg).toStringAsFixed(2)} kg'),
                ],
                nota: 'Cuantificación de materiales para las dimensiones y armado especificados. No sustituye '
                    'el diseño geotécnico/estructural — confírmalo con un ingeniero antes de construir.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Zapata',
                  titulo: 'Zapata aislada ${datos.ladoXCm.toStringAsFixed(0)}x${datos.ladoYCm.toStringAsFixed(0)} cm',
                  subtitulo: '${datos.cantidadZapatas} unidad(es)',
                  fecha: DateTime.now(),
                  volumenConcretoM3: resultado.volumenConcretoM3,
                  bolsasCemento: materiales.bolsasCemento,
                  arenaM3: materiales.arenaM3,
                  gravaM3: materiales.gravaM3,
                  pesoAceroKg: resultado.aceroDireccionX.pesoCompradoKg + resultado.aceroDireccionY.pesoCompradoKg,
                  filas: [
                    {'etiqueta': 'Volumen de concreto', 'valor': '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'},
                    {'etiqueta': 'Cemento', 'valor': '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'},
                    {'etiqueta': 'Cama X', 'valor': '${datos.cantidadBarrasDireccionX} x ${datos.diametroCama.etiqueta}'},
                    {'etiqueta': 'Cama Y', 'valor': '${datos.cantidadBarrasDireccionY} x ${datos.diametroCama.etiqueta}'},
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

// ============================= CORRIDA =============================

class _FormularioCorrida extends StatefulWidget {
  const _FormularioCorrida();

  @override
  State<_FormularioCorrida> createState() => _FormularioCorridaState();
}

class _FormularioCorridaState extends State<_FormularioCorrida> {
  final _formKey = GlobalKey<FormState>();
  final _longitudController = TextEditingController(text: '10');
  final _anchoController = TextEditingController(text: '50');
  final _profundidadController = TextEditingController(text: '30');
  final _recubrimientoController = TextEditingController(text: '7.5');
  final _cantidadVarillasController = TextEditingController(text: '3');
  final _separacionTransversalController = TextEditingController(text: '20');
  final _cantidadController = TextEditingController(text: '1');

  DiametroVarilla _diametroLongitudinal = DiametroVarilla.n4;
  DiametroVarilla _diametroTransversal = DiametroVarilla.n3;
  DosificacionConcreto _dosificacion = DosificacionConcreto.tabla[2];

  ResultadoZapataCorrida? _resultado;
  DatosZapataCorrida? _datosVista;

  @override
  void dispose() {
    _longitudController.dispose();
    _anchoController.dispose();
    _profundidadController.dispose();
    _recubrimientoController.dispose();
    _cantidadVarillasController.dispose();
    _separacionTransversalController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  DatosZapataCorrida? _leerDatos() {
    final longitud = double.tryParse(_longitudController.text.replaceAll(',', '.'));
    final ancho = double.tryParse(_anchoController.text.replaceAll(',', '.'));
    final profundidad = double.tryParse(_profundidadController.text.replaceAll(',', '.'));
    final recubrimiento = double.tryParse(_recubrimientoController.text.replaceAll(',', '.'));
    final cantidadVarillas = int.tryParse(_cantidadVarillasController.text);
    final separacionTransversal = double.tryParse(_separacionTransversalController.text.replaceAll(',', '.'));
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;

    if (longitud == null ||
        ancho == null ||
        profundidad == null ||
        recubrimiento == null ||
        cantidadVarillas == null ||
        separacionTransversal == null) {
      return null;
    }

    return DatosZapataCorrida(
      longitudTotalM: longitud,
      anchoCm: ancho,
      profundidadCm: profundidad,
      recubrimientoCm: recubrimiento,
      diametroLongitudinal: _diametroLongitudinal,
      cantidadVarillasLongitudinales: cantidadVarillas,
      diametroTransversal: _diametroTransversal,
      separacionTransversalCm: separacionTransversal,
      cantidadZapatas: cantidad,
    );
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    final datos = _leerDatos();
    if (datos == null) return;
    setState(() {
      _datosVista = datos;
      _resultado = CalcularZapataCorrida()(datos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text(
            'Volumen = longitud total x ancho x profundidad',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          TextFormField(
            controller: _longitudController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Longitud total de la zapata', suffixText: 'm'),
            validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
          ),
          const SizedBox(height: AppConstants.paddingMd),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _anchoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Ancho', suffixText: 'cm'),
                  validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                child: TextFormField(
                  controller: _profundidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Profundidad', suffixText: 'cm'),
                  validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMd),
          TextFormField(
            controller: _recubrimientoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Recubrimiento',
              suffixText: 'cm',
              helperText: 'Típico: 7.5 cm (fundida contra tierra)',
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
          Text('Acero longitudinal', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DiametroVarilla.values.map((d) {
              return ChoiceChip(
                label: Text(d.etiqueta),
                selected: _diametroLongitudinal == d,
                onSelected: (_) => setState(() => _diametroLongitudinal = d),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _cantidadVarillasController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad de varillas longitudinales'),
            validator: (v) => int.tryParse(v ?? '') == null ? 'Requerido' : null,
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Bastones transversales', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [DiametroVarilla.n3, DiametroVarilla.n4].map((d) {
              return ChoiceChip(
                label: Text(d.etiqueta),
                selected: _diametroTransversal == d,
                onSelected: (_) => setState(() => _diametroTransversal = d),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _separacionTransversalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Separación entre bastones', suffixText: 'cm'),
            validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Requerido' : null,
          ),
          const SizedBox(height: AppConstants.paddingLg),
          TextFormField(
            controller: _cantidadController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad de tramos iguales',
              helperText: 'Si tienes varios tramos de zapata corrida iguales',
            ),
            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Mínimo 1' : null,
          ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular zapata corrida'),
          ),
          if (_resultado != null && _datosVista != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoCorrida(resultado: _resultado!, datos: _datosVista!, dosificacion: _dosificacion),
          ],
          const SizedBox(height: AppConstants.paddingMd),
          Text(
            'Cuantifica materiales para las dimensiones y armado que definiste. El ancho y espesor real '
            'depende de la capacidad portante del suelo y la carga del muro — confírmalo con un ingeniero.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _TarjetaResultadoCorrida extends StatelessWidget {
  final ResultadoZapataCorrida resultado;
  final DatosZapataCorrida datos;
  final DosificacionConcreto dosificacion;

  const _TarjetaResultadoCorrida({required this.resultado, required this.datos, required this.dosificacion});

  @override
  Widget build(BuildContext context) {
    final materiales = CalcularMaterialesConcreto()(volumenM3: resultado.volumenConcretoM3, dosificacion: dosificacion);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              datos.cantidadZapatas > 1 ? 'Material para ${datos.cantidadZapatas} tramos iguales' : 'Material para el tramo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            _Fila('Volumen de concreto', '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'),
            Text("f'c = ${dosificacion.fc} kg/cm²", style: Theme.of(context).textTheme.bodySmall),
            _Fila('Cemento', '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'),
            _Fila('Arena', '${materiales.arenaM3.toStringAsFixed(2)} m³'),
            _Fila('Grava', '${materiales.gravaM3.toStringAsFixed(2)} m³'),
            const Divider(height: AppConstants.paddingLg),
            Text('Acero longitudinal', style: Theme.of(context).textTheme.titleSmall),
            _Fila('Longitud lineal total', '${resultado.aceroLongitudinal.longitudUtilTotalM.toStringAsFixed(2)} m'),
            _Fila('Varillas COMERCIALES a comprar', '${resultado.aceroLongitudinal.varillasComercialesNecesarias}'),
            _Fila('Peso a comprar', '${resultado.aceroLongitudinal.pesoCompradoKg.toStringAsFixed(2)} kg'),
            const Divider(height: AppConstants.paddingLg),
            Text('Bastones transversales', style: Theme.of(context).textTheme.titleSmall),
            _Fila('Cantidad', '${resultado.cantidadBastonesPorZapata}'),
            _Fila('Varillas COMERCIALES a comprar', '${resultado.aceroTransversal.varillasComercialesNecesarias}'),
            _Fila('Peso a comprar', '${resultado.aceroTransversal.pesoCompradoKg.toStringAsFixed(2)} kg'),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Zapata corrida ${datos.longitudTotalM.toStringAsFixed(2)} m',
                subtitulo: '${datos.anchoCm.toStringAsFixed(0)}x${datos.profundidadCm.toStringAsFixed(0)} cm',
                filas: [
                  FilaPdf('Volumen de concreto', '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'),
                  FilaPdf("f'c", "${dosificacion.fc} kg/cm²"),
                  FilaPdf('Cemento', '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'),
                  FilaPdf('Arena', '${materiales.arenaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Grava', '${materiales.gravaM3.toStringAsFixed(2)} m³'),
                  FilaPdf('Acero longitudinal', '${resultado.aceroLongitudinal.pesoCompradoKg.toStringAsFixed(2)} kg'),
                  FilaPdf('Bastones transversales', '${resultado.cantidadBastonesPorZapata}'),
                  FilaPdf('Peso bastones', '${resultado.aceroTransversal.pesoCompradoKg.toStringAsFixed(2)} kg'),
                ],
                nota: 'Cuantificación de materiales para las dimensiones y armado especificados. No sustituye '
                    'el diseño geotécnico/estructural — confírmalo con un ingeniero antes de construir.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                final pesoTotal = resultado.aceroLongitudinal.pesoCompradoKg + resultado.aceroTransversal.pesoCompradoKg;
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Zapata',
                  titulo: 'Zapata corrida ${datos.longitudTotalM.toStringAsFixed(2)} m',
                  subtitulo: '${datos.anchoCm.toStringAsFixed(0)}x${datos.profundidadCm.toStringAsFixed(0)} cm',
                  fecha: DateTime.now(),
                  volumenConcretoM3: resultado.volumenConcretoM3,
                  bolsasCemento: materiales.bolsasCemento,
                  arenaM3: materiales.arenaM3,
                  gravaM3: materiales.gravaM3,
                  pesoAceroKg: pesoTotal,
                  filas: [
                    {'etiqueta': 'Volumen de concreto', 'valor': '${resultado.volumenConcretoM3.toStringAsFixed(2)} m³'},
                    {'etiqueta': 'Cemento', 'valor': '${materiales.bolsasCemento.ceil()} sacos de 42.5 kg'},
                    {'etiqueta': 'Peso total de acero', 'valor': '${pesoTotal.toStringAsFixed(2)} kg'},
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

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _Leyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
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
