import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:structia/core/persistencia/calculo_guardado.dart';
import 'package:structia/core/persistencia/repositorio_proyectos.dart';

/// Guarda los cálculos del usuario en el almacenamiento local del
/// dispositivo (no en la nube — vive solo en este celular). Se usa
/// para ir armando el listado de materiales de todo un proyecto:
/// columna por columna, viga por viga, zapata por zapata.
class RepositorioCalculosGuardados {
  static const _clave = 'structia_calculos_guardados';

  static Future<List<CalculoGuardado>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString(_clave);
    if (crudo == null || crudo.isEmpty) return [];

    final lista = jsonDecode(crudo) as List;
    final calculos = lista
        .map((item) => CalculoGuardado.fromJson(item as Map<String, dynamic>))
        .toList();
    calculos.sort((a, b) => b.fecha.compareTo(a.fecha));
    return calculos;
  }

  /// Si el cálculo no trae ya un proyecto asignado, se etiqueta solo
  /// con el proyecto activo en este momento (si hay uno). Así ninguna
  /// calculadora individual necesita saber nada de proyectos — el
  /// enlace vive aquí, en un solo lugar.
  static Future<void> guardar(CalculoGuardado calculo) async {
    final prefs = await SharedPreferences.getInstance();
    final actuales = await listar();

    var aGuardar = calculo;
    if (aGuardar.proyectoId == null) {
      final activoId = await RepositorioProyectos.idActivo();
      if (activoId != null) {
        aGuardar = aGuardar.conProyecto(activoId);
      }
    }

    actuales.add(aGuardar);
    await prefs.setString(_clave, jsonEncode(actuales.map((c) => c.toJson()).toList()));
  }

  static Future<void> eliminar(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final actuales = await listar();
    actuales.removeWhere((c) => c.id == id);
    await prefs.setString(_clave, jsonEncode(actuales.map((c) => c.toJson()).toList()));
  }

  static Future<void> eliminarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }
}
