import 'package:flutter/foundation.dart';

/// Ancho útil de la lámina (después de traslape lateral), en metros.
/// El ancho útil "Aluzinc acanalada" (1.00 m) corresponde a la lámina
/// tipo R-101/estructural más común en ferreterías hondureñas
/// (ancho total ≈1.07 m, útil 1.00-1.01 m).
class TipoLamina {
  final String etiqueta;
  final double anchoUtilM;

  const TipoLamina({required this.etiqueta, required this.anchoUtilM});

  static const List<TipoLamina> presets = [
    TipoLamina(etiqueta: 'Aluzinc acanalada (ancho útil 1.00 m)', anchoUtilM: 1.00),
    TipoLamina(etiqueta: 'Ondulada clásica (ancho útil 0.605 m)', anchoUtilM: 0.605),
  ];
}

/// Un faldón (agua) del techo: ancho perpendicular a las láminas y
/// largo de bajada (la pendiente, en la dirección de la lámina).
class Faldon {
  final String id;
  final String etiqueta;
  final double anchoM;
  final double largoM;

  const Faldon({
    required this.id,
    required this.etiqueta,
    required this.anchoM,
    required this.largoM,
  });

  double get areaM2 => anchoM * largoM;
}

/// Consumo estimado de tornillos autorroscantes con arandela, en
/// unidades por m² de techo. Cifra de campo (empaques de 100/250
/// suelen anunciar cobertura de 15-35 m² según separación de apoyos).
const double tornillosPorM2 = 7.0;

@immutable
class ResultadoTecho {
  final double areaNetaM2;
  final double areaConDesperdicioM2;

  final int laminasNetas;
  final int laminasDesperdicio;
  final int laminasTotalComprar;
  final bool advertenciaLargo; // algún faldón es más largo que la lámina

  final double canaletaMetrosLineales;
  final int canaletaTramos;

  final double caballeteMetrosLineales;
  final int caballeteTramos;

  final int tornillosTotal;
  final int tornillosCajas;

  const ResultadoTecho({
    required this.areaNetaM2,
    required this.areaConDesperdicioM2,
    required this.laminasNetas,
    required this.laminasDesperdicio,
    required this.laminasTotalComprar,
    required this.advertenciaLargo,
    required this.canaletaMetrosLineales,
    required this.canaletaTramos,
    required this.caballeteMetrosLineales,
    required this.caballeteTramos,
    required this.tornillosTotal,
    required this.tornillosCajas,
  });
}

/// Calcula láminas, canaleta, caballete y tornillos para un techo.
/// Estimación de campo: asume que el largo de lámina ingresado cubre
/// de una sola pieza cada bajada de agua. Si un faldón es más largo
/// que la lámina, hay que sumar traslape longitudinal (usualmente
/// 20 cm) a mano — se marca con una advertencia.
class CalcularTecho {
  ResultadoTecho call({
    required List<Faldon> faldones,
    required TipoLamina tipoLamina,
    required double largoLaminaM,
    required double porcentajeDesperdicio,
    required double canaletaMetrosLineales,
    required double canaletaTramoM,
    required double caballeteMetrosLineales,
    required double caballeteTramoM,
    required int tornillosEmpaque,
  }) {
    final areaNeta = faldones.fold(0.0, (s, f) => s + f.areaM2);
    final factorDesperdicio = 1 + (porcentajeDesperdicio / 100);
    final areaConDesperdicio = areaNeta * factorDesperdicio;

    final laminasNetas = faldones.fold(
      0,
      (s, f) => s + (f.anchoM / tipoLamina.anchoUtilM).ceil(),
    );
    final laminasDesperdicio = (laminasNetas * (porcentajeDesperdicio / 100)).ceil();
    final advertenciaLargo = faldones.any((f) => f.largoM > largoLaminaM);

    final canaletaTramos =
        canaletaMetrosLineales > 0 ? (canaletaMetrosLineales / canaletaTramoM).ceil() : 0;
    final caballeteTramos =
        caballeteMetrosLineales > 0 ? (caballeteMetrosLineales / caballeteTramoM).ceil() : 0;

    final tornillosTotal = (areaConDesperdicio * tornillosPorM2).ceil();
    final tornillosCajas = (tornillosTotal / tornillosEmpaque).ceil();

    return ResultadoTecho(
      areaNetaM2: areaNeta,
      areaConDesperdicioM2: areaConDesperdicio,
      laminasNetas: laminasNetas,
      laminasDesperdicio: laminasDesperdicio,
      laminasTotalComprar: laminasNetas + laminasDesperdicio,
      advertenciaLargo: advertenciaLargo,
      canaletaMetrosLineales: canaletaMetrosLineales,
      canaletaTramos: canaletaTramos,
      caballeteMetrosLineales: caballeteMetrosLineales,
      caballeteTramos: caballeteTramos,
      tornillosTotal: tornillosTotal,
      tornillosCajas: tornillosCajas,
    );
  }
}
