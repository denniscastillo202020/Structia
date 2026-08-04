import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/pdf/exportar_pdf.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';

class CalculadoraAceroScreen extends StatefulWidget {
  const CalculadoraAceroScreen({super.key});

  @override
  State<CalculadoraAceroScreen> createState() => _CalculadoraAceroScreenState();
}

class _CalculadoraAceroScreenState extends State<CalculadoraAceroScreen> {
  final List<TramoRequerido> _tramos = [];
  final _longitudPiezaController = TextEditingController();
  final _cantidadPiezaController = TextEditingController(text: '1');
  final _longitudComercialController = TextEditingController(text: '9');
  final _traslapeController = TextEditingController();

  DiametroVarilla _diametro = DiametroVarilla.n4;
  ResultadoCorteAcero? _resultado;

  @override
  void dispose() {
    _longitudPiezaController.dispose();
    _cantidadPiezaController.dispose();
    _longitudComercialController.dispose();
    _traslapeController.dispose();
    super.dispose();
  }

  void _agregarTramo() {
    final longitud = double.tryParse(_longitudPiezaController.text.replaceAll(',', '.'));
    final cantidad = int.tryParse(_cantidadPiezaController.text);
    if (longitud == null || longitud <= 0 || cantidad == null || cantidad <= 0) return;

    setState(() {
      _tramos.add(TramoRequerido(longitudM: longitud, cantidad: cantidad));
      _longitudPiezaController.clear();
      _cantidadPiezaController.text = '1';
      _resultado = null;
    });
  }

  void _quitarTramo(int index) {
    setState(() {
      _tramos.removeAt(index);
      _resultado = null;
    });
  }

  void _calcular() {
    if (_tramos.isEmpty) return;
    final longitudComercial =
        double.tryParse(_longitudComercialController.text.replaceAll(',', '.')) ?? 9.0;
    final traslapeManual = double.tryParse(_traslapeController.text.replaceAll(',', '.'));

    final resultado = CalcularAcero()(
      tramos: _tramos,
      diametro: _diametro,
      longitudComercialM: longitudComercial,
      longitudTraslapeM: traslapeManual,
    );

    setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acero de refuerzo')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Text('Diámetro de la varilla', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppConstants.paddingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DiametroVarilla.values.map((d) {
              return ChoiceChip(
                label: Text(d.etiqueta),
                selected: _diametro == d,
                onSelected: (_) => setState(() {
                  _diametro = d;
                  _resultado = null;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          TextFormField(
            controller: _longitudComercialController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Longitud de la varilla comercial',
              suffixText: 'm',
              helperText: 'La varilla completa que compras (usualmente 9 m)',
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          TextFormField(
            controller: _traslapeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Longitud de traslape (opcional)',
              suffixText: 'm',
              helperText:
                  'Si lo dejas vacío, se usa la regla práctica de 40 diámetros: '
                  '${_diametro.traslapeSugeridoM.toStringAsFixed(2)} m para ${_diametro.etiqueta}',
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text('Piezas que necesitas cortar', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Agrega cada medida distinta que necesitas — así se calcula el corte real y el desperdicio, no solo un total lineal.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: AppConstants.paddingSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _longitudPiezaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Longitud (m)'),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cantidadPiezaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSm),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton.filled(
                  onPressed: _agregarTramo,
                  icon: const Icon(Icons.add),
                  tooltip: 'Agregar pieza',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSm),
          ..._tramos.asMap().entries.map((entry) {
            final index = entry.key;
            final tramo = entry.value;
            return Card(
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.straighten, size: 20),
                title: Text('${tramo.cantidad} × ${tramo.longitudM.toStringAsFixed(2)} m'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _quitarTramo(index),
                ),
              ),
            );
          }),
          const SizedBox(height: AppConstants.paddingLg),
          FilledButton.icon(
            onPressed: _tramos.isEmpty ? null : _calcular,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular acero'),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppConstants.paddingLg),
            _TarjetaResultadoAcero(resultado: _resultado!, diametro: _diametro, tramos: _tramos),
          ],
        ],
      ),
    );
  }
}

class _TarjetaResultadoAcero extends StatelessWidget {
  final ResultadoCorteAcero resultado;
  final DiametroVarilla diametro;
  final List<TramoRequerido> tramos;

  const _TarjetaResultadoAcero({
    required this.resultado,
    required this.diametro,
    required this.tramos,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Varilla ${diametro.etiqueta}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.paddingMd),
            _FilaResultado(
              icono: Icons.format_list_numbered,
              etiqueta: 'Varillas comerciales (${resultado.longitudComercialM.toStringAsFixed(1)} m c/u)',
              valor: '${resultado.varillasComercialesNecesarias}',
            ),
            if (resultado.traslapesNecesarios > 0)
              _FilaResultado(
                icono: Icons.link,
                etiqueta: 'Traslapes (empalmes de ${resultado.longitudTraslapeM.toStringAsFixed(2)} m c/u)',
                valor: '${resultado.traslapesNecesarios}',
              ),
            _FilaResultado(
              icono: Icons.check_circle_outline,
              etiqueta: 'Longitud útil (lo que realmente usas)',
              valor: '${resultado.longitudUtilTotalM.toStringAsFixed(2)} m',
            ),
            _FilaResultado(
              icono: Icons.content_cut,
              etiqueta: 'Desperdicio de corte',
              valor: '${resultado.desperdicioTotalM.toStringAsFixed(2)} m',
            ),
            _FilaResultado(
              icono: Icons.scale_outlined,
              etiqueta: 'Peso a comprar',
              valor: '${resultado.pesoCompradoKg.toStringAsFixed(2)} kg',
            ),
            const SizedBox(height: AppConstants.paddingMd),
            OutlinedButton.icon(
              onPressed: () => exportarResultadosPdf(
                titulo: 'Acero de refuerzo',
                subtitulo: 'Varilla ${diametro.etiqueta}',
                filas: [
                  ...tramos.map((t) => FilaPdf(
                      'Pieza requerida', '${t.cantidad} × ${t.longitudM.toStringAsFixed(2)} m')),
                  FilaPdf('Varillas comerciales a comprar',
                      '${resultado.varillasComercialesNecesarias} (${resultado.longitudComercialM.toStringAsFixed(1)} m c/u)'),
                  if (resultado.traslapesNecesarios > 0)
                    FilaPdf('Traslapes necesarios',
                        '${resultado.traslapesNecesarios} × ${resultado.longitudTraslapeM.toStringAsFixed(2)} m'),
                  FilaPdf('Longitud útil (diseño)', '${resultado.longitudUtilTotalM.toStringAsFixed(2)} m'),
                  FilaPdf('Desperdicio de corte', '${resultado.desperdicioTotalM.toStringAsFixed(2)} m'),
                  FilaPdf('Peso a comprar', '${resultado.pesoCompradoKg.toStringAsFixed(2)} kg'),
                ],
                nota:
                    'Cálculo de corte optimizado sobre las piezas indicadas, incluyendo traslapes cuando '
                    'un tramo supera la longitud comercial. No incluye ganchos ni desperdicio adicional '
                    'por manejo — agrégalos según tu criterio o el del ingeniero a cargo.',
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar / imprimir como PDF'),
            ),
            const SizedBox(height: AppConstants.paddingSm),
            Text(
              'Incluye traslapes cuando un tramo supera la varilla comercial. No incluye ganchos — agrégalos según el diseño estructural.',
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

  const _FilaResultado({required this.icono, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: AppConstants.paddingSm),
          Expanded(child: Text(etiqueta)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
