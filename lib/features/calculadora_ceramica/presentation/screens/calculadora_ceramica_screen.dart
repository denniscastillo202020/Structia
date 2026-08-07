import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_ceramica/domain/calcular_ceramica.dart';

class CalculadoraCeramicaScreen extends StatefulWidget {
  const CalculadoraCeramicaScreen({super.key});

  @override
  State<CalculadoraCeramicaScreen> createState() => _CalculadoraCeramicaScreenState();
}

class _CalculadoraCeramicaScreenState extends State<CalculadoraCeramicaScreen> {
  final List<Superficie> _superficies = [];
  int _contadorSuperficie = 0;

  TamanoPieza _pieza = TamanoPieza.presets[3]; // 40x40, tamaño común
  bool _piezaPersonalizada = false;
  final _anchoPiezaController = TextEditingController(text: '40');
  final _altoPiezaController = TextEditingController(text: '40');

  final _desperdicioController = TextEditingController(text: '10');

  ResultadoCeramica? _resultado;

  @override
  void dispose() {
    _anchoPiezaController.dispose();
    _altoPiezaController.dispose();
    _desperdicioController.dispose();
    super.dispose();
  }

  double? _num(String texto) => double.tryParse(texto.trim().replaceAll(',', '.'));

  TamanoPieza get _piezaEfectiva {
    if (!_piezaPersonalizada) return _pieza;
    return TamanoPieza(
      etiqueta: 'Personalizada',
      anchoCm: _num(_anchoPiezaController.text) ?? 40,
      altoCm: _num(_altoPiezaController.text) ?? 40,
    );
  }

  Future<void> _agregarSuperficie() async {
    final resultado = await _mostrarDialogoAgregar(
      titulo: 'Añadir superficie',
      etiquetaInicial: 'Área ${_superficies.length + 1}',
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _contadorSuperficie++;
      _superficies.add(Superficie(
        id: 's$_contadorSuperficie',
        etiqueta: resultado.etiqueta,
        largoM: resultado.a,
        anchoM: resultado.b,
      ));
      _resultado = null;
    });
  }

  Future<_DatosDialogo?> _mostrarDialogoAgregar({
    required String titulo,
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
                decoration: const InputDecoration(labelText: 'Largo (m)'),
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
                decoration: const InputDecoration(labelText: 'Ancho (m)'),
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
    if (_superficies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una superficie')),
      );
      return;
    }
    final desperdicio = _num(_desperdicioController.text);
    if (desperdicio == null || desperdicio < 0) return;

    final resultado = CalcularCeramica()(
      superficies: _superficies,
      pieza: _piezaEfectiva,
      porcentajeDesperdicio: desperdicio,
    );
    setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cerámica y porcelanato')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text('Superficies a enchapar', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          if (_superficies.isEmpty)
            Text('Aún no has añadido superficies (piso o pared)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ..._superficies.map((s) => _TarjetaItem(
                titulo: s.etiqueta,
                subtitulo:
                    '${s.largoM.toStringAsFixed(2)} x ${s.anchoM.toStringAsFixed(2)} m  ·  ${s.areaM2.toStringAsFixed(2)} m²',
                onEliminar: () => setState(() {
                  _superficies.remove(s);
                  _resultado = null;
                }),
              )),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton.icon(
            onPressed: _agregarSuperficie,
            icon: const Icon(Icons.add),
            label: const Text('Añadir superficie'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Tamaño de la pieza', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          ...TamanoPieza.presets.map((t) {
            final seleccionado = !_piezaPersonalizada && _pieza.etiqueta == t.etiqueta;
            return Card(
              color: seleccionado
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                  : null,
              child: RadioListTile<String>(
                value: t.etiqueta,
                groupValue: _piezaPersonalizada ? null : _pieza.etiqueta,
                onChanged: (_) => setState(() {
                  _pieza = t;
                  _piezaPersonalizada = false;
                  _resultado = null;
                }),
                title: Text(t.etiqueta),
              ),
            );
          }),
          Card(
            color: _piezaPersonalizada
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                : null,
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: true,
                  groupValue: _piezaPersonalizada,
                  onChanged: (_) => setState(() {
                    _piezaPersonalizada = true;
                    _resultado = null;
                  }),
                  title: const Text('Personalizada'),
                ),
                if (_piezaPersonalizada)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _anchoPiezaController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Ancho (cm)'),
                            onChanged: (_) => setState(() => _resultado = null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _altoPiezaController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Alto (cm)'),
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
          TextFormField(
            controller: _desperdicioController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Desperdicio (cortes, roturas)',
              suffixText: '%',
            ),
            onChanged: (_) => setState(() => _resultado = null),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular piezas y pega'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoCeramica(
              resultado: _resultado!,
              pieza: _piezaEfectiva,
              superficies: List.of(_superficies),
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

class _TarjetaResultadoCeramica extends StatelessWidget {
  final ResultadoCeramica resultado;
  final TamanoPieza pieza;
  final List<Superficie> superficies;

  const _TarjetaResultadoCeramica({
    required this.resultado,
    required this.pieza,
    required this.superficies,
  });

  String get _explicacion {
    final buffer = StringBuffer();
    buffer.write('Se sumaron ${superficies.length} superficie(s): ');
    buffer.write(superficies
        .map((s) => '${s.etiqueta} (${s.largoM.toStringAsFixed(2)}x${s.anchoM.toStringAsFixed(2)} m)')
        .join(', '));
    buffer.write(' = ${resultado.areaNetaM2.toStringAsFixed(2)} m² netos. ');
    buffer.write('Con desperdicio: ${resultado.areaConDesperdicioM2.toStringAsFixed(2)} m².');
    return buffer.toString();
  }

  List<Map<String, String>> get _filasDetalladas {
    final filas = <Map<String, String>>[];
    for (final s in superficies) {
      filas.add({
        'etiqueta': 'Superficie: ${s.etiqueta} (${s.largoM.toStringAsFixed(2)} x ${s.anchoM.toStringAsFixed(2)} m)',
        'valor': '+${s.areaM2.toStringAsFixed(2)} m²',
      });
    }
    filas.addAll([
      {'etiqueta': 'Pieza', 'valor': '${pieza.anchoCm.toStringAsFixed(0)} x ${pieza.altoCm.toStringAsFixed(0)} cm'},
      {'etiqueta': 'Área neta', 'valor': '${resultado.areaNetaM2.toStringAsFixed(2)} m²'},
      {'etiqueta': 'Área con desperdicio', 'valor': '${resultado.areaConDesperdicioM2.toStringAsFixed(2)} m²'},
      {'etiqueta': 'Piezas netas', 'valor': resultado.piezasNetas.ceil().toString()},
      {'etiqueta': 'Piezas a comprar', 'valor': resultado.piezasTotalComprar.toString()},
      {'etiqueta': 'Pega cerámica (kg)', 'valor': resultado.kgPegaTotal.toStringAsFixed(1)},
      {
        'etiqueta': 'Pega cerámica (sacos de 20 kg)',
        'valor': '${resultado.sacosPega} · rinde ${resultado.rendimientoM2PorSaco.toStringAsFixed(1)} m²/saco',
      },
    ]);
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
            Text('Área a enchapar: ${resultado.areaNetaM2.toStringAsFixed(2)} m²',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Pieza ${pieza.anchoCm.toStringAsFixed(0)} x ${pieza.altoCm.toStringAsFixed(0)} cm',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              _explicacion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const Divider(height: AppConstants.paddingLg),
            Text('Piezas', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.grid_on_outlined,
              etiqueta: 'Piezas netas',
              valor: resultado.piezasNetas.ceil().toString(),
            ),
            _FilaResultado(
              icono: Icons.shopping_cart_outlined,
              etiqueta: 'Total a comprar',
              valor: resultado.piezasTotalComprar.toString(),
              destacado: true,
            ),
            const Divider(height: AppConstants.paddingLg),
            Text('Pega cerámica', style: Theme.of(context).textTheme.titleSmall),
            _FilaResultado(
              icono: Icons.scale_outlined,
              etiqueta: 'Total en kg',
              valor: '${resultado.kgPegaTotal.toStringAsFixed(1)} kg',
            ),
            _FilaResultado(
              icono: Icons.inventory_2_outlined,
              etiqueta: 'Sacos de 20 kg',
              valor: resultado.sacosPega.toString(),
              destacado: true,
            ),
            _FilaResultado(
              icono: Icons.info_outline,
              etiqueta: 'Rendimiento usado',
              valor: '${resultado.rendimientoM2PorSaco.toStringAsFixed(1)} m²/saco',
            ),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Cerámica y porcelanato',
                subtitulo: _explicacion,
                filas: _filasDetalladas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota:
                    'Estimación de campo. El rendimiento de la pega (sacos de 20 kg) se ajusta '
                    'automáticamente según el tamaño de la pieza: entre más grande la pieza, más '
                    'gruesa la capa y menor rendimiento por saco (piezas ≤20x20 cm ≈5.3 m²/saco, '
                    '30x30 a 45x45 cm ≈4.4 m²/saco, porcelanato grande ≈3.3 m²/saco). '
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
                  tipo: 'Cerámica',
                  titulo: 'Cerámica ${resultado.areaNetaM2.toStringAsFixed(2)} m²',
                  subtitulo:
                      '${pieza.anchoCm.toStringAsFixed(0)}x${pieza.altoCm.toStringAsFixed(0)} cm · ${resultado.piezasTotalComprar} piezas · ${resultado.sacosPega} sacos pega',
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
