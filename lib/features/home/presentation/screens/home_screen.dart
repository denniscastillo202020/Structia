import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/features/calculadora_acero/presentation/screens/calculadora_acero_screen.dart';
import 'package:structia/features/calculadora_columna/presentation/screens/calculadora_columna_screen.dart';
import 'package:structia/features/calculadora_ceramica/presentation/screens/calculadora_ceramica_screen.dart';
import 'package:structia/features/calculadora_techo/presentation/screens/calculadora_techo_screen.dart';
import 'package:structia/features/calculadora_concreto/presentation/screens/calculadora_concreto_screen.dart';
import 'package:structia/features/calculadora_mamposteria/presentation/screens/calculadora_mamposteria_screen.dart';
import 'package:structia/features/calculadora_viga/presentation/screens/calculadora_viga_screen.dart';
import 'package:structia/features/calculadora_zapata/presentation/screens/calculadora_zapata_screen.dart';
import 'package:structia/features/calculadora_excavacion/presentation/screens/calculadora_excavacion_screen.dart';
import 'package:structia/features/calculadora_electrico/presentation/screens/calculadora_electrico_screen.dart';
import 'package:structia/features/calculadora_cielo_pvc/presentation/screens/calculadora_cielo_pvc_screen.dart';
import 'package:structia/features/guardados/presentation/screens/calculos_guardados_screen.dart';
import 'package:structia/features/presupuesto/presentation/screens/presupuesto_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.folder_special_outlined),
                tooltip: 'Mis cálculos guardados',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalculosGuardadosScreen()),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              title: Text(
                AppConstants.appName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -10,
                    child: Icon(
                      Icons.architecture,
                      size: 160,
                      color: colorScheme.onPrimary.withValues(alpha: 0.10),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Icon(
                      Icons.foundation,
                      size: 120,
                      color: colorScheme.onPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculadora de materiales de construcción',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elige qué quieres calcular',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: AppConstants.paddingMd),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _AccesoRapidoChip(
                          icono: Icons.folder_special_outlined,
                          label: 'Guardados',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CalculosGuardadosScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _AccesoRapidoChip(
                          icono: Icons.payments_outlined,
                          label: 'Presupuesto',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PresupuestoScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _AccesoRapidoChip(
                          icono: Icons.foundation_outlined,
                          label: 'Concreto',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CalculadoraConcretoScreen()),
                          ),
                        ),
                      ],
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
                    icono: Icons.terrain_outlined,
                    titulo: 'Excavación y relleno',
                    descripcion: 'Volumen a excavar y relleno según las dimensiones de tus zapatas',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalculadoraExcavacionScreen()),
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
                    icono: Icons.grid_on_outlined,
                    titulo: 'Cerámica y porcelanato',
                    descripcion: 'Piezas y pega según el tamaño, para baño, piso o pared',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalculadoraCeramicaScreen()),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMd),
                  _TarjetaCalculadora(
                    icono: Icons.roofing_outlined,
                    titulo: 'Techo',
                    descripcion: 'Láminas, canaleta, caballete y tornillos según los faldones',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalculadoraTechoScreen()),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMd),
                  _TarjetaCalculadora(
                    icono: Icons.electric_bolt_outlined,
                    titulo: 'Instalación eléctrica',
                    descripcion: 'Manguera, cable, cajas, tornillos y tablero según los puntos que agregues',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalculadoraElectricoScreen()),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMd),
                  _TarjetaCalculadora(
                    icono: Icons.blinds_outlined,
                    titulo: 'Cielo falso PVC',
                    descripcion: 'Tablillas, cornisa, furring channel y tornillos, con sugerencia de orientación',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalculadoraCieloPvcScreen()),
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
                  const SizedBox(height: AppConstants.paddingLg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccesoRapidoChip extends StatelessWidget {
  final IconData icono;
  final String label;
  final VoidCallback onTap;

  const _AccesoRapidoChip({
    required this.icono,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icono, size: 18, color: colorScheme.primary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.25)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMd),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, size: 28, color: colorScheme.primary),
              ),
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
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
