import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_techo/domain/calcular_techo.dart';

class CalculadoraTechoScreen extends StatefulWidget {
  const CalculadoraTechoScreen({super.key});

  @override
  State<CalculadoraTechoScreen> createState() => _CalculadoraTechoScreenState();
}

class _CalculadoraTechoScreenState extends State<CalculadoraTechoScreen> {
  final List<Faldon> _faldones = [];
  int _contadorFaldon = 0;

  TipoLamina _tipoLamina = TipoLamina.presets[0]; // Aluzinc acanalada
  final _largoLaminaController = TextEditingController();
  final _desperdicioController = TextEditingController(text: '5');

  final _canaletaMetrosController = TextEditingController();
  final _canaletaTramoController = TextEditingController(text: '3');

  final _caballeteMetrosController = TextEditingController();
  final _caballeteTramoController = TextEditingController(text: '2.44');

  int _tornillosEmpaque = 100;

  ResultadoTecho? _resultado;

  @override
  void dispose() {
    _largoLaminaController.dispose();
    _desperdicioController.dispose();
    _canaletaMetrosController.dispose();
    _canaletaTramoController.dispose();
    _caballeteMetrosController.dispose();
    _caballeteTramoController.dispose();
    super.dispose();
  }

  double? _num(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));
  double _numOr0(String texto) => _num(texto) ?? 0;

  Future<void> _agregarFaldon() async {
    final resultado = await _mostrarDialogoAgregar(
      titulo: 'Añadir faldón (agua del techo)',
      etiquetaA: 'Ancho (m)',
      etiquetaB: 'Largo de bajada (m)',
      etiquetaInicial: 'Faldón ${_faldones.length + 1}',
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _contadorFaldon++;
      _faldones.add(Faldon(
        id: 'f$_contadorFaldon',
        etiqueta: resultado.etiqueta,
        anchoM: resultado.a,
        largoM: resultado.b,
      ));
      _resultado = null;
    });
  }

  Future<_DatosDialogo?> _mostrarDialogoAgregar({
    required String titulo,
    required String etiquetaA,
    required String etiquetaB,
    required String etiquetaInicial,
  }) {
    final nombreController = TextEditingController(text: etiquetaInicial);
    final aController = TextEditingController();
    final bController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<_DatosDialogo>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Form(
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
            ],
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
    if (_faldones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un faldón')),
      );
      return;
    }
    final largoLamina = _num(_largoLaminaController.text);
    if (largoLamina == null || largoLamina <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el largo de lámina que vas a usar')),
      );
      return;
    }
    final desperdicio = _num(_desperdicioController.text);
    if (desperdicio == null || desperdicio < 0) return;

    final canaletaTramo = _num(_canaletaTramoController.text) ?? 3;
    final caballeteTramo = _num(_caballeteTramoController.text) ?? 2.44;

    final resultado = CalcularTecho()(
      faldones: _faldones,
      tipoLamina: _tipoLamina,
      largoLaminaM: largoLamina,
      porcentajeDesperdicio: desperdicio,
      canaletaMetrosLineales: _numOr0(_canaletaMetrosController.text),
      canaletaTramoM: canaletaTramo <= 0 ? 3 : canaletaTramo,
      caballeteMetrosLineales: _numOr0(_caballeteMetrosController.text),
      caballeteTramoM: caballeteTramo <= 0 ? 2.44 : caballeteTramo,
      tornillosEmpaque: _tornillosEmpaque,
    );
    setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Techo')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text('Faldones (aguas del techo)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          if (_faldones.isEmpty)
            Text('Aún no has añadido faldones',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ..._faldones.map((f) => _TarjetaItem(
                titulo: f.etiqueta,
                subtitulo:
                    'Ancho ${f.anchoM.toStringAsFixed(2)} m  ·  Bajada ${f.largoM.toStringAsFixed(2)} m  ·  ${f.areaM2.toStringAsFixed(2)} m²',
                onEliminar: () => setState(() {
                  _faldones.remove(f);
                  _resultado = null;
                }),
              )),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton.icon(
            onPressed: _agregarFaldon,
            icon: const Icon(Icons.add),
            label: const Text('Añadir faldón'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Tipo de lámina', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          ...TipoLamina.presets.map((t) {
            final seleccionado = _tipoLamina.etiqueta == t.etiqueta;
            return Card(
              color: seleccionado
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                  : null,
              child: RadioListTile<String>(
                value: t.etiqueta,
                groupValue: _tipoLamina.etiqueta,
                onChanged: (_) => setState(() {
                  _tipoLamina = t;
                  _resultado = null;
                }),
                title: Text(t.etiqueta),
              ),
            );
          }),
          const SizedBox(height: AppConstants.paddingSm),
          TextFormField(
            controller: _largoLaminaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Largo de lámina a usar',
              suffixText: 'm',
              helperText: 'Debe cubrir la bajada de cada faldón en una sola pieza',
            ),
            onChanged: (_) => setState(() => _resultado = null),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          TextFormField(
            controller: _desperdicioController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Desperdicio (cortes, traslapes extra)',
              suffixText: '%',
            ),
            onChanged: (_) => setState(() => _resultado = null),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Canaleta (opcional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _canaletaMetrosController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Metros lineales', suffixText: 'm'),
                  onChanged: (_) => setState(() => _resultado = null),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                child: TextFormField(
                  controller: _canaletaTramoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Tramo comercial', suffixText: 'm'),
                  onChanged: (_) => setState(() => _resultado = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Caballete / cumbrera (opcional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _caballeteMetrosController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Metros lineales', suffixText: 'm'),
                  onChanged: (_) => setState(() => _resultado = null),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                child: TextFormField(
                  controller: _caballeteTramoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Tramo comercial', suffixText: 'm'),
                  onChanged: (_) => setState(() => _resultado = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Tornillos autorroscantes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: _tornillosEmpaque == 100
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                      : null,
                  child: RadioListTile<int>(
                    value: 100,
                    groupValue: _tornillosEmpaque,
                    onChanged: (v) => setState(() {
                      _tornillosEmpaque = v!;
                      _resultado = null;
                    }),
                    title: const Text('Caja de 100'),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  color: _tornillosEmpaque == 250
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                      : null,
                  child: RadioListTile<int>(
                    value: 250,
                    groupValue: _tornillosEmpaque,
                    onChanged: (v) => setState(() {
                      _tornillosEmpaque = v!;
                      _resultado = null;
                    }),
                    title: const Text('Caja de 250'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular materiales de techo'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoTecho(
              resultado: _resultado!,
              tipoLamina: _tipoLamina,
              largoLaminaM: _num(_largoLaminaController.text) ?? 0,
              faldones: List.of(_faldones),
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
  const _DatosDialogo({required this.etiqueta, required this.a, required this.b});
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

class _TarjetaResultadoTecho extends StatelessWidget {
  final ResultadoTecho resultado;
  final TipoLamina tipoLamina;
  final double largoLaminaM;
  final List<Faldon> faldones;

  const _TarjetaResultadoTecho({
    required this.resultado,
    required this.tipoLamina,
    required this.largoLaminaM,
    required this.faldones,
  });

  String get _explicacion {
    final buffer = StringBuffer();
    buffer.write('Se sumaron ${faldones.length} faldón(es): ');
    buffer.write(faldones
        .map((f) => '${f.etiqueta} (${f.anchoM.toStringAsFixed(2)}x${f.largoM.toStringAsFixed(2)} m)')
        .join(', '));
    buffer.write(' = ${resultado.areaNetaM2.toStringAsFixed(2)} m².');
    if (resultado.advertenciaLargo) {
      buffer.write(' ⚠ Al menos un faldón es más largo que la lámina ingresada '
          '(${largoLaminaM.toStringAsFixed(2)} m) — súmale traslape longitudinal a mano.');
    }
    return buffer.toString();
  }

  List<Map<String, String>> get _filasDetalladas {
    final filas = <Map<String, String>>[];
    for (final f in faldones) {
      filas.add({
        'etiqueta': 'Faldón: ${f.etiqueta} (${f.anchoM.toStringAsFixed(2)} x ${f.largoM.toStringAsFixed(2)} m)',
        'valor': '${f.areaM2.toStringAsFixed(2)} m²',
      });
    }
    filas.addAll([
      {'etiqueta': 'Área total', 'valor': '${resultado.areaNetaM2.toStringAsFixed(2)} m²'},
      {'etiqueta': 'Tipo de lámina', 'valor': tipoLamina.etiqueta},
      {'etiqueta': 'Láminas netas', 'valor': resultado.laminasNetas.toString()},
      {'etiqueta': 'Láminas desperdicio', 'valor': resultado.laminasDesperdicio.toString()},
      {'etiqueta': 'Láminas total a comprar', 'valor': resultado.laminasTotalComprar.toString()},
      {'etiqueta': 'Tornillos', 'valor': '${resultado.tornillosTotal} (${resultado.tornillosCajas} caja(s))'},
    ]);
    if (resultado.canaletaMetrosLineales > 0) {
      filas.add({
        'etiqueta': 'Canaleta',
        'valor': '${resultado.canaletaMetrosLineales.toStringAsFixed(2)} m · ${resultado.canaletaTramos} tramo(s)',
      });
    }
    if (resultado.caballeteMetrosLineales > 0) {
      filas.add({
        'etiqueta': 'Caballete/cumbrera',
        'valor':
            '${resultado.caballeteMetrosLineales.toStringAsFixed(2)} m · ${resultado.caballeteTramos} tramo(s)',
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
            Text('Área de techo: ${resultado.areaNetaM2.toStringAsFixed(2)} m²',
                style: Theme.of(context).textTheme.titleMedium),
            Text(tipoLamina.etiqueta, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              _explicacion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: resultado.advertenciaLargo
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outline,
                  ),
            ),
            const Divider(height: AppConstants.paddingLg),
            Text('Láminas', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.grid_view_outlined,
              etiqueta: 'Netas',
              valor: resultado.laminasNetas.toString(),
            ),
            _FilaResultado(
              icono: Icons.layers_outlined,
              etiqueta: 'Desperdicio',
              valor: resultado.laminasDesperdicio.toString(),
            ),
            _FilaResultado(
              icono: Icons.shopping_cart_outlined,
              etiqueta: 'Total a comprar',
              valor: resultado.laminasTotalComprar.toString(),
              destacado: true,
            ),
            if (resultado.canaletaMetrosLineales > 0) ...[
              const Divider(height: AppConstants.paddingLg),
              Text('Canaleta', style: Theme.of(context).textTheme.titleSmall),
              _FilaResultado(
                icono: Icons.straighten_outlined,
                etiqueta: 'Metros lineales',
                valor: '${resultado.canaletaMetrosLineales.toStringAsFixed(2)} m',
              ),
              _FilaResultado(
                icono: Icons.shopping_cart_outlined,
                etiqueta: 'Tramos a comprar',
                valor: resultado.canaletaTramos.toString(),
                destacado: true,
              ),
            ],
            if (resultado.caballeteMetrosLineales > 0) ...[
              const Divider(height: AppConstants.paddingLg),
              Text('Caballete / cumbrera', style: Theme.of(context).textTheme.titleSmall),
              _FilaResultado(
                icono: Icons.straighten_outlined,
                etiqueta: 'Metros lineales',
                valor: '${resultado.caballeteMetrosLineales.toStringAsFixed(2)} m',
              ),
              _FilaResultado(
                icono: Icons.shopping_cart_outlined,
                etiqueta: 'Tramos a comprar',
                valor: resultado.caballeteTramos.toString(),
                destacado: true,
              ),
            ],
            const Divider(height: AppConstants.paddingLg),
            Text('Tornillos', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.hardware_outlined,
              etiqueta: 'Unidades',
              valor: resultado.tornillosTotal.toString(),
            ),
            _FilaResultado(
              icono: Icons.inventory_2_outlined,
              etiqueta: 'Cajas a comprar',
              valor: resultado.tornillosCajas.toString(),
              destacado: true,
            ),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Techo',
                subtitulo: _explicacion,
                filas: _filasDetalladas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota:
                    'Estimación de campo. Se asume que el largo de lámina cubre cada bajada en una '
                    'sola pieza; si algún faldón es más largo, suma traslape longitudinal (usualmente '
                    '20 cm) a mano. Tornillos calculados a $tornillosPorM2 unidades/m². '
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
                  tipo: 'Techo',
                  titulo: 'Techo ${resultado.areaNetaM2.toStringAsFixed(2)} m²',
                  subtitulo: '${resultado.laminasTotalComprar} láminas · ${tipoLamina.etiqueta}',
                  fecha: DateTime.now(),
                  areaNetaM2: resultado.areaNetaM2,
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
              'Estimación de campo — no sustituye el criterio del maestro de obra ni la ficha '
              'técnica del fabricante.',
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
