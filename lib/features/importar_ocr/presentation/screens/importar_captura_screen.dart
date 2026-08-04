import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/ocr/borrador_calculo.dart';
import 'package:structia/core/ocr/linea_ocr.dart';
import 'package:structia/core/ocr/parser_captura.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';

/// Agrupa los elementos de texto reconocidos por posición vertical (misma
/// altura en la imagen), sin importar en qué "bloque" o "línea" los haya
/// separado ML Kit. Así reconstruimos correctamente filas de
/// "etiqueta ........ valor" aunque el hueco entre ambas columnas haga que
/// ML Kit las lea como bloques distintos.
List<LineaOcr> _agruparEnFilas(RecognizedText recognizedText) {
  final elementos = <TextElement>[];
  for (final block in recognizedText.blocks) {
    for (final line in block.lines) {
      elementos.addAll(line.elements);
    }
  }
  if (elementos.isEmpty) return [];

  elementos.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

  final filas = <List<TextElement>>[];
  for (final el in elementos) {
    final centroY = el.boundingBox.top + el.boundingBox.height / 2;
    List<TextElement>? filaEncontrada;
    for (final fila in filas) {
      final refY = fila.first.boundingBox.top + fila.first.boundingBox.height / 2;
      final alturaRef = fila.first.boundingBox.height;
      if ((centroY - refY).abs() < alturaRef * 0.6) {
        filaEncontrada = fila;
        break;
      }
    }
    (filaEncontrada ?? (filas..add([])).last).add(el);
  }

  return filas.map((fila) {
    fila.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    return LineaOcr(
      texto: fila.map((e) => e.text).join(' '),
      elementos: fila
          .map((e) => ElementoOcr(
                texto: e.text,
                left: e.boundingBox.left.toDouble(),
                right: e.boundingBox.right.toDouble(),
              ))
          .toList(),
    );
  }).toList();
}

class ImportarCapturaScreen extends StatefulWidget {
  const ImportarCapturaScreen({super.key});

  @override
  State<ImportarCapturaScreen> createState() => _ImportarCapturaScreenState();
}

class _ImportarCapturaScreenState extends State<ImportarCapturaScreen> {
  final _picker = ImagePicker();
  final _reconocedor = TextRecognizer(script: TextRecognitionScript.latin);
  final List<CalculoBorrador> _borradores = [];
  bool _procesando = false;
  String? _error;

  @override
  void dispose() {
    _reconocedor.close();
    super.dispose();
  }

  Future<void> _elegirCapturas() async {
    final List<XFile> archivos;
    try {
      archivos = await _picker.pickMultiImage(imageQuality: 100);
    } catch (e) {
      setState(() => _error = 'No pude abrir la galería: $e');
      return;
    }
    if (archivos.isEmpty) return;

    setState(() {
      _procesando = true;
      _error = null;
    });

    var huboSinDatos = false;
    try {
      for (final archivo in archivos) {
        final inputImage = InputImage.fromFilePath(archivo.path);
        final recognizedText = await _reconocedor.processImage(inputImage);
        final filas = _agruparEnFilas(recognizedText);
        final encontrados = extraerCalculosDeTexto(filas);
        if (encontrados.isEmpty) {
          huboSinDatos = true;
        } else {
          _borradores.addAll(encontrados);
        }
      }
    } catch (e) {
      _error = 'Ocurrió un problema leyendo alguna imagen: $e';
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
          if (huboSinDatos && _error == null) {
            _error = 'En al menos una captura no reconocí ningún proyecto. '
                'Prueba con una captura más nítida o recorta solo la tarjeta del cálculo.';
          }
        });
      }
    }
  }

  Future<void> _guardarTodo() async {
    for (var i = 0; i < _borradores.length; i++) {
      final borrador = _borradores[i];
      final campos = camposNumericosDesde(borrador.filas);
      await RepositorioCalculosGuardados.guardar(CalculoGuardado(
        id: '${DateTime.now().microsecondsSinceEpoch}_$i',
        tipo: borrador.tipo,
        titulo: borrador.titulo,
        subtitulo: borrador.subtitulo,
        fecha: DateTime.now(),
        filas: borrador.filas.map((f) => {'etiqueta': f.etiqueta, 'valor': f.valor}).toList(),
        volumenConcretoM3: campos.volumenConcretoM3,
        bolsasCemento: campos.bolsasCemento,
        arenaM3: campos.arenaM3,
        gravaM3: campos.gravaM3,
        pesoAceroKg: campos.pesoAceroKg,
        bloquesTotal: campos.bloquesTotal,
        morteroM3: campos.morteroM3,
        areaNetaM2: campos.areaNetaM2,
      ));
    }
    if (!mounted) return;
    final cantidad = _borradores.length;
    setState(() => _borradores.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$cantidad proyecto(s) recreado(s) en "Mis cálculos guardados"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar desde capturas')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sube capturas de "Mis cálculos guardados" o de la pantalla de resultado de una '
              'calculadora. Voy a intentar reconocer cada proyecto — revisa y corrige lo que '
              'haga falta antes de guardar, el OCR no siempre acierta el 100%.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingMd),
            FilledButton.icon(
              onPressed: _procesando ? null : _elegirCapturas,
              icon: _procesando
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.image_search_outlined),
              label: Text(_procesando ? 'Leyendo capturas…' : 'Elegir capturas'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConstants.paddingSm),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: AppConstants.paddingMd),
            Expanded(
              child: _borradores.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no hay proyectos detectados',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _borradores.length,
                      itemBuilder: (context, i) => _TarjetaBorrador(
                        key: ObjectKey(_borradores[i]),
                        borrador: _borradores[i],
                        onEliminar: () => setState(() => _borradores.removeAt(i)),
                      ),
                    ),
            ),
            if (_borradores.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingSm),
              FilledButton.tonalIcon(
                onPressed: _guardarTodo,
                icon: const Icon(Icons.save_outlined),
                label: Text('Guardar ${_borradores.length} proyecto(s) en mi proyecto'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaBorrador extends StatefulWidget {
  final CalculoBorrador borrador;
  final VoidCallback onEliminar;

  const _TarjetaBorrador({super.key, required this.borrador, required this.onEliminar});

  @override
  State<_TarjetaBorrador> createState() => _TarjetaBorradorState();
}

class _TarjetaBorradorState extends State<_TarjetaBorrador> {
  late final TextEditingController _tituloController;
  late final TextEditingController _subtituloController;
  late final List<TextEditingController> _etiquetaControllers;
  late final List<TextEditingController> _valorControllers;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.borrador.titulo)
      ..addListener(() => widget.borrador.titulo = _tituloController.text);
    _subtituloController = TextEditingController(text: widget.borrador.subtitulo)
      ..addListener(() => widget.borrador.subtitulo = _subtituloController.text);
    _etiquetaControllers = widget.borrador.filas
        .map((f) => TextEditingController(text: f.etiqueta))
        .toList();
    _valorControllers =
        widget.borrador.filas.map((f) => TextEditingController(text: f.valor)).toList();
    for (var i = 0; i < widget.borrador.filas.length; i++) {
      _etiquetaControllers[i]
          .addListener(() => widget.borrador.filas[i].etiqueta = _etiquetaControllers[i].text);
      _valorControllers[i]
          .addListener(() => widget.borrador.filas[i].valor = _valorControllers[i].text);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _subtituloController.dispose();
    for (final c in _etiquetaControllers) {
      c.dispose();
    }
    for (final c in _valorControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _agregarFila() {
    setState(() {
      widget.borrador.filas.add(FilaBorrador(etiqueta: '', valor: ''));
      final i = widget.borrador.filas.length - 1;
      final ec = TextEditingController()
        ..addListener(() => widget.borrador.filas[i].etiqueta = _etiquetaControllers[i].text);
      final vc = TextEditingController()
        ..addListener(() => widget.borrador.filas[i].valor = _valorControllers[i].text);
      _etiquetaControllers.add(ec);
      _valorControllers.add(vc);
    });
  }

  void _eliminarFila(int i) {
    setState(() {
      widget.borrador.filas.removeAt(i);
      _etiquetaControllers.removeAt(i).dispose();
      _valorControllers.removeAt(i).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: kTiposCalculoGuardado.contains(widget.borrador.tipo)
                        ? widget.borrador.tipo
                        : kTiposCalculoGuardado.first,
                    decoration: const InputDecoration(labelText: 'Tipo', isDense: true),
                    items: kTiposCalculoGuardado
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => widget.borrador.tipo = v);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Descartar este proyecto',
                  onPressed: widget.onEliminar,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSm),
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título', isDense: true),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            TextFormField(
              controller: _subtituloController,
              decoration: const InputDecoration(labelText: 'Subtítulo', isDense: true),
            ),
            const SizedBox(height: AppConstants.paddingMd),
            Text('Datos', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            ...List.generate(widget.borrador.filas.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _etiquetaControllers[i],
                        decoration: const InputDecoration(isDense: true, hintText: 'Etiqueta'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSm),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _valorControllers[i],
                        decoration: const InputDecoration(isDense: true, hintText: 'Valor'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _eliminarFila(i),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _agregarFila,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar fila'),
            ),
          ],
        ),
      ),
    );
  }
}
