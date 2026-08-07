import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_electrico/domain/calcular_electrico.dart';

class CalculadoraElectricoScreen extends StatefulWidget {
  const CalculadoraElectricoScreen({super.key});

  @override
  State<CalculadoraElectricoScreen> createState() => _CalculadoraElectricoScreenState();
}

class _CalculadoraElectricoScreenState extends State<CalculadoraElectricoScreen> {
  final List<PuntoElectrico> _puntos = [];
  int _contadorPunto = 0;

  final List<Breaker> _breakers = [];
  int _contadorBreaker = 0;

  final _desperdicioController = TextEditingController(text: '10');
  final _espaciadoController = TextEditingController(text: '0.6');
  int _conductoresPorPunto = 3;

  CalibreCable _calibreIluminacion = CalibreCable.presets[0];
  CalibreCable _calibreTomacorrientes = CalibreCable.presets[1];

  ResultadoElectrico? _resultado;

  @override
  void dispose() {
    _desperdicioController.dispose();
    _espaciadoController.dispose();
    super.dispose();
  }

  double? _num(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  Future<void> _agregarPunto() async {
    final resultado = await _mostrarDialogoPunto();
    if (resultado == null || !mounted) return;
    setState(() {
      _contadorPunto++;
      _puntos.add(PuntoElectrico(
        id: 'e$_contadorPunto',
        etiqueta: resultado.etiqueta,
        tipo: resultado.tipo,
        distanciaM: resultado.distancia,
      ));
      _resultado = null;
    });
  }

  Future<_DatosPunto?> _mostrarDialogoPunto() {
    var tipo = TipoPunto.tomacorriente;
    final nombreController =
        TextEditingController(text: '${tipo.etiqueta} ${_puntos.length + 1}');
    final distanciaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<_DatosPunto>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir punto eléctrico'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TipoPunto>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo de punto'),
                    items: TipoPunto.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.etiqueta)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => tipo = v ?? tipo),
                  ),
                  const SizedBox(height: AppConstants.paddingSm),
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre / referencia'),
                  ),
                  const SizedBox(height: AppConstants.paddingSm),
                  TextFormField(
                    controller: distanciaController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Distancia desde el panel principal',
                      suffixText: 'm',
                      helperText: 'Siguiendo el recorrido real del cableado, no en línea recta',
                    ),
                    validator: (v) {
                      final val = double.tryParse((v ?? '').replaceAll(',', '.'));
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
                  _DatosPunto(
                    etiqueta: nombreController.text.trim().isEmpty
                        ? tipo.etiqueta
                        : nombreController.text.trim(),
                    tipo: tipo,
                    distancia: double.parse(distanciaController.text.replaceAll(',', '.')),
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

  Future<void> _agregarBreaker() async {
    final resultado = await _mostrarDialogoBreaker();
    if (resultado == null || !mounted) return;
    setState(() {
      _contadorBreaker++;
      _breakers.add(Breaker(
        id: 'b$_contadorBreaker',
        etiqueta: resultado.etiqueta,
        amperaje: resultado.amperaje,
      ));
      _resultado = null;
    });
  }

  Future<_DatosBreaker?> _mostrarDialogoBreaker() {
    var amperaje = 20;
    final nombreController =
        TextEditingController(text: 'Circuito ${_breakers.length + 1}');
    const amperajes = [15, 20, 30, 40, 50];

    return showDialog<_DatosBreaker>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir breaker / circuito'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Descripción del circuito'),
              ),
              const SizedBox(height: AppConstants.paddingSm),
              DropdownButtonFormField<int>(
                initialValue: amperaje,
                decoration: const InputDecoration(labelText: 'Amperaje'),
                items: amperajes
                    .map((a) => DropdownMenuItem(value: a, child: Text('$a A')))
                    .toList(),
                onChanged: (v) => setDialogState(() => amperaje = v ?? amperaje),
              ),
              const SizedBox(height: AppConstants.paddingSm),
              Text(
                'Confirma el amperaje con un electricista según la carga real del circuito.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _DatosBreaker(
                  etiqueta: nombreController.text.trim().isEmpty
                      ? 'Circuito'
                      : nombreController.text.trim(),
                  amperaje: amperaje,
                ),
              ),
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  void _calcular() {
    if (_puntos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un punto eléctrico')),
      );
      return;
    }
    final desperdicio = _num(_desperdicioController.text);
    final espaciado = _num(_espaciadoController.text);
    if (desperdicio == null || desperdicio < 0 || espaciado == null || espaciado <= 0) return;

    final resultado = CalcularElectrico()(
      puntos: _puntos,
      breakers: _breakers,
      porcentajeDesperdicio: desperdicio,
      espaciadoAbrazaderasM: espaciado,
      conductoresPorPunto: _conductoresPorPunto,
      calibreIluminacion: _calibreIluminacion,
      calibreTomacorrientes: _calibreTomacorrientes,
    );
    setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instalación eléctrica')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text('Puntos eléctricos', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          if (_puntos.isEmpty)
            Text('Aún no has añadido puntos (switch, foco, tomacorriente)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ..._puntos.map((p) => _TarjetaItem(
                titulo: p.etiqueta,
                subtitulo: '${p.tipo.etiqueta}  ·  ${p.distanciaM.toStringAsFixed(1)} m del panel',
                onEliminar: () => setState(() {
                  _puntos.remove(p);
                  _resultado = null;
                }),
              )),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton.icon(
            onPressed: _agregarPunto,
            icon: const Icon(Icons.add),
            label: const Text('Añadir punto'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Manguera y cable', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _desperdicioController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Desperdicio', suffixText: '%'),
                  onChanged: (_) => setState(() => _resultado = null),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                child: TextFormField(
                  controller: _espaciadoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Espaciado abrazaderas', suffixText: 'm'),
                  onChanged: (_) => setState(() => _resultado = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSm),
          DropdownButtonFormField<int>(
            initialValue: _conductoresPorPunto,
            decoration: const InputDecoration(
              labelText: 'Conductores por punto',
              helperText: 'Fase + neutro + tierra = 3, típico',
            ),
            items: const [2, 3, 4]
                .map((n) => DropdownMenuItem(value: n, child: Text('$n conductores')))
                .toList(),
            onChanged: (v) => setState(() {
              _conductoresPorPunto = v ?? 3;
              _resultado = null;
            }),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          DropdownButtonFormField<CalibreCable>(
            initialValue: _calibreIluminacion,
            decoration: const InputDecoration(labelText: 'Calibre — iluminación (switch/foco)'),
            items: CalibreCable.presets
                .map((c) => DropdownMenuItem(value: c, child: Text(c.etiqueta)))
                .toList(),
            onChanged: (v) => setState(() {
              _calibreIluminacion = v ?? _calibreIluminacion;
              _resultado = null;
            }),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          DropdownButtonFormField<CalibreCable>(
            initialValue: _calibreTomacorrientes,
            decoration: const InputDecoration(labelText: 'Calibre — tomacorrientes'),
            items: CalibreCable.presets
                .map((c) => DropdownMenuItem(value: c, child: Text(c.etiqueta)))
                .toList(),
            onChanged: (v) => setState(() {
              _calibreTomacorrientes = v ?? _calibreTomacorrientes;
              _resultado = null;
            }),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Breakers / tablero (opcional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          if (_breakers.isEmpty)
            Text('Aún no has añadido circuitos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ..._breakers.map((b) => _TarjetaItem(
                titulo: b.etiqueta,
                subtitulo: '${b.amperaje} A',
                onEliminar: () => setState(() {
                  _breakers.remove(b);
                  _resultado = null;
                }),
              )),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton.icon(
            onPressed: _agregarBreaker,
            icon: const Icon(Icons.add),
            label: const Text('Añadir breaker'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular materiales eléctricos'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoElectrico(
              resultado: _resultado!,
              puntos: List.of(_puntos),
              breakers: List.of(_breakers),
              calibreIluminacion: _calibreIluminacion,
              calibreTomacorrientes: _calibreTomacorrientes,
            ),
          ],
        ],
      ),
    );
  }
}

class _DatosPunto {
  final String etiqueta;
  final TipoPunto tipo;
  final double distancia;
  const _DatosPunto({required this.etiqueta, required this.tipo, required this.distancia});
}

class _DatosBreaker {
  final String etiqueta;
  final int amperaje;
  const _DatosBreaker({required this.etiqueta, required this.amperaje});
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

class _TarjetaResultadoElectrico extends StatelessWidget {
  final ResultadoElectrico resultado;
  final List<PuntoElectrico> puntos;
  final List<Breaker> breakers;
  final CalibreCable calibreIluminacion;
  final CalibreCable calibreTomacorrientes;

  const _TarjetaResultadoElectrico({
    required this.resultado,
    required this.puntos,
    required this.breakers,
    required this.calibreIluminacion,
    required this.calibreTomacorrientes,
  });

  String get _explicacion {
    final buffer = StringBuffer();
    buffer.write('Se sumaron ${puntos.length} punto(s) eléctrico(s): ');
    buffer.write(puntos
        .map((p) => '${p.etiqueta} (${p.distanciaM.toStringAsFixed(1)} m)')
        .join(', '));
    buffer.write('. Manguera neta: ${resultado.mangueraNetaM.toStringAsFixed(1)} m, '
        'con desperdicio: ${resultado.mangueraConDesperdicioM.toStringAsFixed(1)} m.');
    return buffer.toString();
  }

  List<Map<String, String>> get _filasDetalladas {
    final filas = <Map<String, String>>[];
    for (final p in puntos) {
      filas.add({
        'etiqueta': '${p.tipo.etiqueta}: ${p.etiqueta}',
        'valor': '${p.distanciaM.toStringAsFixed(1)} m',
      });
    }
    filas.addAll([
      {'etiqueta': 'Manguera neta', 'valor': '${resultado.mangueraNetaM.toStringAsFixed(1)} m'},
      {
        'etiqueta': 'Manguera con desperdicio',
        'valor': '${resultado.mangueraConDesperdicioM.toStringAsFixed(1)} m',
      },
      {'etiqueta': 'Abrazaderas', 'valor': resultado.abrazaderas.toString()},
      {
        'etiqueta': 'Cable iluminación (${calibreIluminacion.etiqueta})',
        'valor':
            '${resultado.cableIluminacionM.toStringAsFixed(1)} m · ${resultado.rollosIluminacion} rollo(s)',
      },
      {
        'etiqueta': 'Cable tomacorrientes (${calibreTomacorrientes.etiqueta})',
        'valor':
            '${resultado.cableTomacorrientesM.toStringAsFixed(1)} m · ${resultado.rollosTomacorrientes} rollo(s)',
      },
      {'etiqueta': 'Cajas rectangulares', 'valor': resultado.cajasRectangulares.toString()},
      {'etiqueta': 'Cajas octagonales', 'valor': resultado.cajasOctagonales.toString()},
      {'etiqueta': 'Tornillos de cajas', 'valor': resultado.tornillosCajas.toString()},
      {'etiqueta': 'Tape aislante', 'valor': '${resultado.rollosTape} rollo(s)'},
    ]);
    if (breakers.isNotEmpty) {
      for (final b in breakers) {
        filas.add({'etiqueta': 'Breaker: ${b.etiqueta}', 'valor': '${b.amperaje} A'});
      }
      filas.add({
        'etiqueta': 'Tablero sugerido',
        'valor': resultado.tableroEspacios != null
            ? '${resultado.tableroEspacios} espacios'
            : 'Más de 24 espacios — combinar tableros',
      });
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
            Text('Manguera: ${resultado.mangueraConDesperdicioM.toStringAsFixed(1)} m',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              _explicacion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const Divider(height: AppConstants.paddingLg),
            Text('Manguera y abrazaderas', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.cable_outlined,
              etiqueta: 'Manguera total a comprar',
              valor: '${resultado.mangueraConDesperdicioM.toStringAsFixed(1)} m',
              destacado: true,
            ),
            _FilaResultado(
              icono: Icons.push_pin_outlined,
              etiqueta: 'Abrazaderas',
              valor: resultado.abrazaderas.toString(),
            ),
            const Divider(height: AppConstants.paddingLg),
            Text('Cable', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.lightbulb_outline,
              etiqueta: 'Iluminación (${calibreIluminacion.etiqueta})',
              valor: '${resultado.rollosIluminacion} rollo(s)',
              destacado: true,
            ),
            _FilaResultado(
              icono: Icons.power_outlined,
              etiqueta: 'Tomacorrientes (${calibreTomacorrientes.etiqueta})',
              valor: '${resultado.rollosTomacorrientes} rollo(s)',
              destacado: true,
            ),
            const Divider(height: AppConstants.paddingLg),
            Text('Cajas y accesorios', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.crop_square_outlined,
              etiqueta: 'Cajas rectangulares',
              valor: resultado.cajasRectangulares.toString(),
            ),
            _FilaResultado(
              icono: Icons.hexagon_outlined,
              etiqueta: 'Cajas octagonales',
              valor: resultado.cajasOctagonales.toString(),
            ),
            _FilaResultado(
              icono: Icons.hardware_outlined,
              etiqueta: 'Tornillos',
              valor: resultado.tornillosCajas.toString(),
            ),
            _FilaResultado(
              icono: Icons.line_style_outlined,
              etiqueta: 'Tape aislante',
              valor: '${resultado.rollosTape} rollo(s)',
            ),
            if (breakers.isNotEmpty) ...[
              const Divider(height: AppConstants.paddingLg),
              Text('Breakers y tablero', style: Theme.of(context).textTheme.titleSmall),
              _FilaResultado(
                icono: Icons.electric_bolt_outlined,
                etiqueta: 'Breakers agregados',
                valor: resultado.cantidadBreakers.toString(),
              ),
              _FilaResultado(
                icono: Icons.dashboard_outlined,
                etiqueta: 'Tablero sugerido',
                valor: resultado.tableroEspacios != null
                    ? '${resultado.tableroEspacios} espacios'
                    : 'Combinar tableros (+24)',
                destacado: true,
              ),
            ],
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Instalación eléctrica',
                subtitulo: _explicacion,
                filas: _filasDetalladas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota:
                    'Estimación de campo de materiales (manguera, cable, cajas, tornillos, tape). '
                    'El diseño de circuitos, el amperaje de cada breaker y el balanceo de cargas '
                    'SIEMPRE deben ser confirmados y ejecutados por un electricista certificado — '
                    'esta app no valida seguridad eléctrica.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Eléctrico',
                  titulo: 'Eléctrico ${puntos.length} puntos',
                  subtitulo:
                      '${resultado.mangueraConDesperdicioM.toStringAsFixed(1)} m manguera · ${resultado.rollosIluminacion + resultado.rollosTomacorrientes} rollos cable',
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
              '⚠ Estimación de campo de materiales. El diseño de circuitos y el amperaje de cada '
              'breaker deben ser confirmados por un electricista certificado — no sustituye su '
              'criterio ni las normas locales.',
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
