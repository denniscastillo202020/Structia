import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/persistencia/proyecto.dart';
import 'package:structia/core/persistencia/repositorio_proyectos.dart';
import 'package:structia/features/calculadora_acero/presentation/screens/calculadora_acero_screen.dart';
import 'package:structia/features/calculadora_columna/presentation/screens/calculadora_columna_screen.dart';
import 'package:structia/features/calculadora_concreto/presentation/screens/calculadora_concreto_screen.dart';
import 'package:structia/features/calculadora_mamposteria/presentation/screens/calculadora_mamposteria_screen.dart';
import 'package:structia/features/calculadora_viga/presentation/screens/calculadora_viga_screen.dart';
import 'package:structia/features/calculadora_zapata/presentation/screens/calculadora_zapata_screen.dart';
import 'package:structia/features/guardados/presentation/screens/calculos_guardados_screen.dart';
import 'package:structia/features/importar_ocr/presentation/screens/importar_captura_screen.dart';
import 'package:structia/features/presupuesto/presentation/screens/presupuesto_screen.dart';
import 'package:structia/features/proyectos/presentation/screens/proyectos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Proyecto? _proyectoActivo;

  @override
  void initState() {
    super.initState();
    _cargarProyectoActivo();
  }

  Future<void> _cargarProyectoActivo() async {
    final activo = await RepositorioProyectos.activo();
    if (mounted) setState(() => _proyectoActivo = activo);
  }

  Future<void> _abrirProyectos() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProyectosScreen()),
    );
    _cargarProyectoActivo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_special_outlined),
            tooltip: 'Mis cálculos guardados',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculosGuardadosScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        children: [
          Card(
            color: _proyectoActivo != null
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                : null,
            child: ListTile(
              leading: Icon(
                Icons.folder_outlined,
                color: _proyectoActivo != null ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(
                _proyectoActivo != null ? _proyectoActivo!.nombre : 'Sin proyecto activo',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _proyectoActivo != null
                    ? 'Todo lo que calcules se guarda aquí'
                    : 'Toca para crear o elegir un proyecto',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _abrirProyectos,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          Text(
            'Calculadora de materiales de construcción',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppConstants.paddingSm),
          Text(
            'Elige qué quieres calcular',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          _TarjetaCalculadora(
            icono: Icons.foundation_outlined,
            titulo: 'Concreto y agregados',
            descripcion: 'Cemento (sacos de 42.5 kg), arena y grava según volumen y resistencia (f\'c)',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculadoraConcretoScreen()),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          _TarjetaCalculadora(
            icono: Icons.grid_4x4,
            titulo: 'Acero de refuerzo',
            descripcion: 'Peso, varillas comerciales y traslapes según diámetro',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculadoraAceroScreen()),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          _TarjetaCalculadora(
            icono: Icons.view_column_outlined,
            titulo: 'Columnas',
            descripcion: 'Concreto + acero longitudinal y estribos, con vista seccionada',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculadoraColumnaScreen()),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          _TarjetaCalculadora(
            icono: Icons.horizontal_rule,
            titulo: 'Vigas',
            descripcion: 'Concreto + acero superior, inferior y estribos, con vista seccionada',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculadoraVigaScreen()),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          _TarjetaCalculadora(
            icono: Icons.crop_din,
            titulo: 'Zapatas',
            descripcion: 'Corrida o aislada, con cama de varillas y vista en planta',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculadoraZapataScreen()),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          _TarjetaCalculadora(
            icono: Icons.grid_view_outlined,
            titulo: 'Muros y bloques',
            descripcion: 'Suma paredes, resta puertas/ventanas y calcula bloques y mortero, con el desperdicio aparte',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculadoraMamposteriaScreen()),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          _TarjetaCalculadora(
            icono: Icons.payments_outlined,
            titulo: 'Costos y mano de obra',
            descripcion: 'Honorarios de planificación y presupuesto de mano de obra por actividad',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PresupuestoScreen()),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMd),
          _TarjetaCalculadora(
            icono: Icons.document_scanner_outlined,
            titulo: 'Recuperar desde capturas',
            descripcion: 'Sube capturas de cotizaciones o cálculos anteriores y recréalos automáticamente',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportarCapturaScreen()),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLg),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalculosGuardadosScreen()),
            ),
            icon: const Icon(Icons.folder_special_outlined),
            label: const Text('Mis cálculos guardados'),
          ),
        ],
      ),
    );
  }
}

class _TarjetaCalculadora extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _TarjetaCalculadora({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          child: Row(
            children: [
              Icon(icono, size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppConstants.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(descripcion, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
