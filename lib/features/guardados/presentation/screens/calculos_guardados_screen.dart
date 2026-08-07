import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_calculos_guardados.dart';
import 'package:structia/features/importar_ocr/presentation/screens/importar_captura_screen.dart';

class CalculosGuardadosScreen extends StatefulWidget {
  const CalculosGuardadosScreen({super.key});

  @override
  State<CalculosGuardadosScreen> createState() => _CalculosGuardadosScreenState();
}

class _CalculosGuardadosScreenState extends State<CalculosGuardadosScreen> {
  late Future<List<CalculoGuardado>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = RepositorioCalculosGuardados.listar();
  }

  void _recargar() {
    setState(() => _futuro = RepositorioCalculosGuardados.listar());
  }

  Future<void> _eliminar(String id) async {
    await RepositorioCalculosGuardados.eliminar(id);
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis cálculos guardados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_search_outlined),
            tooltip: 'Recuperar desde capturas',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportarCapturaScreen()),
              );
              _recargar();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<CalculoGuardado>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final calculos = snapshot.data!;
          if (calculos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_outlined,
                        size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: AppConstants.paddingMd),
                    const Text(
                      'Aún no has guardado ningún cálculo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppConstants.paddingSm),
                    const Text(
                      'Desde cualquier calculadora, toca "Guardar en mi proyecto" para irlos acumulando aquí.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.paddingMd),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ImportarCapturaScreen()),
                        );
                        _recargar();
                      },
                      icon: const Icon(Icons.image_search_outlined),
                      label: const Text('Recuperar desde capturas'),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalConcreto = calculos.fold(0.0, (s, c) => s + (c.volumenConcretoM3 ?? 0));
          final totalBolsas = calculos.fold(0.0, (s, c) => s + (c.bolsasCemento ?? 0));
          final totalArena = calculos.fold(0.0, (s, c) => s + (c.arenaM3 ?? 0));
          final totalGrava = calculos.fold(0.0, (s, c) => s + (c.gravaM3 ?? 0));
          final totalAcero = calculos.fold(0.0, (s, c) => s + (c.pesoAceroKg ?? 0));
          final totalBloques = calculos.fold(0.0, (s, c) => s + (c.bloquesTotal ?? 0));
          final totalMortero = calculos.fold(0.0, (s, c) => s + (c.morteroM3 ?? 0));
          final totalAreaMuros = calculos.fold(0.0, (s, c) => s + (c.areaNetaM2 ?? 0));

          return ListView(
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total del proyecto (${calculos.length} elementos)',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppConstants.paddingSm),
                      _FilaTotal('Concreto', '${totalConcreto.toStringAsFixed(2)} m³'),
                      if (totalBolsas > 0)
                        _FilaTotal('Cemento', '${totalBolsas.ceil()} sacos de 42.5 kg'),
                      if (totalArena > 0) _FilaTotal('Arena', '${totalArena.toStringAsFixed(2)} m³'),
                      if (totalGrava > 0) _FilaTotal('Grava', '${totalGrava.toStringAsFixed(2)} m³'),
                      if (totalAcero > 0) _FilaTotal('Acero', '${totalAcero.toStringAsFixed(2)} kg'),
                      if (totalBloques > 0) _FilaTotal('Bloques', '${totalBloques.ceil()} unidades'),
                      if (totalMortero > 0) _FilaTotal('Mortero', '${totalMortero.toStringAsFixed(2)} m³'),
                      if (totalAreaMuros > 0)
                        _FilaTotal('Área de muros', '${totalAreaMuros.toStringAsFixed(2)} m²'),
                      const SizedBox(height: AppConstants.paddingSm),
                      OutlinedButton.icon(
                        onPressed: () => exportarResultadosPdf(
                          titulo: 'Resumen del proyecto',
                          subtitulo: '${calculos.length} elementos guardados',
                          filas: [
                            FilaPdf('Concreto total', '${totalConcreto.toStringAsFixed(2)} m³'),
                            if (totalBolsas > 0)
                              FilaPdf('Cemento total', '${totalBolsas.ceil()} sacos de 42.5 kg'),
                            if (totalArena > 0) FilaPdf('Arena total', '${totalArena.toStringAsFixed(2)} m³'),
                            if (totalGrava > 0) FilaPdf('Grava total', '${totalGrava.toStringAsFixed(2)} m³'),
                            if (totalAcero > 0) FilaPdf('Acero total', '${totalAcero.toStringAsFixed(2)} kg'),
                            if (totalBloques > 0) FilaPdf('Bloques total', '${totalBloques.ceil()} unidades'),
                            if (totalMortero > 0) FilaPdf('Mortero total', '${totalMortero.toStringAsFixed(2)} m³'),
                            if (totalAreaMuros > 0)
                              FilaPdf('Área de muros total', '${totalAreaMuros.toStringAsFixed(2)} m²'),
                            ...calculos.map((c) => FilaPdf(c.titulo, c.subtitulo)),
                          ],
                          nota: 'Suma de todos los elementos guardados en StructIA. Cada elemento fue '
                              'calculado con el armado y dosificación que tú especificaste — confirma el '
                              'diseño estructural con un ingeniero antes de construir.',
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exportar resumen del proyecto a PDF'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMd),
              ...calculos.map((calculo) {
                return Card(
                  child: ExpansionTile(
                    leading: _IconoPorTipo(tipo: calculo.tipo),
                    title: Text(calculo.titulo),
                    subtitle: Text(calculo.subtitulo),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _eliminar(calculo.id),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMd,
                          vertical: AppConstants.paddingSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: calculo.filas
                              .map((f) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(f['etiqueta'] ?? '')),
                                        Text(f['valor'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _FilaTotal(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _IconoPorTipo extends StatelessWidget {
  final String tipo;

  const _IconoPorTipo({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final iconos = {
      'Columna': Icons.view_column_outlined,
      'Viga': Icons.horizontal_rule,
      'Zapata': Icons.crop_din,
      'Concreto': Icons.foundation_outlined,
      'Acero': Icons.grid_4x4,
      'Presupuesto': Icons.payments_outlined,
      'Mampostería': Icons.grid_view_outlined,
      'Cerámica': Icons.grid_on_outlined,
    };
    return Icon(iconos[tipo] ?? Icons.calculate_outlined);
  }
}
