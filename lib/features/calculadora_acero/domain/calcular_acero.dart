/// Diámetros comerciales de varilla corrugada (grado 40/60, la más
/// común en obra), su peso nominal en kg/m y su diámetro real en mm
/// (para calcular la longitud de traslape).
///
/// Tabla estándar de la industria (equivalente a ASTM A615): el
/// "número de varilla" es el diámetro en octavos de pulgada — por
/// eso la numeración salta del N°6 (3/4") al N°8 (1"), no existe un
/// N°7 comercial estándar.
enum DiametroVarilla {
  n3('3/8" (N°3)', 0.560, 9.5),
  n4('1/2" (N°4)', 0.994, 12.7),
  n5('5/8" (N°5)', 1.552, 15.9),
  n6('3/4" (N°6)', 2.235, 19.1),
  n8('1" (N°8)', 3.973, 25.4),
  n10('1 1/4" (N°10)', 6.225, 31.8),
  n12('1 1/2" (N°12)', 8.938, 38.1);

  final String etiqueta;
  final double kgPorMetro;
  final double diametroMm;
  const DiametroVarilla(this.etiqueta, this.kgPorMetro, this.diametroMm);

  /// Longitud de traslape sugerida (m), usando la regla práctica de
  /// campo de 40 diámetros para empalmes en tensión con acero grado
  /// 60 y concreto de f'c ≥ 210 kg/cm² (ACI 318, ref. 4.3.1.14).
  /// Es un valor de referencia: la longitud definitiva de empalme
  /// depende del elemento, la ubicación del traslape y el diseño
  /// estructural — confírmala con el ingeniero a cargo.
  double get traslapeSugeridoM => (diametroMm / 1000) * 40;
}

/// Un tramo de acero que se necesita cubrir de forma continua: una
/// longitud, repetida [cantidad] de veces (ej: "8 piezas de 2.40 m").
/// Si [longitudM] es mayor que la varilla comercial, se dividirá
/// automáticamente en varios segmentos empalmados con traslape.
class TramoRequerido {
  final double longitudM;
  final int cantidad;

  const TramoRequerido({required this.longitudM, required this.cantidad});
}

class ResultadoCorteAcero {
  final double longitudComercialM;
  final int varillasComercialesNecesarias;
  final double longitudUtilTotalM;
  final double desperdicioTotalM;
  final double pesoUtilKg;
  final double pesoCompradoKg;
  final int traslapesNecesarios;
  final double longitudTraslapeM;

  const ResultadoCorteAcero({
    required this.longitudComercialM,
    required this.varillasComercialesNecesarias,
    required this.longitudUtilTotalM,
    required this.desperdicioTotalM,
    required this.pesoUtilKg,
    required this.pesoCompradoKg,
    required this.traslapesNecesarios,
    required this.longitudTraslapeM,
  });
}

/// Calcula cuántas varillas comerciales hay que comprar para cubrir
/// una lista de tramos requeridos.
///
/// Dos reglas clave, según cómo se trabaja realmente en obra:
///
/// 1. Si un tramo es más largo que la varilla comercial, se divide en
///    segmentos empalmados: cada unión consume una longitud extra de
///    traslape (el acero ahí queda doblado, no es "desperdicio" pero
///    sí material adicional que hay que comprar).
/// 2. Los retazos que sobran de cortar cualquier pieza (incluyendo
///    los segmentos de un traslape) quedan disponibles para cubrir
///    OTRAS piezas de la lista — solo se cuenta como desperdicio real
///    lo que, al final, no alcanzó para ninguna pieza pendiente.
class CalcularAcero {
  ResultadoCorteAcero call({
    required List<TramoRequerido> tramos,
    required DiametroVarilla diametro,
    double longitudComercialM = 9.0,
    double? longitudTraslapeM,
  }) {
    final traslape = longitudTraslapeM ?? diametro.traslapeSugeridoM;

    // 1) Expande cada tramo en las piezas físicas que hay que cortar,
    //    dividiendo con traslape los que no caben en una sola varilla.
    final piezas = <double>[];
    var traslapesNecesarios = 0;

    for (final tramo in tramos) {
      for (var i = 0; i < tramo.cantidad; i++) {
        var restante = tramo.longitudM;
        var esPrimerSegmento = true;

        while (restante > 0) {
          if (esPrimerSegmento) {
            if (restante <= longitudComercialM) {
              piezas.add(restante);
              restante = 0;
            } else {
              piezas.add(longitudComercialM);
              restante -= longitudComercialM;
              esPrimerSegmento = false;
            }
          } else {
            final coberturaPorSegmento = longitudComercialM - traslape;
            if (restante <= coberturaPorSegmento) {
              // Último segmento: cubre lo que falta + su traslape con el anterior.
              piezas.add(restante + traslape);
              traslapesNecesarios++;
              restante = 0;
            } else {
              piezas.add(longitudComercialM);
              restante -= coberturaPorSegmento;
              traslapesNecesarios++;
            }
          }
        }
      }
    }

    // 2) Empaqueta todas las piezas (incluyendo las de los traslapes)
    //    en la menor cantidad de varillas comerciales posible,
    //    reutilizando retazos entre piezas distintas.
    piezas.sort((a, b) => b.compareTo(a));
    final espacioRestantePorVarilla = <double>[];

    for (final pieza in piezas) {
      int? mejorIndice;
      double mejorEspacio = double.infinity;
      for (var i = 0; i < espacioRestantePorVarilla.length; i++) {
        final espacio = espacioRestantePorVarilla[i];
        if (espacio >= pieza && espacio < mejorEspacio) {
          mejorEspacio = espacio;
          mejorIndice = i;
        }
      }

      if (mejorIndice != null) {
        espacioRestantePorVarilla[mejorIndice] -= pieza;
      } else {
        espacioRestantePorVarilla.add(longitudComercialM - pieza);
      }
    }

    final longitudUtilTotal = tramos.fold(
      0.0,
      (suma, t) => suma + t.longitudM * t.cantidad,
    );
    final varillasNecesarias = espacioRestantePorVarilla.length;
    final desperdicioTotal = espacioRestantePorVarilla.fold(0.0, (suma, e) => suma + e);
    final pesoComprado = varillasNecesarias * longitudComercialM * diametro.kgPorMetro;
    final pesoUtil = longitudUtilTotal * diametro.kgPorMetro;

    return ResultadoCorteAcero(
      longitudComercialM: longitudComercialM,
      varillasComercialesNecesarias: varillasNecesarias,
      longitudUtilTotalM: longitudUtilTotal,
      desperdicioTotalM: desperdicioTotal,
      pesoUtilKg: pesoUtil,
      pesoCompradoKg: pesoComprado,
      traslapesNecesarios: traslapesNecesarios,
      longitudTraslapeM: traslape,
    );
  }
}
