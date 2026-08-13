import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';

enum TipoApoyoViga {
  simplementeApoyada('Simplemente apoyada (sobre 2 columnas)'),
  continua('Continua (sobre 3 o más columnas)'),
  voladizo('En voladizo (empotrada en un extremo)');

  final String etiqueta;
  const TipoApoyoViga(this.etiqueta);
}

/// Geometría y armado de UNA viga, definidos por el usuario. Igual
/// que en columnas: esto NO diseña la viga, solo cuantifica material
/// para el armado que el usuario ya definió. [cantidadVigas] permite
/// calcular el material para varias vigas iguales de una sola vez.
class DatosViga {
  final double anchoCm;
  final double peralteCm;
  final double luzM;
  final double recubrimientoCm;
  final TipoApoyoViga tipoApoyo;

  final DiametroVarilla diametroSuperior;
  final int cantidadVarillasSuperiores;
  final DiametroVarilla diametroInferior;
  final int cantidadVarillasInferiores;

  final DiametroVarilla diametroEstribo;
  final double separacionEstribosCm;
  final int cantidadVigas;

  const DatosViga({
    required this.anchoCm,
    required this.peralteCm,
    required this.luzM,
    required this.recubrimientoCm,
    required this.tipoApoyo,
    required this.diametroSuperior,
    required this.cantidadVarillasSuperiores,
    required this.diametroInferior,
    required this.cantidadVarillasInferiores,
    required this.diametroEstribo,
    required this.separacionEstribosCm,
    this.cantidadVigas = 1,
  });

  double get volumenConcretoM3 =>
      (anchoCm / 100) * (peralteCm / 100) * luzM * cantidadVigas;

  double get _radioEstribo => 0.6;

  List<({double xCm, double yCm})> _posicionesEnFila(int cantidad, double yCm) {
    final margenX = recubrimientoCm + _radioEstribo;
    final anchoUtil = anchoCm - 2 * margenX;
    if (cantidad <= 0) return [];
    if (cantidad == 1) return [(xCm: anchoCm / 2, yCm: yCm)];

    final puntos = <({double xCm, double yCm})>[];
    for (var i = 0; i < cantidad; i++) {
      final t = i / (cantidad - 1);
      puntos.add((xCm: margenX + anchoUtil * t, yCm: yCm));
    }
    return puntos;
  }

  List<({double xCm, double yCm})> posicionesVarillasSuperiores() {
    final margenY = recubrimientoCm + _radioEstribo;
    return _posicionesEnFila(cantidadVarillasSuperiores, margenY);
  }

  List<({double xCm, double yCm})> posicionesVarillasInferiores() {
    final margenY = peralteCm - recubrimientoCm - _radioEstribo;
    return _posicionesEnFila(cantidadVarillasInferiores, margenY);
  }
}

class ResultadoViga {
  final ResultadoCorteAcero aceroSuperior;
  final ResultadoCorteAcero aceroInferior;
  final ResultadoCorteAcero aceroEstribos;
  final int cantidadEstribosPorViga;
  final double perimetroEstriboM;
  final double volumenConcretoM3;

  const ResultadoViga({
    required this.aceroSuperior,
    required this.aceroInferior,
    required this.aceroEstribos,
    required this.cantidadEstribosPorViga,
    required this.perimetroEstriboM,
    required this.volumenConcretoM3,
  });
}

/// Calcula cantidades de acero para [DatosViga.cantidadVigas] vigas
/// IGUALES a partir del armado de una sola viga, combinando todas las
/// piezas en un solo cálculo de corte para aprovechar mejor los
/// retazos entre vigas.
class CalcularViga {
  ResultadoViga call(DatosViga datos) {
    final cantidadTotal = datos.cantidadVigas;

    final aceroSuperior = CalcularAcero().calcularPiezasCortas(
      longitudPiezaM: datos.luzM,
      cantidadPiezas: datos.cantidadVarillasSuperiores * cantidadTotal,
      diametro: datos.diametroSuperior,
      longitudTraslapeM: 0.5,
    );

    final aceroInferior = CalcularAcero().calcularPiezasCortas(
      longitudPiezaM: datos.luzM,
      cantidadPiezas: datos.cantidadVarillasInferiores * cantidadTotal,
      diametro: datos.diametroInferior,
      longitudTraslapeM: 0.5,
    );

    final longitudCm = datos.luzM * 100;
    final cantidadEstribosPorViga = (longitudCm / datos.separacionEstribosCm).ceil() + 1;

    final anchoInterno = datos.anchoCm - 2 * datos.recubrimientoCm;
    final peralteInterno = datos.peralteCm - 2 * datos.recubrimientoCm;
    final perimetroEstriboCm = 2 * (anchoInterno + peralteInterno) + 10;
    final perimetroEstriboM = perimetroEstriboCm / 100;

    final aceroEstribos = CalcularAcero().calcularPiezasCortas(
      longitudPiezaM: perimetroEstriboM,
      cantidadPiezas: cantidadEstribosPorViga * cantidadTotal,
      diametro: datos.diametroEstribo,
    );

    return ResultadoViga(
      aceroSuperior: aceroSuperior,
      aceroInferior: aceroInferior,
      aceroEstribos: aceroEstribos,
      cantidadEstribosPorViga: cantidadEstribosPorViga,
      perimetroEstriboM: perimetroEstriboM,
      volumenConcretoM3: datos.volumenConcretoM3,
    );
  }
}
