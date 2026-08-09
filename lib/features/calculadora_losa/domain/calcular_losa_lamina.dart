import 'package:flutter/foundation.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';

/// Tipo de tubo estructural usado como vigueta bajo la lámina.
enum TipoTubo { cuadrado4x4, rectangular4x2 }

extension TipoTuboInfo on TipoTubo {
  String get etiqueta {
    switch (this) {
      case TipoTubo.cuadrado4x4:
        return 'Tubo cuadrado 4" x 4"';
      case TipoTubo.rectangular4x2:
        return 'Tubo rectangular 4" x 2"';
    }
  }
}

/// Un ambiente (cuarto, corredor, terraza, etc.) al que se le pondrá
/// losa con estructura de tubo + lámina + malla electrosoldada +
/// concreto. Solo se usan largo y ancho — el espesor del concreto se
/// da por separado, ya que es el mismo para toda la losa.
class AmbienteLosa {
  final String id;
  final String etiqueta;
  final double largoM;
  final double anchoM;
  final int cantidad;

  const AmbienteLosa({
    required this.id,
    required this.etiqueta,
    required this.largoM,
    required this.anchoM,
    this.cantidad = 1,
  });

  double get areaM2 => largoM * anchoM * cantidad;
}

/// Constantes comerciales de referencia. Pueden variar según el
/// proveedor — confirma las medidas exactas antes de comprar.
class ConstantesLosa {
  static const double largoComercialTuboM = 6.0;
  static const double anchoUtilLaminaM = 0.90;
  static const double anchoHojaMallaM = 2.30;
  static const double largoHojaMallaM = 6.00;
  static const double espaciadoTornillosM = 0.30; // a lo largo de cada tubo
}

@immutable
class ResultadoLosa {
  final double areaTotalM2;
  final double volumenConcretoM3;

  final int tuboPiezas;
  final double tuboMetrosLineales;
  final TipoTubo tipoTubo;
  final double separacionTubosM;

  final int laminaPiezas;
  final double laminaMetrosLineales;

  final int mallaHojas;
  final int tornillos;

  final ResultadoMaterialesConcreto concreto;

  const ResultadoLosa({
    required this.areaTotalM2,
    required this.volumenConcretoM3,
    required this.tuboPiezas,
    required this.tuboMetrosLineales,
    required this.tipoTubo,
    required this.separacionTubosM,
    required this.laminaPiezas,
    required this.laminaMetrosLineales,
    required this.mallaHojas,
    required this.tornillos,
    required this.concreto,
  });
}

/// Calcula tubo (vigueta), lámina, malla electrosoldada, tornillos y
/// concreto para una losa con estructura de tubo + lámina troquelada
/// (aluzín) como cimbra permanente. Estimación de campo — el diseño
/// estructural real (calibre de tubo, calibre de lámina, separación
/// máxima según carga y claro) siempre debe confirmarlo un ingeniero.
class CalcularLosaLamina {
  ResultadoLosa call({
    required List<AmbienteLosa> ambientes,
    required double separacionTubosM,
    required double espesorConcretoM,
    required TipoTubo tipoTubo,
    required DosificacionConcreto dosificacion,
    required double porcentajeDesperdicio,
  }) {
    var metrosTubo = 0.0;
    var metrosLamina = 0.0;
    var tornillosTotal = 0;
    var areaTotal = 0.0;
    var volumenConcreto = 0.0;

    for (final a in ambientes) {
      if (a.largoM <= 0 || a.anchoM <= 0 || separacionTubosM <= 0) continue;

      final numTubos = (a.anchoM / separacionTubosM).ceil() + 1;
      final metrosTuboUnidad = numTubos * a.largoM;

      final numLaminas = (a.largoM / ConstantesLosa.anchoUtilLaminaM).ceil();
      final metrosLaminaUnidad = numLaminas * a.anchoM;

      final tornillosPorTubo = (a.largoM / ConstantesLosa.espaciadoTornillosM).ceil();
      final tornillosUnidad = numTubos * tornillosPorTubo;

      metrosTubo += metrosTuboUnidad * a.cantidad;
      metrosLamina += metrosLaminaUnidad * a.cantidad;
      tornillosTotal += tornillosUnidad * a.cantidad;
      areaTotal += a.areaM2;
      volumenConcreto += a.areaM2 * espesorConcretoM;
    }

    final metrosTuboConDesperdicio = metrosTubo * (1 + porcentajeDesperdicio / 100);
    final metrosLaminaConDesperdicio = metrosLamina * (1 + porcentajeDesperdicio / 100);
    final areaConDesperdicio = areaTotal * (1 + porcentajeDesperdicio / 100);

    final tuboPiezas = metrosTubo > 0
        ? (metrosTuboConDesperdicio / ConstantesLosa.largoComercialTuboM).ceil()
        : 0;

    final laminaPiezas =
        metrosLamina > 0 ? (metrosLaminaConDesperdicio / ConstantesLosa.largoComercialTuboM).ceil() : 0;

    final areaHojaMalla = ConstantesLosa.anchoHojaMallaM * ConstantesLosa.largoHojaMallaM;
    final mallaHojas = areaTotal > 0 ? (areaConDesperdicio / areaHojaMalla).ceil() : 0;

    final concreto = CalcularMaterialesConcreto()(
      volumenM3: volumenConcreto,
      dosificacion: dosificacion,
    );

    return ResultadoLosa(
      areaTotalM2: areaTotal,
      volumenConcretoM3: volumenConcreto,
      tuboPiezas: tuboPiezas,
      tuboMetrosLineales: metrosTuboConDesperdicio,
      tipoTubo: tipoTubo,
      separacionTubosM: separacionTubosM,
      laminaPiezas: laminaPiezas,
      laminaMetrosLineales: metrosLaminaConDesperdicio,
      mallaHojas: mallaHojas,
      tornillos: tornillosTotal,
      concreto: concreto,
    );
  }
}
