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
  static const double largoComercialAnguloM = 3.00;
  static const double largoComercialViguetaM = 3.66;
  static const double espaciadoOmegaNormalM = 0.50;
  static const double espaciadoOmegaCalienteM = 0.40;
  // Las viguetas (soporte principal) van perpendiculares a las omegas,
  // con una separación típica mayor — referencia de campo.
  static const double espaciadoViguetaM = 1.20;
  static const double espaciadoTornillosCornisaM = 0.61;
  static const double espaciadoTornillosOmegaM = 0.50;
  // Fijación del ángulo perimetral a la pared (tarugo + tornillo/puntilla).
  static const double espaciadoFijacionAnguloM = 0.40;
  // Puntos de amarre omega-vigueta.
  static const double espaciadoAmarreOmegaViguetaM = 0.60;
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
  // Ángulo perimetral: perfil "L" que sostiene los bordes contra la pared.
  final int anguloUnidades;
  // Viguetas metálicas: soportan el peso principal y a las omegas.
  final double metrosVigueta;
  final int viguetaUnidades;
  final int tornillosTablillas;
  final int tornillosOmega;
  final int tornillosCornisa;
  // Fijaciones del ángulo perimetral a la pared (tarugo + tornillo/puntilla).
  final int fijacionesAngulo;
  // Amarres/tornillos donde la omega se sujeta a la vigueta.
  final int amarresOmegaVigueta;
  final List<DetalleAmbienteCieloPvc> detallesPorAmbiente;

  const ResultadoCieloPvc({
    required this.areaTotalM2,
    required this.tablillasNecesarias,
    required this.unionesH,
    required this.perimetroTotalM,
    required this.cornisaUnidades,
    required this.metrosOmega,
    required this.espaciadoOmegaM,
    required this.anguloUnidades,
    required this.metrosVigueta,
    required this.viguetaUnidades,
    required this.tornillosTablillas,
    required this.tornillosOmega,
    required this.tornillosCornisa,
    required this.fijacionesAngulo,
    required this.amarresOmegaVigueta,
    required this.detallesPorAmbiente,
  });

  int get tornillosTotal =>
      tornillosTablillas + tornillosOmega + tornillosCornisa + fijacionesAngulo + amarresOmegaVigueta;
}

/// Calcula tablillas, cornisa, ángulo perimetral, furring channel (omega),
/// viguetas metálicas y tornillos/fijaciones para cielo falso de PVC, a
/// partir del área en planta de cada ambiente. Sugiere en qué dirección
/// conviene correr las tablillas para evitar o minimizar las uniones H.
/// Estimación de campo — las medidas reales del producto y la estructura
/// de colgado deben confirmarse con el instalador y el proveedor.
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
    var metrosViguetaTotal = 0.0;
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
      // Las viguetas corren perpendiculares a las omegas, cubriendo la
      // misma área en la dirección larga del ambiente.
      final numViguetas = (direccionAncho / ConstantesCieloPvc.espaciadoViguetaM).ceil() + 1;
      final metrosViguetaUnidad = numViguetas * direccionTablilla;

      tablillasGeometricas += tablillasUnidad * a.cantidad;
      uniones += unionesUnidad * a.cantidad;
      metrosOmegaTotal += metrosOmegaUnidad * a.cantidad;
      metrosViguetaTotal += metrosViguetaUnidad * a.cantidad;
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
    final anguloUnidades = perimetroTotal > 0
        ? (perimetroConDesperdicio / ConstantesCieloPvc.largoComercialAnguloM).ceil()
        : 0;

    final metrosOmegaConDesperdicio = metrosOmegaTotal * (1 + porcentajeDesperdicio / 100);
    final metrosViguetaConDesperdicio = metrosViguetaTotal * (1 + porcentajeDesperdicio / 100);
    final viguetaUnidades = metrosViguetaConDesperdicio > 0
        ? (metrosViguetaConDesperdicio / ConstantesCieloPvc.largoComercialViguetaM).ceil()
        : 0;

    final tornillosOmega = metrosOmegaConDesperdicio > 0
        ? (metrosOmegaConDesperdicio / ConstantesCieloPvc.espaciadoTornillosOmegaM).ceil()
        : 0;
    final tornillosCornisa = perimetroConDesperdicio > 0
        ? (perimetroConDesperdicio / ConstantesCieloPvc.espaciadoTornillosCornisaM).ceil()
        : 0;
    final fijacionesAngulo = perimetroConDesperdicio > 0
        ? (perimetroConDesperdicio / ConstantesCieloPvc.espaciadoFijacionAnguloM).ceil()
        : 0;
    final amarresOmegaVigueta = metrosOmegaConDesperdicio > 0
        ? (metrosOmegaConDesperdicio / ConstantesCieloPvc.espaciadoAmarreOmegaViguetaM).ceil()
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
      anguloUnidades: anguloUnidades,
      metrosVigueta: metrosViguetaConDesperdicio,
      viguetaUnidades: viguetaUnidades,
      tornillosTablillas: tornillosTablillasTotal,
      tornillosOmega: tornillosOmega,
      tornillosCornisa: tornillosCornisa,
      fijacionesAngulo: fijacionesAngulo,
      amarresOmegaVigueta: amarresOmegaVigueta,
      detallesPorAmbiente: detalles,
    );
  }
}
