import 'package:flutter/foundation.dart';

/// Tipo de punto eléctrico. Cada tipo define qué caja PVC usa y a
/// qué categoría de cable pertenece (iluminación o tomacorrientes),
/// ya que normalmente llevan calibre distinto.
enum TipoPunto { tomacorriente, interruptor, foco }

extension TipoPuntoInfo on TipoPunto {
  String get etiqueta {
    switch (this) {
      case TipoPunto.tomacorriente:
        return 'Tomacorriente';
      case TipoPunto.interruptor:
        return 'Interruptor (switch)';
      case TipoPunto.foco:
        return 'Foco / lámpara / roseta';
    }
  }

  /// true = caja rectangular (tomacorriente, switch); false = octagonal (foco/lámpara).
  bool get usaCajaRectangular => this != TipoPunto.foco;

  /// true = va en el circuito de tomacorrientes (calibre más grueso);
  /// false = va en el circuito de iluminación.
  bool get esTomacorriente => this == TipoPunto.tomacorriente;
}

/// Un punto eléctrico (switch, foco o tomacorriente) con la distancia
/// del tramo de cableado que le corresponde: desde el punto anterior
/// en la misma cadena, o desde el panel/tablero si es el primer punto
/// del circuito. Siguiendo el recorrido real del cableado (no la
/// línea recta).
class PuntoElectrico {
  final String id;
  final String etiqueta;
  final TipoPunto tipo;
  final double distanciaM;

  const PuntoElectrico({
    required this.id,
    required this.etiqueta,
    required this.tipo,
    required this.distanciaM,
  });
}

/// Calibre de cable (AWG) y su presentación comercial en rollo.
class CalibreCable {
  final String etiqueta;
  final double rolloM;

  const CalibreCable({required this.etiqueta, required this.rolloM});

  static const List<CalibreCable> presets = [
    CalibreCable(etiqueta: '14 AWG (iluminación, 15A)', rolloM: 100),
    CalibreCable(etiqueta: '12 AWG (tomacorrientes, 20A)', rolloM: 100),
    CalibreCable(etiqueta: '10 AWG (cargas mayores, 30A)', rolloM: 100),
  ];
}

/// Un breaker/circuito que el usuario agrega manualmente. El amperaje
/// lo decide el usuario — la app NO lo calcula ni lo valida: el
/// dimensionamiento de circuitos debe confirmarlo un electricista
/// certificado según la carga real conectada.
class Breaker {
  final String id;
  final String etiqueta;
  final int amperaje;

  const Breaker({required this.id, required this.etiqueta, required this.amperaje});
}

/// Espacios disponibles en tableros comerciales, para sugerir el
/// tamaño mínimo que alcanza para los breakers agregados.
const List<int> espaciosTableroPresets = [4, 8, 12, 16, 24];

int? tableroSugerido(int cantidadBreakers) {
  for (final espacios in espaciosTableroPresets) {
    if (espacios >= cantidadBreakers) return espacios;
  }
  return null; // requiere tablero mayor a 24 espacios o combinar tableros
}

@immutable
class ResultadoElectrico {
  final double mangueraNetaM;
  final double mangueraConDesperdicioM;
  final int abrazaderas;

  final double cableIluminacionM;
  final int rollosIluminacion;
  final double cableTomacorrientesM;
  final int rollosTomacorrientes;
  final int conductoresPorPunto;

  final int cajasRectangulares;
  final int cajasOctagonales;
  final int tornillosCajas;
  final int rollosTape;

  final int cantidadBreakers;
  final int? tableroEspacios;

  const ResultadoElectrico({
    required this.mangueraNetaM,
    required this.mangueraConDesperdicioM,
    required this.abrazaderas,
    required this.cableIluminacionM,
    required this.rollosIluminacion,
    required this.cableTomacorrientesM,
    required this.rollosTomacorrientes,
    required this.conductoresPorPunto,
    required this.cajasRectangulares,
    required this.cajasOctagonales,
    required this.tornillosCajas,
    required this.rollosTape,
    required this.cantidadBreakers,
    required this.tableroEspacios,
  });
}

/// Calcula manguera, abrazaderas, cable, cajas y tornillos para un
/// conjunto de puntos eléctricos encadenados (tablero → punto 1 →
/// punto 2 → ...), donde cada punto trae la distancia de su propio
/// tramo. Estimación de campo — el diseño de circuitos y la
/// protección (amperaje de breakers) siempre debe confirmarlos un
/// electricista certificado.
class CalcularElectrico {
  ResultadoElectrico call({
    required List<PuntoElectrico> puntos,
    required List<Breaker> breakers,
    required double porcentajeDesperdicio,
    required double espaciadoAbrazaderasM,
    required int conductoresPorPunto,
    required CalibreCable calibreIluminacion,
    required CalibreCable calibreTomacorrientes,
  }) {
    final mangueraNeta = puntos.fold(0.0, (s, p) => s + p.distanciaM);
    final mangueraConDesperdicio = mangueraNeta * (1 + porcentajeDesperdicio / 100);

    final abrazaderas = mangueraConDesperdicio > 0
        ? (mangueraConDesperdicio / espaciadoAbrazaderasM).ceil() + puntos.length
        : 0;

    final cableIluminacion = puntos
            .where((p) => !p.tipo.esTomacorriente)
            .fold(0.0, (s, p) => s + p.distanciaM) *
        conductoresPorPunto;
    final cableTomacorrientes = puntos
            .where((p) => p.tipo.esTomacorriente)
            .fold(0.0, (s, p) => s + p.distanciaM) *
        conductoresPorPunto;

    final rollosIluminacion =
        cableIluminacion > 0 ? (cableIluminacion / calibreIluminacion.rolloM).ceil() : 0;
    final rollosTomacorrientes = cableTomacorrientes > 0
        ? (cableTomacorrientes / calibreTomacorrientes.rolloM).ceil()
        : 0;

    // Cada tomacorriente lleva 2 cajas rectangulares: la del propio
    // toma y la del empalme de paso hacia el siguiente punto. Los
    // switches llevan 1 caja rectangular; los focos/lámparas 1 octagonal.
    final cajasRectangulares = puntos.fold<int>(0, (s, p) {
      if (!p.tipo.usaCajaRectangular) return s;
      return s + (p.tipo.esTomacorriente ? 2 : 1);
    });
    final cajasOctagonales = puntos.where((p) => !p.tipo.usaCajaRectangular).length;
    final tornillosCajas = (cajasRectangulares + cajasOctagonales) * 2;

    final rollosTape = puntos.isEmpty ? 0 : (puntos.length / 20).ceil().clamp(1, 999);

    final tablero = tableroSugerido(breakers.length);

    return ResultadoElectrico(
      mangueraNetaM: mangueraNeta,
      mangueraConDesperdicioM: mangueraConDesperdicio,
      abrazaderas: abrazaderas,
      cableIluminacionM: cableIluminacion,
      rollosIluminacion: rollosIluminacion,
      cableTomacorrientesM: cableTomacorrientes,
      rollosTomacorrientes: rollosTomacorrientes,
      conductoresPorPunto: conductoresPorPunto,
      cajasRectangulares: cajasRectangulares,
      cajasOctagonales: cajasOctagonales,
      tornillosCajas: tornillosCajas,
      rollosTape: rollosTape,
      cantidadBreakers: breakers.length,
      tableroEspacios: tablero,
    );
  }
}
