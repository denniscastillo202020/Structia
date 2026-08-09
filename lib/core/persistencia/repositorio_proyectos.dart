import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:structia/core/persistencia/proyecto.dart';

/// Administra los proyectos y cuál está "activo" en este momento —
/// el que se le asigna automáticamente a cada cálculo nuevo que se
/// guarde desde cualquier calculadora, sin que el usuario tenga que
/// elegirlo cada vez.
class RepositorioProyectos {
  static const _claveProyectos = 'structia_proyectos';
  static const _claveActivo = 'structia_proyecto_activo';

  static Future<List<Proyecto>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString(_claveProyectos);
    if (crudo == null || crudo.isEmpty) return [];

    final lista = jsonDecode(crudo) as List;
    final proyectos =
        lista.map((p) => Proyecto.fromJson(p as Map<String, dynamic>)).toList();
    proyectos.sort((a, b) => b.fecha.compareTo(a.fecha));
    return proyectos;
  }

  /// Crea el proyecto y lo deja como activo de inmediato.
  static Future<Proyecto> crear(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    final actuales = await listar();
    final nuevo = Proyecto(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nombre: nombre,
      fecha: DateTime.now(),
    );
    actuales.insert(0, nuevo);
    await prefs.setString(
        _claveProyectos, jsonEncode(actuales.map((p) => p.toJson()).toList()));
    await establecerActivo(nuevo.id);
    return nuevo;
  }

  static Future<void> renombrar(String id, String nuevoNombre) async {
    final prefs = await SharedPreferences.getInstance();
    final actuales = await listar();
    final index = actuales.indexWhere((p) => p.id == id);
    if (index == -1) return;
    actuales[index] =
        Proyecto(id: id, nombre: nuevoNombre, fecha: actuales[index].fecha);
    await prefs.setString(
        _claveProyectos, jsonEncode(actuales.map((p) => p.toJson()).toList()));
  }

  /// Elimina el proyecto (NO borra los cálculos ya guardados con ese
  /// proyectoId — esos quedan intactos, solo pierden la etiqueta y
  /// pasan a mostrarse como "Sin proyecto asignado").
  static Future<void> eliminar(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final actuales = await listar();
    actuales.removeWhere((p) => p.id == id);
    await prefs.setString(
        _claveProyectos, jsonEncode(actuales.map((p) => p.toJson()).toList()));
    if (await idActivo() == id) {
      await prefs.remove(_claveActivo);
    }
  }

  static Future<String?> idActivo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveActivo);
  }

  /// Pasa `null` para dejar la app "sin proyecto activo" (los cálculos
  /// que se guarden así quedarán sueltos, como antes de este cambio).
  static Future<void> establecerActivo(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_claveActivo);
    } else {
      await prefs.setString(_claveActivo, id);
    }
  }

  static Future<Proyecto?> activo() async {
    final id = await idActivo();
    if (id == null) return null;
    final proyectos = await listar();
    for (final p in proyectos) {
      if (p.id == id) return p;
    }
    return null;
  }
}
