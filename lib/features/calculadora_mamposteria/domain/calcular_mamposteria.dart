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
/// (cemento : arena, en volumen). Igual que la tabla de concreto,
/// es una guía de campo para obra menor y mediana — la proporción
/// definitiva depende de la arena disponible en la zona. La misma
/// dosificación seleccionada aquí se reutiliza para el repello.
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
      bolsasCementoPorM3: 11.4,
      arenaM3PorM3: 0.98,
      usoTypico: 'Pega de mayor resistencia (muros de carga, zonas sísmicas)',
    ),
    DosificacionMortero(
      proporcion: '1 : 4',
      bolsasCementoPorM3: 8.8,
      arenaM3PorM3: 1.05,
      usoTypico: 'Pega de bloque estándar (uso general)',
    ),
    DosificacionMortero(
      proporcion: '1 : 5',
      bolsasCementoPorM3: 7.2,
      arenaM3PorM3: 1.10,
      usoTypico: 'Muros divisorios livianos, sin carga',
    ),
  ];
}

/// Espesor estándar de la capa de repello (aplanado), fijo a 2 cm
/// como es práctica común de obra.
const double espesorRepelloM = 0.02;

/// Rendimiento estimado del pulido (planchado fino, 3 a 5 mm de
/// espesor, promedio 4 mm): cuántos m² cubre un saco de cemento de
/// 42.5 kg en pasta pura. Es una cifra de campo — ajústala según tu
/// experiencia si tu mezcla/mano de obra rinde distinto.
const double rendimientoPulidoM2PorSaco = 8.0;

/// Un tramo de pared que el usuario va añadiendo a la lista.
/// [llevaRepello] y [llevaPulido] se marcan por pared, ya que no
/// todas las paredes de un proyecto llevan acabado (p. ej. paredes
/// que quedarán cubiertas por cerámica, o muros perimetrales sin
/// terminar).
class Pared {
  final String id;
  final String etiqueta;
  final double largoM;
  final double altoM;
  final bool llevaRepello;
  final bool llevaPulido;

  const Pared({
    required this.id,
    required this.etiqueta,
    required this.largoM,
    required this.altoM,
    this.llevaRepello = false,
    this.llevaPulido = false,
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

  // Repello y pulido: solo sobre las paredes marcadas con el switch
  // correspondiente (área tal cual la pared, sin descuento de vanos
  // por pared individual, ya que los vanos no están ligados a una
  // pared específica en este modelo — descuéntalos a mano si aplica).
  final double areaConRepelloM2;
  final double areaConPulidoM2;
  final double repelloMorteroM3;
  final double repelloSacosCemento;
  final double repelloArenaM3;
  final double pulidoSacosCemento;

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
    required this.areaConRepelloM2,
    required this.areaConPulidoM2,
    required this.repelloMorteroM3,
    required this.repelloSacosCemento,
    required this.repelloArenaM3,
    required this.pulidoSacosCemento,
  });
}

/// Calcula bloques y mortero necesarios para levantar un conjunto de
/// paredes, descontando puertas/ventanas, y contabilizando el
/// desperdicio (roturas, cortes) SIEMPRE por separado del bloque
/// usable — nunca mezclado en una sola cifra. También calcula el
/// repello y pulido de las paredes marcadas con esos acabados.
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

    // Repello y pulido, solo sobre las paredes marcadas.
    final areaConRepello = paredes.where((p) => p.llevaRepello).fold(0.0, (s, p) => s + p.areaM2);
    final areaConPulido = paredes.where((p) => p.llevaPulido).fold(0.0, (s, p) => s + p.areaM2);

    final repelloMortero = areaConRepello * espesorRepelloM;
    final repelloCemento = repelloMortero * dosificacionMortero.bolsasCementoPorM3;
    final repelloArena = repelloMortero * dosificacionMortero.arenaM3PorM3;
    final pulidoCemento = areaConPulido / rendimientoPulidoM2PorSaco;

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
      areaConRepelloM2: areaConRepello,
      areaConPulidoM2: areaConPulido,
      repelloMorteroM3: repelloMortero,
      repelloSacosCemento: repelloCemento,
      repelloArenaM3: repelloArena,
      pulidoSacosCemento: pulidoCemento,
    );
  }
}
