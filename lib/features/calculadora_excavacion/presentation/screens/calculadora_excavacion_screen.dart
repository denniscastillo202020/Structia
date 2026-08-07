import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/calculadora_excavacion/domain/calcular_excavacion.dart';

class CalculadoraExcavacionScreen extends StatefulWidget {
  const CalculadoraExcavacionScreen({super.key});

  @override
  State<CalculadoraExcavacionScreen> createState() => _CalculadoraExcavacionScreenState();
}

class _CalculadoraExcavacionScreenState extends State<CalculadoraExcavacionScreen> {
  final List<ZapataExcavacion> _zapatas = [];
  int _contador = 0;

  ResultadoExcavacion? _resultado;

  Future<void> _agregarZapata() async {
    final resultado = await _mostrarDialogoZapata();
    if (resultado == null || !mounted) return;
    setState(() {
      _contador++;
      _zapatas.add(ZapataExcavacion(
        id: 'z$_contador',
        etiqueta: resultado.etiqueta,
        largoZapataM: resultado.largo,
        anchoZapataM: resultado.ancho,
        profundidadM: resultado.profundidad,
        cantidad: resultado.cantidad,
      ));
      _resultado = null;
    });
  }

  Future<_DatosZapata?> _mostrarDialogoZapata() {
    final nombreController =
        TextEditingController(text: 'Zapata ${_zapatas.length + 1}');
    final largoController = TextEditingController();
    final anchoController = TextEditingController();
    final profundidadController = TextEditingController();
    final cantidadController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    return showDialog<_DatosZapata>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir zapata'),
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
                  controller: largoController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Largo de la zapata', suffixText: 'm'),
                  validator: (v) {
                    final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Requerido';
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingSm),
                TextFormField(
                  controller: anchoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Ancho de la zapata', suffixText: 'm'),
                  validator: (v) {
                    final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Requerido';
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingSm),
                TextFormField(
                  controller: profundidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Profundidad', suffixText: 'm'),
                  validator: (v) {
                    final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Requerido';
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingSm),
                TextFormField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad de zapatas iguales'),
                  validator: (v) {
                    final val = int.tryParse((v ?? '').trim());
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
                _DatosZapata(
                  etiqueta: nombreController.text.trim().isEmpty
                      ? 'Zapata'
                      : nombreController.text.trim(),
                  largo: double.parse(largoController.text.replaceAll(',', '.')),
                  ancho: double.parse(anchoController.text.replaceAll(',', '.')),
                  profundidad: double.parse(profundidadController.text.replaceAll(',', '.')),
                  cantidad: int.parse(cantidadController.text.trim()),
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
    if (_zapatas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una zapata')),
      );
      return;
    }
    setState(() => _resultado = CalcularExcavacion()(zapatas: _zapatas));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excavación y relleno')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text(
            'Ingresa las mismas dimensiones que usaste en "Zapatas" (largo, ancho, profundidad). '
            'Se le suma automáticamente el margen de trabajo (${ConstantesExcavacionTexto.margen}) '
            'y la sobreexcavación de fondo (${ConstantesExcavacionTexto.sobreexcavacion}).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          Text('Zapatas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          if (_zapatas.isEmpty)
            Text('Aún no has añadido zapatas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ..._zapatas.map((z) => Card(
                child: ListTile(
                  title: Text(z.etiqueta),
                  subtitle: Text(
                    '${z.largoZapataM.toStringAsFixed(2)} × ${z.anchoZapataM.toStringAsFixed(2)} × '
                    '${z.profundidadM.toStringAsFixed(2)} m'
                    '${z.cantidad > 1 ? '  ×${z.cantidad}' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      _zapatas.remove(z);
                      _resultado = null;
                    }),
                  ),
                ),
              )),
          const SizedBox(height: AppConstants.paddingSm),
          OutlinedButton.icon(
            onPressed: _agregarZapata,
            icon: const Icon(Icons.add),
            label: const Text('Añadir zapata'),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular excavación'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoExcavacion(resultado: _resultado!, zapatas: List.of(_zapatas)),
          ],
        ],
      ),
    );
  }
}

class ConstantesExcavacionTexto {
  static const margen = '0.10 m por lado';
  static const sobreexcavacion = '0.05 m';
}

class _DatosZapata {
  final String etiqueta;
  final double largo;
  final double ancho;
  final double profundidad;
  final int cantidad;
  const _DatosZapata({
    required this.etiqueta,
    required this.largo,
    required this.ancho,
    required this.profundidad,
    required this.cantidad,
  });
}

class _TarjetaResultadoExcavacion extends StatelessWidget {
  final ResultadoExcavacion resultado;
  final List<ZapataExcavacion> zapatas;

  const _TarjetaResultadoExcavacion({required this.resultado, required this.zapatas});

  List<Map<String, String>> get _filasDetalladas {
    final filas = <Map<String, String>>[];
    for (final d in resultado.detallesPorZapata) {
      filas.add({
        'etiqueta': '${d.etiqueta} — excavación',
        'valor': '${d.volumenExcavacionM3.toStringAsFixed(2)} m³',
      });
      filas.add({
        'etiqueta': '${d.etiqueta} — relleno',
        'valor': '${d.volumenRellenoM3.toStringAsFixed(2)} m³',
      });
    }
    filas.addAll([
      {
        'etiqueta': 'Excavación total',
        'valor': '${resultado.volumenExcavacionTotalM3.toStringAsFixed(2)} m³',
      },
      {
        'etiqueta': 'Relleno total',
        'valor': '${resultado.volumenRellenoTotalM3.toStringAsFixed(2)} m³',
      },
      {
        'etiqueta': 'Concreto de referencia (zapatas)',
        'valor': '${resultado.volumenConcretoReferenciaM3.toStringAsFixed(2)} m³',
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
            Text('${resultado.volumenExcavacionTotalM3.toStringAsFixed(2)} m³ a excavar',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.paddingMd),
            _Fila('Excavación total', '${resultado.volumenExcavacionTotalM3.toStringAsFixed(2)} m³',
                destacado: true),
            _Fila('Relleno total (compactado)', '${resultado.volumenRellenoTotalM3.toStringAsFixed(2)} m³',
                destacado: true),
            _Fila('Concreto de referencia', '${resultado.volumenConcretoReferenciaM3.toStringAsFixed(2)} m³'),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Excavación y relleno',
                subtitulo: '${resultado.volumenExcavacionTotalM3.toStringAsFixed(2)} m³ de excavación',
                filas: _filasDetalladas.map((f) => FilaPdf(f['etiqueta']!, f['valor']!)).toList(),
                nota: 'Estimación de campo. Incluye margen de trabajo de 0.10 m por lado y '
                    'sobreexcavación de fondo de 0.05 m. El tipo de suelo, nivel freático y '
                    'profundidad real de desplante deben confirmarse con un ingeniero según el '
                    'estudio de suelos.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            FilledButton.tonalIcon(
              onPressed: () async {
                await RepositorioCalculosGuardados.guardar(CalculoGuardado(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  tipo: 'Excavación',
                  titulo: 'Excavación ${resultado.volumenExcavacionTotalM3.toStringAsFixed(2)} m³',
                  subtitulo: 'Relleno: ${resultado.volumenRellenoTotalM3.toStringAsFixed(2)} m³',
                  fecha: DateTime.now(),
                  filas: _filasDetalladas,
                  volumenExcavacionM3: resultado.volumenExcavacionTotalM3,
                  volumenRellenoM3: resultado.volumenRellenoTotalM3,
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
              '⚠ Estimación de campo. Confirma el tipo de suelo y la profundidad real de '
              'desplante con un ingeniero.',
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

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;
  const _Fila(this.etiqueta, this.valor, {this.destacado = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(etiqueta,
                style: destacado ? const TextStyle(fontWeight: FontWeight.w600) : null),
          ),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
