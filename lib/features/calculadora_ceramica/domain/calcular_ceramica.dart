import 'package:flutter/foundation.dart';

/// Medida de la pieza (cerámica de baño o porcelanato), en centímetros.
class TamanoPieza {
  final String etiqueta;
  final double anchoCm;
  final double altoCm;

  const TamanoPieza({
    required this.etiqueta,
    required this.anchoCm,
    required this.altoCm,
  });

  static const List<TamanoPieza> presets = [
    TamanoPieza(etiqueta: '20 x 20 cm', anchoCm: 20, altoCm: 20),
    TamanoPieza(etiqueta: '30 x 30 cm', anchoCm: 30, altoCm: 30),
    TamanoPieza(etiqueta: '33 x 33 cm', anchoCm: 33, altoCm: 33),
    TamanoPieza(etiqueta: '40 x 40 cm', anchoCm: 40, altoCm: 40),
    TamanoPieza(etiqueta: '45 x 45 cm', anchoCm: 45, altoCm: 45),
    TamanoPieza(etiqueta: '60 x 60 cm (porcelanato)', anchoCm: 60, altoCm: 60),
    TamanoPieza(etiqueta: '80 x 80 cm (porcelanato)', anchoCm: 80, altoCm: 80),
  ];
}

/// Rendimiento de la pega cerámica/porcelanato (sacos de 20 kg), en
/// capa delgada, según el tamaño de la pieza: a mayor pieza se usa un
/// peine/llana más grande y la capa es más gruesa, así que rinde menos
/// por m². Cifras de campo tomadas de fichas técnicas de pega
/// cerámica/porcelanato (p. ej. Perdura, Weber): piezas chicas ~3.5-4
/// kg/m², medianas ~4-5 kg/m², grandes/porcelanato ~5-7 kg/m². Se usa
/// el punto medio de cada rango.
class RendimientoPega {
  final double kgPorM2;
  const RendimientoPega(this.kgPorM2);

  static const double sacoKg = 20;

  double get m2PorSaco => sacoKg / kgPorM2;

  static RendimientoPega paraPieza(TamanoPieza pieza) {
    final lado = pieza.anchoCm > pieza.altoCm ? pieza.anchoCm : pieza.altoCm;
    if (lado <= 20) return const RendimientoPega(3.75); // ≈5.3 m²/saco
    if (lado <= 45) return const RendimientoPega(4.5); // ≈4.4 m²/saco
    return const RendimientoPega(6.0); // ≈3.3 m²/saco (porcelanato grande)
  }
}

/// Un tramo de superficie (piso o pared) a enchapar.
class Superficie {
  final String id;
  final String etiqueta;
  final double largoM;
  final double anchoM;

  const Superficie({
    required this.id,
    required this.etiqueta,
    required this.largoM,
    required this.anchoM,
  });

  double get areaM2 => largoM * anchoM;
}

@immutable
class ResultadoCeramica {
  final double areaNetaM2;
  final double areaConDesperdicioM2;
  final double piezasNetas;
  final int piezasTotalComprar;
  final double kgPegaTotal;
  final int sacosPega;
  final double rendimientoM2PorSaco;

  const ResultadoCeramica({
    required this.areaNetaM2,
    required this.areaConDesperdicioM2,
    required this.piezasNetas,
    required this.piezasTotalComprar,
    required this.kgPegaTotal,
    required this.sacosPega,
    required this.rendimientoM2PorSaco,
  });
}

/// Calcula piezas de cerámica/porcelanato y pega necesaria para un
/// conjunto de superficies. Estimación de campo — no sustituye el
/// criterio del maestro de obra ni la ficha técnica del fabricante.
class CalcularCeramica {
  ResultadoCeramica call({
    required List<Superficie> superficies,
    required TamanoPieza pieza,
    required double porcentajeDesperdicio,
  }) {
    final areaNeta = superficies.fold(0.0, (s, x) => s + x.areaM2);
    final factor = 1 + (porcentajeDesperdicio / 100);
    final areaConDesperdicio = areaNeta * factor;

    final areaPiezaM2 = (pieza.anchoCm / 100) * (pieza.altoCm / 100);
    final piezasNetas = areaPiezaM2 > 0 ? areaNeta / areaPiezaM2 : 0;
    final piezasTotalComprar =
        areaPiezaM2 > 0 ? (areaConDesperdicio / areaPiezaM2).ceil() : 0;

    final rendimiento = RendimientoPega.paraPieza(pieza);
    final kgPegaTotal = areaConDesperdicio * rendimiento.kgPorM2;
    final sacosPega = (kgPegaTotal / RendimientoPega.sacoKg).ceil();

    return ResultadoCeramica(
      areaNetaM2: areaNeta,
      areaConDesperdicioM2: areaConDesperdicio,
      piezasNetas: piezasNetas,
      piezasTotalComprar: piezasTotalComprar,
      kgPegaTotal: kgPegaTotal,
      sacosPega: sacosPega,
      rendimientoM2PorSaco: rendimiento.m2PorSaco,
    );
  }
}
