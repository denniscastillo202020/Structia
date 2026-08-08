import 'package:flutter/foundation.dart';

/// Tipo/tamaño de bloque de concreto, en centímetros.
/// [largoCm] x [altoCm] es la cara vista del bloque en el muro,
/// y [espesorCm] es la profundidad (el espesor del muro que deja
/// ese bloque).
class TipoBloque {
  final String etiqueta;
  final double largoCm;
  final double altoCm;
  final double espesorCm;

  const TipoBloque({
    required this.etiqueta,
    required this.largoCm,
    required this.altoCm,
    required this.espesorCm,
  });

  static const List<TipoBloque> presets = [
    TipoBloque(etiqueta: 'Bloque 40 x 20 x 10 cm (muro liviano / tabique)', largoCm: 40, altoCm: 20, espesorCm: 10),
    TipoBloque(etiqueta: 'Bloque 40 x 20 x 15 cm (muro estándar)', largoCm: 40, altoCm: 20, espesorCm: 15),
    TipoBloque(etiqueta: 'Bloque 40 x 20 x 20 cm (muro de carga)', largoCm: 40, altoCm: 20, espesorCm: 20),
    TipoBloque(etiqueta: 'Bloque 39 x 19 x 9 cm', largoCm: 39, altoCm: 19, espesorCm: 9),
  ];
}

/// Fila de la tabla práctica de dosificación de mortero de pega
/// (cemento : arena, en volumen). Rendimiento calibrado con datos de
/// campo reales de obra en Honduras. Igual que la tabla de concreto,
/// es una guía de campo — la proporción definitiva depende de la
/// arena disponible en la zona y no reemplaza el criterio del
/// maestro de obra.
class DosificacionMortero {
  final String proporcion; // Cemento : Arena, en volumen
  final double bolsasCementoPorM3;
  final double arenaM3PorM3;
  final String usoTypico;

  const DosificacionMortero({
    required this.proporcion,
    required this.bolsasCementoPorM3,
    required this.arenaM3PorM3,
    required this.usoTypico,
  });

  String get etiqueta => 'Mortero $proporcion';

  static const List<DosificacionMortero> tabla = [
    DosificacionMortero(
      proporcion: '1 : 3',
      bolsasCementoPorM3: 9.52,
      arenaM3PorM3: 0.98,
      usoTypico: 'Pega de mayor resistencia (muros de carga, zonas sísmicas)',
    ),
    DosificacionMortero(
      proporcion: '1 : 4',
      bolsasCementoPorM3: 7.41,
      arenaM3PorM3: 1.05,
      usoTypico: 'Pega de bloque estándar (uso general)',
    ),
    DosificacionMortero(
      proporcion: '1 : 5',
      bolsasCementoPorM3: 6.06,
      arenaM3PorM3: 1.10,
      usoTypico: 'Muros divisorios livianos, sin carga',
    ),
    DosificacionMortero(
      proporcion: '1 : 6',
      bolsasCementoPorM3: 5.13,
      arenaM3PorM3: 1.15,
      usoTypico: 'Repello y trabajos livianos sin exigencia estructural',
    ),
  ];
}

/// Un tramo de pared que el usuario va añadiendo a la lista.
class Pared {
  final String id;
  final String etiqueta;
  final double largoM;
  final double altoM;

  const Pared({
    required this.id,
    required this.etiqueta,
    required this.largoM,
    required this.altoM,
  });

  double get areaM2 => largoM * altoM;
}

/// Un vano (puerta, ventana u otra abertura) que se descuenta del
/// área bruta de las paredes.
class Vano {
  final String id;
  final String etiqueta;
  final double anchoM;
  final double altoM;

  const Vano({
    required this.id,
    required this.etiqueta,
    required this.anchoM,
    required this.altoM,
  });

  double get areaM2 => anchoM * altoM;
}

@immutable
class ResultadoMamposteria {
  final double areaBrutaM2;
  final double areaVanosM2;
  final double areaNetaM2;

  final double bloquesPorM2;
  final double bloquesNetos; // exactos, sin redondear ni desperdicio
  final double bloquesDesperdicio; // solo el excedente por desperdicio
  final int bloquesTotalComprar; // netos + desperdicio, redondeado hacia arriba

  final double morteroNetoM3;
  final double morteroDesperdicioM3;
  final double morteroTotalM3;

  final double sacosCementoMortero;
  final double arenaMorteroM3;

  const ResultadoMamposteria({
    required this.areaBrutaM2,
    required this.areaVanosM2,
    required this.areaNetaM2,
    required this.bloquesPorM2,
    required this.bloquesNetos,
    required this.bloquesDesperdicio,
    required this.bloquesTotalComprar,
    required this.morteroNetoM3,
    required this.morteroDesperdicioM3,
    required this.morteroTotalM3,
    required this.sacosCementoMortero,
    required this.arenaMorteroM3,
  });
}

/// Calcula bloques y mortero necesarios para levantar un conjunto de
/// paredes, descontando puertas/ventanas, y contabilizando el
/// desperdicio (roturas, cortes) SIEMPRE por separado del bloque
/// usable — nunca mezclado en una sola cifra.
///
/// Fórmula de referencia usada en presupuestos de obra (estimación
/// de campo, no sustituye el criterio del maestro de obra):
///   bloques por m² = 1 / ((largo+junta) x (alto+junta))
///   mortero por m² = (1 − área_cara_bloque x bloques_por_m²) x espesor_bloque
class CalcularMamposteria {
  ResultadoMamposteria call({
    required List<Pared> paredes,
    required List<Vano> vanos,
    required TipoBloque tipoBloque,
    required double espesorJuntaCm,
    required double porcentajeDesperdicio,
    required DosificacionMortero dosificacionMortero,
  }) {
    final areaBruta = paredes.fold(0.0, (s, p) => s + p.areaM2);
    final areaVanos = vanos.fold(0.0, (s, v) => s + v.areaM2);
    final areaNeta = (areaBruta - areaVanos).clamp(0.0, double.infinity);

    final largoM = tipoBloque.largoCm / 100;
    final altoM = tipoBloque.altoCm / 100;
    final espesorBloqueM = tipoBloque.espesorCm / 100;
    final juntaM = espesorJuntaCm / 100;

    final bloquesPorM2 = 1 / ((largoM + juntaM) * (altoM + juntaM));
    final areaCaraBloque = largoM * altoM;
    final fraccionJuntaPorM2 = (1 - (areaCaraBloque * bloquesPorM2)).clamp(0.0, 1.0);
    final morteroPorM2 = fraccionJuntaPorM2 * espesorBloqueM;

    final bloquesNetos = areaNeta * bloquesPorM2;
    final morteroNeto = areaNeta * morteroPorM2;

    final factorDesperdicio = porcentajeDesperdicio / 100;
    final bloquesDesperdicio = bloquesNetos * factorDesperdicio;
    final morteroDesperdicio = morteroNeto * factorDesperdicio;

    final morteroTotal = morteroNeto + morteroDesperdicio;

    // El total a comprar se arma sumando el neto YA redondeado hacia
    // arriba más el desperdicio YA redondeado hacia arriba (no el
    // redondeo de la suma exacta), para que en pantalla "neto +
    // desperdicio" siempre cuadre exactamente con "total a comprar".
    final bloquesNetosUnidades = bloquesNetos.ceil();
    final bloquesDesperdicioUnidades = bloquesDesperdicio.ceil();

    return ResultadoMamposteria(
      areaBrutaM2: areaBruta,
      areaVanosM2: areaVanos,
      areaNetaM2: areaNeta,
      bloquesPorM2: bloquesPorM2,
      bloquesNetos: bloquesNetos,
      bloquesDesperdicio: bloquesDesperdicio,
      bloquesTotalComprar: bloquesNetosUnidades + bloquesDesperdicioUnidades,
      morteroNetoM3: morteroNeto,
      morteroDesperdicioM3: morteroDesperdicio,
      morteroTotalM3: morteroTotal,
      sacosCementoMortero: morteroTotal * dosificacionMortero.bolsasCementoPorM3,
      arenaMorteroM3: morteroTotal * dosificacionMortero.arenaM3PorM3,
    );
  }
}
