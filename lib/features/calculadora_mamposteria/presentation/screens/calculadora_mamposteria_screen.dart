import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_mamposteria/domain/calcular_mamposteria.dart';

class CalculadoraMamposteriaScreen extends StatefulWidget {
  const CalculadoraMamposteriaScreen({super.key});

  @override
  State<CalculadoraMamposteriaScreen> createState() => _CalculadoraMamposteriaScreenState();
}

class _CalculadoraMamposteriaScreenState extends State<CalculadoraMamposteriaScreen> {
  final List<Pared> _paredes = [];
  final List<Vano> _vanos = [];

  TipoBloque _tipoBloque = TipoBloque.presets[1];
  bool _bloquePersonalizado = false;
  final _largoBloqueController = TextEditingController(text: '40');
  final _altoBloqueController = TextEditingController(text: '20');
  final _espesorBloqueController = TextEditingController(text: '15');

  final _juntaController = TextEditingController(text: '1.5');
  final _desperdicioController = TextEditingController(text: '5');

  DosificacionMortero _dosificacionMortero = DosificacionMortero.tabla[1]; // 1:4, uso general

  ResultadoMamposteria? _resultado;
  int _contadorPared = 0;
  int _contadorVano = 0;

  @override
  void dispose() {
    _largoBloqueController.dispose();
    _altoBloqueController.dispose();
    _espesorBloqueController.dispose();
    _juntaController.dispose();
    _desperdicioController.dispose();
    super.dispose();
  }

  double? _num(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  TipoBloque get _tipoBloqueEfectivo {
    if (!_bloquePersonalizado) return _tipoBloque;
    return TipoBloque(
      etiqueta: 'Bloque personalizado',
      largoCm: _num(_largoBloqueController.text) ?? 40,
      altoCm: _num(_altoBloqueController.text) ?? 20,
      espesorCm: _num(_espesorBloqueController.text) ?? 15,
    );
  }

  Future<void> _agregarPared() async {
    final resultado = await _mostrarDialogoAgregar(
      titulo: 'Añadir pared',
      etiquetaA: 'Largo (m)',
      etiquetaB: 'Alto (m)',
      etiquetaInicial: 'Pared ${_paredes.length + 1}',
      mostrarAcabados: true,
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _contadorPared++;
      _paredes.add(Pared(
        id: 'p$_contadorPared',
        etiqueta: resultado.etiqueta,
        largoM: resultado.a,
        altoM: resultado.b,
        llevaRepello: resultado.repello,
        llevaPulido: resultado.pulido,
      ));
      _resultado = null;
    });
  }

  Future<void> _agregarVano(String tipoSugerido) async {
    final resultado = await _mostrarDialogoAgregar(
      titulo: 'Añadir $tipoSugerido',
      etiquetaA: 'Ancho (m)',
      etiquetaB: 'Alto (m)',
      etiquetaInicial:
          '$tipoSugerido ${_vanos.where((v) => v.etiqueta.startsWith(tipoSugerido)).length + 1}',
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _contadorVano++;
      _vanos.add(Vano(
        id: 'v$_contadorVano',
        etiqueta: resultado.etiqueta,
        anchoM: resultado.a,
        altoM: resultado.b,
      ));
      _resultado = null;
    });
  }

  Future<_DatosDialogo?> _mostrarDialogoAgregar({
    required String titulo,
    required String etiquetaA,
    required String etiquetaB,
    required String etiquetaInicial,
    bool mostrarAcabados = false,
  }) {
    final nombreController = TextEditingController(text: etiquetaInicial);
    final aController = TextEditingController();
    final bController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var repello = false;
    var pulido = false;

    return showDialog<_DatosDialogo>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(titulo),
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
                    controller: aController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: etiquetaA),
                    validator: (v) {
                      final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (val == null || val <= 0) return 'Requerido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingSm),
                  TextFormField(
                    controller: bController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: etiquetaB),
                    validator: (v) {
                      final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (val == null || val <= 0) return 'Requerido';
                      return null;
                    },
                  ),
                  if (mostrarAcabados) ...[
                    const Divider(height: AppConstants.paddingLg),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: repello,
                      onChanged: (v) => setDialogState(() => repello = v),
                      title: const Text('Lleva repello'),
                      subtitle: const Text('2 cm de espesor'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: pulido,
                      onChanged: (v) => setDialogState(() => pulido = v),
                      title: const Text('Lleva pulido'),
                      subtitle: const Text('3 a 5 mm de espesor'),
                    ),
                  ],
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
                  _DatosDialogo(
                    etiqueta: nombreController.text.trim().isEmpty
                        ? etiquetaInicial
                        : nombreController.text.trim(),
                    a: double.parse(aController.text.replaceAll(',', '.')),
                    b: double.parse(bController.text.replaceAll(',', '.')),
                    repello: repello,
                    pulido: pulido,
                  ),
                );
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  void _calcular() {
    if (_paredes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una pared')),
      );
      return;
    }
    final junta = _num(_juntaController.text);
    final desperdicio = _num(_desperdicioController.text);
    if (junta == null || junta < 0 || desperdicio == null || desperdicio < 0) return;

    final resultado = CalcularMamposteria()(
      paredes: _paredes,
      vanos: _vanos,
      tipoBloque: _tipoBloqueEfectivo,
      espesorJuntaCm: junta,
      porcentajeDesperdicio: desperdicio,
      dosificacionMortero: _dosificacionMortero,
    );
    setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Muros y bloques')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text('Paredes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          if (_paredes.isEmpty)
            Text('Aún no has añadido paredes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ..._paredes.map((p) {
            final acabados = [
              if (p.llevaRepello) 'Repello',
              if (p.llevaPulido) 'Pulido',
            ].join(' · ');
            final subtitulo =
                '${p.largoM.toStringAsFixed(2)} x ${p.altoM.toStringAsFixed(2)} m  ·  ${p.areaM2.toStringAsFixed(2)} m²'
                '${acabados.isNotEmpty ? '  ·  $acabados' : ''}';
            return _TarjetaItem(
              titulo: p.etiqueta,
              subtitulo: subtitulo,
              onEliminar: () => setState(() {
                _paredes.remove(p);
                _resultado = null;
              }),
            );
          }),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton.icon(
            onPressed: _agregarPared,
            icon: const Icon(Icons.add),
            label: const Text('Añadir pared'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Puertas y ventanas (se restan del área)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          if (_vanos.isEmpty)
            Text('Aún no has añadido vanos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ..._vanos.map((v) => _TarjetaItem(
                titulo: v.etiqueta,
                subtitulo: '${v.anchoM.toStringAsFixed(2)} x ${v.altoM.toStringAsFixed(2)} m  ·  ${v.areaM2.toStringAsFixed(2)} m²',
                onEliminar: () => setState(() {
                  _vanos.remove(v);
                  _resultado = null;
                }),
              )),
          const SizedBox(height: AppConstants.paddingSm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _agregarVano('Puerta'),
                  icon: const Icon(Icons.sensor_door_outlined),
                  label: const Text('Puerta'),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _agregarVano('Ventana'),
                  icon: const Icon(Icons.window_outlined),
                  label: const Text('Ventana'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Tipo de bloque', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          ...TipoBloque.presets.map((t) {
            final seleccionado = !_bloquePersonalizado && _tipoBloque.etiqueta == t.etiqueta;
            return Card(
              color: seleccionado
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                  : null,
              child: RadioListTile<String>(
                value: t.etiqueta,
                groupValue: _bloquePersonalizado ? null : _tipoBloque.etiqueta,
                onChanged: (_) => setState(() {
                  _tipoBloque = t;
                  _bloquePersonalizado = false;
                  _resultado = null;
                }),
                title: Text(t.etiqueta),
              ),
            );
          }),
          Card(
            color: _bloquePersonalizado
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                : null,
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: true,
                  groupValue: _bloquePersonalizado,
                  onChanged: (_) => setState(() {
                    _bloquePersonalizado = true;
                    _resultado = null;
                  }),
                  title: const Text('Personalizado'),
                ),
                if (_bloquePersonalizado)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _largoBloqueController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Largo (cm)'),
                            onChanged: (_) => setState(() => _resultado = null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _altoBloqueController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Alto (cm)'),
                            onChanged: (_) => setState(() => _resultado = null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _espesorBloqueController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Espesor (cm)'),
                            onChanged: (_) => setState(() => _resultado = null),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _juntaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Espesor de junta',
                    suffixText: 'cm',
                  ),
                  onChanged: (_) => setState(() => _resultado = null),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                child: TextFormField(
                  controller: _desperdicioController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Desperdicio',
                    suffixText: '%',
                  ),
                  onChanged: (_) => setState(() => _resultado = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Mortero de pega (y repello)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          ...DosificacionMortero.tabla.map((d) {
            final seleccionada = _dosificacionMortero.proporcion == d.proporcion;
            return Card(
              color: seleccionada
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                  : null,
              child: RadioListTile<String>(
                value: d.proporcion,
                groupValue: _dosificacionMortero.proporcion,
                onChanged: (_) => setState(() {
                  _dosificacionMortero = d;
                  _resultado = null;
                }),
                title: Text('${d.etiqueta}  ·  ${d.usoTypico}'),
              ),
            );
          }),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular bloques y mortero'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoMamposteria(
              resultado: _resultado!,
              tipoBloque: _tipoBloqueEfectivo,
              dosificacionMortero: _dosificacionMortero,
              paredes: List.of(_paredes),
              vanos: List.of(_vanos),
            ),
          ],
        ],
      ),
    );
  }
}

class _DatosDialogo {
  final String etiqueta;
  final double a;
  final double b;
  final bool repello;
  final bool pulido;
  const _DatosDialogo({
    required this.etiqueta,
    required this.a,
    required this.b,
    this.repello = false,
    this.pulido = false,
  });
}

class _TarjetaItem extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final VoidCallback onEliminar;

  const _TarjetaItem({required this.titulo, required this.subtitulo, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(subtitulo),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onEliminar,
        ),
      ),
    );
  }
}

class _TarjetaResultadoMamposteria extends StatelessWidget {
  final ResultadoMamposteria resultado;
  final TipoBloque tipoBloque;
  final DosificacionMortero dosificacionMortero;
  final List<Pared> paredes;
  final List<Vano> vanos;

  const _TarjetaResultadoMamposteria({
    required this.resultado,
    required this.tipoBloque,
    required this.dosificacionMortero,
    required this.paredes,
    required this.vanos,
  });

  /// Texto narrativo del proyecto: qué paredes se sumaron y qué vanos
  /// se rebajaron, para que al abrir el cálculo guardado se entienda
  /// de un vistazo cómo se armó el área neta.
  String get _explicacion {
    final buffer = StringBuffer();
    buffer.write('Se sumaron ${paredes.length} pared(es): ');
    buffer.write(paredes
        .map((p) => '${p.etiqueta} (${p.largoM.toStringAsFixed(2)}x${p.altoM.toStringAsFixed(2)} m)')
        .join(', '));
    buffer.write(' = ${resultado.areaBrutaM2.toStringAsFixed(2)} m² brutos.');
    if (vanos.isNotEmpty) {
      buffer.write(' Se rebajaron ${vanos.length} vano(s): ');
      buffer.write(vanos
          .map((v) => '${v.etiqueta} (${v.anchoM.toStringAsFixed(2)}x${v.altoM.toStringAsFixed(2)} m)')
          .join(', '));
      buffer.write(' = ${resultado.areaVanosM2.toStringAsFixed(2)} m².');
    }
    buffer.write(' Área neta a levantar: ${resultado.areaNetaM2.toStringAsFixed(2)} m².');
    if (resultado.areaConRepelloM2 > 0 || resultado.areaConPulidoM2 > 0) {
      buffer.write(' Acabados: ${resultado.areaConRepelloM2.toStringAsFixed(2)} m² con repello, '
          '${resultado.areaConPulidoM2.toStringAsFixed(2)} m² con pulido.');
    }
    return buffer.toString();
  }

  List<Map<String, String>> get _filasDetalladas {
    final filas = <Map<String, String>>[];
    for (final p in paredes) {
      final tags = [
        if (p.llevaRepello) 'repello',
        if (p.llevaPulido) 'pulido',
      ].join('+');
      filas.add({
        'etiqueta': 'Pared: ${p.etiqueta} (${p.largoM.toStringAsFixed(2)} x ${p.altoM.toStringAsFixed(2)} m)'
            '${tags.isNotEmpty ? ' [$tags]' : ''}',
        'valor': '+${p.areaM2.toStringAsFixed(2)} m²',
      });
    }
    for (final v in vanos) {
      filas.add({
        'etiqueta': 'Rebaja: ${v.etiqueta} (${v.anchoM.toStringAsFixed(2)} x ${v.altoM.toStringAsFixed(2)} m)',
        'valor': '−${v.areaM2.toStringAsFixed(2)} m²',
      });
    }
    filas.addAll([
      {'etiqueta': 'Área neta', 'valor': '${resultado.areaNetaM2.toStringAsFixed(2)} m²'},
      {'etiqueta': 'Bloque usable (neto)', 'valor': resultado.bloquesNetos.ceil().toString()},
      {'etiqueta': 'Bloque desperdicio', 'valor': resultado.bloquesDesperdicio.ceil().toString()},
      {'etiqueta': 'Bloque total a comprar', 'valor': resultado.bloquesTotalComprar.toString()},
      {'etiqueta': 'Mortero neto', 'valor': '${resultado.morteroNetoM3.toStringAsFixed(3)} m³'},
      {'etiqueta': 'Mortero desperdicio', 'valor': '${resultado.morteroDesperdicioM3.toStringAsFixed(3)} m³'},
      {'etiqueta': 'Mortero total', 'valor': '${resultado.morteroTotalM3.toStringAsFixed(3)} m³'},
      {'etiqueta': 'Cemento', 'valor': '${resultado.sacosCementoMortero.ceil()} sacos de 42.5 kg'},
      {'etiqueta': 'Arena', 'valor': '${resultado.arenaMorteroM3.toStringAsFixed(2)} m³'},
    ]);
    if (resultado.areaConRepelloM2 > 0) {
      filas.addAll([
        {'etiqueta': 'Área con repello', 'valor': '${resultado.areaConRepelloM2.toStringAsFixed(2)} m²'},
        {'etiqueta': 'Repello mortero', 'valor': '${resultado.repelloMorteroM3.toStringAsFixed(3)} m³'},
        {'etiqueta': 'Repello cemento', 'valor': '${resultado.repelloSacosCemento.ceil()} sacos de 42.5 kg'},
        {'etiqueta': 'Repello arena', 'valor': '${resultado.repelloArenaM3.toStringAsFixed(2)} m³'},
      ]);
    }
    if (resultado.areaConPulidoM2 > 0) {
      filas.addAll([
        {'etiqueta': 'Área con pulido', 'valor': '${resultado.areaConPulidoM2.toStringAsFixed(2)} m²'},
        {'etiqueta': 'Pulido cemento', 'valor': '${resultado.pulidoSacosCemento.ceil()} sacos de 42.5 kg'},
      ]);
    }
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
            Text('Área neta de muro: ${resultado.areaNetaM2.toStringAsFixed(2)} m²',
                style: Theme.of(context).textTheme.titleMedium),
            Text(tipoBloque.etiqueta, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              _explicacion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const Divider(height: AppConstants.paddingLg),
            Text('Bloques', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.grid_view_outlined,
              etiqueta: 'Bloque usable (neto)',
              valor: resultado.bloquesNetos.ceil().toString(),
            ),
            _FilaResultado(
              icono: Icons.layers_outlined,
              etiqueta: 'Desperdicio',
              valor: resultado.bloquesDesperdicio.ceil().toString(),
            ),
            _FilaResultado(
              icono: Icons.shopping_cart_outlined,
              etiqueta: 'Total a comprar',
              valor: resultado.bloquesTotalComprar.toString(),
              destacado: true,
            ),
            const Divider(height: AppConstants.paddingLg),
            Text('Mortero de pega', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.water_outlined,
              etiqueta: 'Neto',
              valor: '${resultado.morteroNetoM3.toStringAsFixed(3)} m³',
            ),
            _FilaResultado(
              icono: Icons.layers_outlined,
              etiqueta: 'Desperdicio',
              valor: '${resultado.morteroDesperdicioM3.toStringAsFixed(3)} m³',
            ),
            _FilaResultado(
              icono: Icons.shopping_cart_outlined,
              etiqueta: 'Total (${dosificacionMortero.proporcion})',
              valor: '${resultado.morteroTotalM3.toStringAsFixed(3)} m³',
              destacado: true,
            ),
            _FilaResultado(
              icono: Icons.inventory_2_outlined,
              etiqueta: 'Cemento (sacos de 42.5 kg)',
              valor: resultado.sacosCementoMortero.ceil().toString(),
            ),
            _FilaResultado(
              icono: Icons.grain,
              etiqueta: 'Arena',
              valor: '${resultado.arenaMorteroM3.toStringAsFixed(2)} m³',
            ),
            if (resultado.areaConRepelloM2 > 0) ...[
              const Divider(height: AppConstants.paddingLg),
              Text('Repello (2 cm)', style: Theme.of(context).textTheme.titleSmall),
              _FilaResultado(
                icono: Icons.crop_square_outlined,
                etiqueta: 'Área con repello',
                valor: '${resultado.areaConRepelloM2.toStringAsFixed(2)} m²',
              ),
              _FilaResultado(
                icono: Icons.inventory_2_outlined,
                etiqueta: 'Cemento',
                valor: '${resultado.repelloSacosCemento.ceil()} sacos de 42.5 kg',
                destacado: true,
              ),
              _FilaResultado(
                icono: Icons.grain,
                etiqueta: 'Arena',
                valor: '${resultado.repelloArenaM3.toStringAsFixed(2)} m³',
              ),
            ],
            if (resultado.areaConPulidoM2 > 0) ...[
              const Divider(height: AppConstants.paddingLg),
              Text('Pulido (3 a 5 mm)', style: Theme.of(context).textTheme.titleSmall),
              _FilaResultado(
                icono: Icons.crop_square_outlined,
                etiqueta: 'Área con pulido',
                valor: '${resultado.areaConPulidoM2.toStringAsFixed(2)} m²',
              ),
              _FilaResultado(
                icono: Icons.inventory_2_outlined,
                etiqueta: 'Cemento (pasta pura)',
                valor: '${resultado.pulidoSacosCemento.ceil()} sacos de 42.5 kg',
                destacado: true,
              ),
            ],
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Muros y bloques',
                subtitulo: _explicacion,
                filas: _filasDetalladas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota:
                    'Estimación de campo (bloques por m² = 1 / ((largo+junta) x (alto+junta))). '
                    'El desperdicio se contabiliza aparte del bloque usable. El repello usa la misma '
                    'dosificación de mortero seleccionada, a 2 cm de espesor; el pulido se estima como '
                    'pasta de cemento pura a razón de 1 saco (42.5 kg) por cada '
                    '${rendimientoPulidoM2PorSaco.toStringAsFixed(0)} m² (3 a 5 mm). '
                    'Confirma cantidades finales con el maestro de obra antes de comprar.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Mampostería',
                  titulo: 'Muros ${resultado.areaNetaM2.toStringAsFixed(2)} m²',
                  subtitulo: '${tipoBloque.etiqueta} · ${resultado.bloquesTotalComprar} bloques',
                  fecha: DateTime.now(),
                  bloquesTotal: resultado.bloquesTotalComprar.toDouble(),
                  morteroM3: resultado.morteroTotalM3,
                  areaNetaM2: resultado.areaNetaM2,
                  bolsasCemento: resultado.sacosCementoMortero,
                  arenaM3: resultado.arenaMorteroM3,
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
              'El desperdicio se calcula y muestra por separado del bloque usable en todo momento. '
              'Estimación de campo — no sustituye el criterio del maestro de obra.',
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
  final bool destacado;

  const _FilaResultado({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppConstants.paddingSm),
          Expanded(
            child: Text(
              etiqueta,
              style: destacado ? const TextStyle(fontWeight: FontWeight.w600) : null,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: destacado ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
