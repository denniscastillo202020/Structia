import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';

/// Geometría y armado de UNA columna rectangular, definidos por el
/// usuario (esto NO calcula si el armado es estructuralmente
/// suficiente — solo la cantidad de material para el armado que tú
/// especifiques). [cantidadColumnas] permite calcular el material
/// para varias columnas iguales de una sola vez.
class DatosColumna {
  final double anchoCm;
  final double profundidadCm;
  final double alturaM;
  final double recubrimientoCm;
  final DiametroVarilla diametroLongitudinal;
  final int cantidadVarillasLongitudinales;
  final DiametroVarilla diametroEstribo;
  final double separacionEstribosCm;
  final int cantidadColumnas;

  const DatosColumna({
    required this.anchoCm,
    required this.profundidadCm,
    required this.alturaM,
    required this.recubrimientoCm,
    required this.diametroLongitudinal,
    required this.cantidadVarillasLongitudinales,
    required this.diametroEstribo,
    required this.separacionEstribosCm,
    this.cantidadColumnas = 1,
  });

  double get volumenConcretoM3 =>
      (anchoCm / 100) * (profundidadCm / 100) * alturaM * cantidadColumnas;

  /// Posiciones donde se ubican las varillas longitudinales en el
  /// corte transversal: siempre 4 en las esquinas, y las varillas
  /// adicionales repartidas en PARES SIMÉTRICOS — primero arriba+abajo,
  /// luego izquierda+derecha, alternando — para que el armado se vea
  /// balanceado en ambos ejes (así se arma en la práctica: un patrón
  /// simétrico, nunca varillas sueltas en un solo lado).
  /// Es una distribución ilustrativa para la vista en planta, no un
  /// detalle de armado estructural definitivo.
  List<({double xCm, double yCm})> posicionesVarillas() {
    final margenX = recubrimientoCm + _radioEstribo;
    final margenY = recubrimientoCm + _radioEstribo;
    final anchoUtil = anchoCm - 2 * margenX;
    final profundidadUtil = profundidadCm - 2 * margenY;

    final n = cantidadVarillasLongitudinales;
    if (n <= 0) return [];
    if (n <= 4) {
      final esquinas = [
        (xCm: margenX, yCm: margenY),
        (xCm: margenX + anchoUtil, yCm: margenY),
        (xCm: margenX + anchoUtil, yCm: margenY + profundidadUtil),
        (xCm: margenX, yCm: margenY + profundidadUtil),
      ];
      return esquinas.take(n).toList();
    }

    // porLado: [arriba, derecha, abajo, izquierda]
    final porLado = [0, 0, 0, 0];
    var restantes = n - 4;
    var turno = 0; // 0 = par arriba/abajo, 1 = par izquierda/derecha
    while (restantes > 0) {
      if (turno == 0) {
        porLado[0]++; // arriba
        restantes--;
        if (restantes > 0) {
          porLado[2]++; // abajo
          restantes--;
        }
      } else {
        porLado[1]++; // derecha
        restantes--;
        if (restantes > 0) {
          porLado[3]++; // izquierda
          restantes--;
        }
      }
      turno = 1 - turno;
    }

    final puntos = <({double xCm, double yCm})>[
      (xCm: margenX, yCm: margenY),
      (xCm: margenX + anchoUtil, yCm: margenY),
      (xCm: margenX + anchoUtil, yCm: margenY + profundidadUtil),
      (xCm: margenX, yCm: margenY + profundidadUtil),
    ];

    for (var i = 1; i <= porLado[0]; i++) {
      final t = i / (porLado[0] + 1);
      puntos.add((xCm: margenX + anchoUtil * t, yCm: margenY));
    }
    for (var i = 1; i <= porLado[1]; i++) {
      final t = i / (porLado[1] + 1);
      puntos.add((xCm: margenX + anchoUtil, yCm: margenY + profundidadUtil * t));
    }
    for (var i = 1; i <= porLado[2]; i++) {
      final t = i / (porLado[2] + 1);
      puntos.add((xCm: margenX + anchoUtil * (1 - t), yCm: margenY + profundidadUtil));
    }
    for (var i = 1; i <= porLado[3]; i++) {
      final t = i / (porLado[3] + 1);
      puntos.add((xCm: margenX, yCm: margenY + profundidadUtil * (1 - t)));
    }

    return puntos;
  }

  double get _radioEstribo => 0.6;
}

class ResultadoColumna {
  final ResultadoCorteAcero aceroLongitudinal;
  final ResultadoCorteAcero aceroEstribos;
  final int cantidadEstribosPorColumna;
  final double perimetroEstriboM;
  final double volumenConcretoM3;

  const ResultadoColumna({
    required this.aceroLongitudinal,
    required this.aceroEstribos,
    required this.cantidadEstribosPorColumna,
    required this.perimetroEstriboM,
    required this.volumenConcretoM3,
  });
}

/// Calcula las cantidades de acero (longitudinal y estribos) para
/// [DatosColumna.cantidadColumnas] columnas IGUALES, a partir de la
/// geometría y el armado de una sola columna. Internamente combina
/// todas las piezas de todas las columnas en un solo cálculo de corte
/// — así se aprovechan mejor los retazos entre columnas, en vez de
/// comprar el material columna por columna por separado.
class CalcularColumna {
  ResultadoColumna call(DatosColumna datos) {
    final cantidadTotal = datos.cantidadColumnas;

    final aceroLongitudinal = CalcularAcero()(
      tramos: [
        TramoRequerido(
          longitudM: datos.alturaM,
          cantidad: datos.cantidadVarillasLongitudinales * cantidadTotal,
        ),
      ],
      diametro: datos.diametroLongitudinal,
    );

    final alturaCm = datos.alturaM * 100;
    final cantidadEstribosPorColumna = (alturaCm / datos.separacionEstribosCm).ceil() + 1;

    final anchoInterno = datos.anchoCm - 2 * datos.recubrimientoCm;
    final profundidadInterna = datos.profundidadCm - 2 * datos.recubrimientoCm;
    final perimetroEstriboCm = 2 * (anchoInterno + profundidadInterna) + 10;
    final perimetroEstriboM = perimetroEstriboCm / 100;

    final aceroEstribos = CalcularAcero()(
      tramos: [
        TramoRequerido(
          longitudM: perimetroEstriboM,
          cantidad: cantidadEstribosPorColumna * cantidadTotal,
        ),
      ],
      diametro: datos.diametroEstribo,
    );

    return ResultadoColumna(
      aceroLongitudinal: aceroLongitudinal,
      aceroEstribos: aceroEstribos,
      cantidadEstribosPorColumna: cantidadEstribosPorColumna,
      perimetroEstriboM: perimetroEstriboM,
      volumenConcretoM3: datos.volumenConcretoM3,
    );
  }
}
