import 'package:flutter/foundation.dart';

/// Un ambiente (cuarto, sala, pasillo, etc.) al que se le pondrá
/// cielo falso de PVC. Solo se usan largo y ancho (área en planta) —
/// igual que en la calculadora de firme, no se necesita el espesor.
class AmbienteCieloPvc {
  final String id;
  final String etiqueta;
  final double largoM;
  final double anchoM;
  final int cantidad;

  const AmbienteCieloPvc({
    required this.id,
    required this.etiqueta,
    required this.largoM,
    required this.anchoM,
    this.cantidad = 1,
  });

  double get areaM2 => largoM * anchoM * cantidad;
  double get perimetroM => 2 * (largoM + anchoM) * cantidad;
  double get ladoMenorM => largoM < anchoM ? largoM : anchoM;
  double get ladoMayorM => largoM > anchoM ? largoM : anchoM;
}

/// Constantes comerciales típicas de tablilla/cornisa PVC (referencia
/// Plycem y otras marcas centroamericanas). Pueden variar según el
/// proveedor — confirma las medidas exactas del producto que vas a comprar.
class ConstantesCieloPvc {
  static const double largoComercialTablillaM = 5.95;
  static const double anchoUtilTablillaM = 0.20;
  static const double largoComercialCornisaM = 5.95;
  static const double espaciadoOmegaNormalM = 0.50;
  static const double espaciadoOmegaCalienteM = 0.40;
  static const double espaciadoTornillosCornisaM = 0.61;
  static const double espaciadoTornillosOmegaM = 0.50;
}

@immutable
class DetalleAmbienteCieloPvc {
  final String etiqueta;
  final bool requiereUnionH;
  final String orientacionSugerida;

  const DetalleAmbienteCieloPvc({
    required this.etiqueta,
    required this.requiereUnionH,
    required this.orientacionSugerida,
  });
}

@immutable
class ResultadoCieloPvc {
  final double areaTotalM2;
  final int tablillasNecesarias;
  final int unionesH;
  final double perimetroTotalM;
  final int cornisaUnidades;
  final double metrosOmega;
  final double espaciadoOmegaM;
  final int tornillosTablillas;
  final int tornillosOmega;
  final int tornillosCornisa;
  final List<DetalleAmbienteCieloPvc> detallesPorAmbiente;

  const ResultadoCieloPvc({
    required this.areaTotalM2,
    required this.tablillasNecesarias,
    required this.unionesH,
    required this.perimetroTotalM,
    required this.cornisaUnidades,
    required this.metrosOmega,
    required this.espaciadoOmegaM,
    required this.tornillosTablillas,
    required this.tornillosOmega,
    required this.tornillosCornisa,
    required this.detallesPorAmbiente,
  });

  int get tornillosTotal => tornillosTablillas + tornillosOmega + tornillosCornisa;
}

/// Calcula tablillas, cornisa, furring channel (omega) y tornillos
/// para cielo falso de PVC, a partir del área en planta de cada
/// ambiente. Sugiere en qué dirección conviene correr las tablillas
/// para evitar o minimizar las uniones H. Estimación de campo — las
/// medidas reales del producto y la estructura de colgado deben
/// confirmarse con el instalador y el proveedor.
class CalcularCieloPvc {
  ResultadoCieloPvc call({
    required List<AmbienteCieloPvc> ambientes,
    required double porcentajeDesperdicio,
    required bool climaCaliente,
  }) {
    final espaciadoOmega = climaCaliente
        ? ConstantesCieloPvc.espaciadoOmegaCalienteM
        : ConstantesCieloPvc.espaciadoOmegaNormalM;

    var tablillasGeometricas = 0;
    var uniones = 0;
    var metrosOmegaTotal = 0.0;
    var tornillosTablillasTotal = 0;
    final detalles = <DetalleAmbienteCieloPvc>[];

    for (final a in ambientes) {
      if (a.largoM <= 0 || a.anchoM <= 0) continue;

      final ladoMenor = a.ladoMenorM;
      final ladoMayor = a.ladoMayorM;
      final tablillaCabeMenor = ladoMenor <= ConstantesCieloPvc.largoComercialTablillaM;
      final tablillaCabeMayor = ladoMayor <= ConstantesCieloPvc.largoComercialTablillaM;

      // Dirección en la que corre el LARGO de la tablilla.
      // Si el lado mayor no cabe en una tablilla, orientamos por el
      // lado menor para evitar o minimizar uniones H.
      final direccionTablilla = tablillaCabeMayor ? ladoMayor : ladoMenor;
      final direccionAncho = tablillaCabeMayor ? ladoMenor : ladoMayor;

      final filasPorTablilla =
          (direccionTablilla / ConstantesCieloPvc.largoComercialTablillaM).ceil();
      final tablillasLadoAlado =
          (direccionAncho / ConstantesCieloPvc.anchoUtilTablillaM).ceil();

      final tablillasUnidad = filasPorTablilla * tablillasLadoAlado;
      final unionesUnidad = (filasPorTablilla - 1) * tablillasLadoAlado;

      final numOmegas = (direccionTablilla / espaciadoOmega).ceil() + 1;
      final metrosOmegaUnidad = numOmegas * direccionAncho;

      tablillasGeometricas += tablillasUnidad * a.cantidad;
      uniones += unionesUnidad * a.cantidad;
      metrosOmegaTotal += metrosOmegaUnidad * a.cantidad;
      tornillosTablillasTotal += tablillasUnidad * numOmegas * a.cantidad;

      final requiereUnionH = !tablillaCabeMenor;
      String orientacion;
      if (!tablillaCabeMayor && tablillaCabeMenor) {
        orientacion = 'Corré las tablillas a lo largo del lado corto '
            '(${ladoMenor.toStringAsFixed(2)} m) — así evitás uniones H.';
      } else if (tablillaCabeMayor) {
        orientacion = 'Ambos lados caben en una sola tablilla (máx. '
            '${ConstantesCieloPvc.largoComercialTablillaM.toStringAsFixed(2)} m). '
            'Para mejor vista, corré las tablillas a lo largo del lado más largo '
            '(${ladoMayor.toStringAsFixed(2)} m).';
      } else {
        orientacion = 'Los dos lados superan los '
            '${ConstantesCieloPvc.largoComercialTablillaM.toStringAsFixed(2)} m de la tablilla: '
            'vas a necesitar Unión H sí o sí. Orientá a lo largo del lado corto '
            '(${ladoMenor.toStringAsFixed(2)} m) para minimizar la cantidad de uniones.';
      }

      detalles.add(DetalleAmbienteCieloPvc(
        etiqueta: a.etiqueta,
        requiereUnionH: requiereUnionH,
        orientacionSugerida: orientacion,
      ));
    }

    final tablillasNecesarias =
        (tablillasGeometricas * (1 + porcentajeDesperdicio / 100)).ceil();

    final perimetroTotal = ambientes.fold(0.0, (s, a) => s + a.perimetroM);
    final perimetroConDesperdicio = perimetroTotal * (1 + porcentajeDesperdicio / 100);
    final cornisaUnidades = perimetroTotal > 0
        ? (perimetroConDesperdicio / ConstantesCieloPvc.largoComercialCornisaM).ceil()
        : 0;

    final metrosOmegaConDesperdicio = metrosOmegaTotal * (1 + porcentajeDesperdicio / 100);
    final tornillosOmega = metrosOmegaConDesperdicio > 0
        ? (metrosOmegaConDesperdicio / ConstantesCieloPvc.espaciadoTornillosOmegaM).ceil()
        : 0;
    final tornillosCornisa = perimetroConDesperdicio > 0
        ? (perimetroConDesperdicio / ConstantesCieloPvc.espaciadoTornillosCornisaM).ceil()
        : 0;

    final areaTotal = ambientes.fold(0.0, (s, a) => s + a.areaM2);

    return ResultadoCieloPvc(
      areaTotalM2: areaTotal,
      tablillasNecesarias: tablillasNecesarias,
      unionesH: uniones,
      perimetroTotalM: perimetroTotal,
      cornisaUnidades: cornisaUnidades,
      metrosOmega: metrosOmegaConDesperdicio,
      espaciadoOmegaM: espaciadoOmega,
      tornillosTablillas: tornillosTablillasTotal,
      tornillosOmega: tornillosOmega,
      tornillosCornisa: tornillosCornisa,
      detallesPorAmbiente: detalles,
    );
  }
}
