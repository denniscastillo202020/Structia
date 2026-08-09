import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/persistencia/proyecto.dart';
import 'package:structia/core/persistencia/repositorio_proyectos.dart';

/// Elegir/crear el proyecto activo. Todo lo que se guarde desde
/// cualquier calculadora mientras un proyecto esté activo se etiqueta
/// solo con ese proyecto, sin que el usuario tenga que hacer nada más.
class ProyectosScreen extends StatefulWidget {
  const ProyectosScreen({super.key});

  @override
  State<ProyectosScreen> createState() => _ProyectosScreenState();
}

class _ProyectosScreenState extends State<ProyectosScreen> {
  late Future<List<Proyecto>> _futuroProyectos;
  String? _idActivo;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _futuroProyectos = RepositorioProyectos.listar();
    RepositorioProyectos.idActivo().then((id) {
      if (mounted) setState(() => _idActivo = id);
    });
  }

  Future<void> _crearProyecto() async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo proyecto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Proyecto de Carol, Casa Marvin 2do piso',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Crear y activar'),
          ),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty) return;
    await RepositorioProyectos.crear(nombre);
    setState(_recargar);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$nombre" creado y activado')),
      );
    }
  }

  Future<void> _activar(String? id) async {
    await RepositorioProyectos.establecerActivo(id);
    setState(_recargar);
  }

  Future<void> _eliminar(Proyecto proyecto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar proyecto?'),
        content: Text(
          '"${proyecto.nombre}" se eliminará. Los cálculos que ya guardaste ahí NO se '
          'borran — quedarán como "Sin proyecto asignado" en Mis cálculos guardados.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await RepositorioProyectos.eliminar(proyecto.id);
    setState(_recargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis proyectos')),
      body: FutureBuilder<List<Proyecto>>(
        future: _futuroProyectos,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final proyectos = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            children: [
              Text(
                'El proyecto activo es donde se guarda todo lo que calcules. '
                'Toca uno para activarlo, o crea uno nuevo.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: AppConstants.paddingMd),
              FilledButton.icon(
                onPressed: _crearProyecto,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo proyecto'),
              ),
              const SizedBox(height: AppConstants.paddingMd),
              if (proyectos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingLg),
                  child: Center(
                    child: Text(
                      'Aún no tienes proyectos creados',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                ),
              ...proyectos.map((p) {
                final esActivo = p.id == _idActivo;
                return Card(
                  color: esActivo
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                      : null,
                  child: ListTile(
                    leading: Icon(
                      esActivo ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: esActivo ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(esActivo ? 'Activo — se está guardando aquí' : 'Toca para activar'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _eliminar(p),
                    ),
                    onTap: () => _activar(p.id),
                  ),
                );
              }),
              if (_idActivo != null) ...[
                const SizedBox(height: AppConstants.paddingMd),
                OutlinedButton.icon(
                  onPressed: () => _activar(null),
                  icon: const Icon(Icons.block),
                  label: const Text('Desactivar (guardar sin proyecto)'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
