import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';

enum TipoZapata {
  corrida('Zapata corrida'),
  aislada('Zapata aislada');

  final String etiqueta;
  const TipoZapata(this.etiqueta);
}

/// Datos de una zapata CORRIDA (bajo un muro, se mide en metros
/// lineales): volumen = longitud x ancho x profundidad. Lleva acero
/// longitudinal (a lo largo de toda la zapata, con traslapes si hace
/// falta) y bastones transversales cada cierta separación.
class DatosZapataCorrida {
  final double longitudTotalM;
  final double anchoCm;
  final double profundidadCm;
  final double recubrimientoCm;
  final DiametroVarilla diametroLongitudinal;
  final int cantidadVarillasLongitudinales;
  final DiametroVarilla diametroTransversal;
  final double longitudBastonCm;
  final double separacionTransversalCm;
  final int cantidadZapatas;

  const DatosZapataCorrida({
    required this.longitudTotalM,
    required this.anchoCm,
    required this.profundidadCm,
    required this.recubrimientoCm,
    required this.diametroLongitudinal,
    required this.cantidadVarillasLongitudinales,
    required this.diametroTransversal,
    required this.longitudBastonCm,
    required this.separacionTransversalCm,
    this.cantidadZapatas = 1,
  });

  double get volumenConcretoM3 =>
      longitudTotalM * (anchoCm / 100) * (profundidadCm / 100) * cantidadZapatas;
}

class ResultadoZapataCorrida {
  final ResultadoCorteAcero aceroLongitudinal;
  final ResultadoCorteAcero aceroTransversal;
  final int cantidadBastonesPorZapata;
  final double volumenConcretoM3;

  const ResultadoZapataCorrida({
    required this.aceroLongitudinal,
    required this.aceroTransversal,
    required this.cantidadBastonesPorZapata,
    required this.volumenConcretoM3,
  });
}

class CalcularZapataCorrida {
  ResultadoZapataCorrida call(DatosZapataCorrida datos) {
    final aceroLongitudinal = CalcularAcero().calcularPiezasCortas(
      longitudPiezaM: datos.longitudTotalM,
      cantidadPiezas: datos.cantidadVarillasLongitudinales * datos.cantidadZapatas,
      diametro: datos.diametroLongitudinal,
      longitudTraslapeM: 0.5,
    );

    final longitudBastonM = datos.longitudBastonCm / 100;
    final cantidadBastonesPorZapata =
        ((datos.longitudTotalM * 100) / datos.separacionTransversalCm).ceil() + 1;

    final aceroTransversal = CalcularAcero().calcularPiezasCortas(
      longitudPiezaM: longitudBastonM,
      cantidadPiezas: cantidadBastonesPorZapata * datos.cantidadZapatas,
      diametro: datos.diametroTransversal,
    );

    return ResultadoZapataCorrida(
      aceroLongitudinal: aceroLongitudinal,
      aceroTransversal: aceroTransversal,
      cantidadBastonesPorZapata: cantidadBastonesPorZapata,
      volumenConcretoM3: datos.volumenConcretoM3,
    );
  }
}

/// Datos de una zapata AISLADA (bajo una columna, rectangular en
/// planta): volumen = ladoX x ladoY x profundidad. Lleva una "cama"
/// de varillas en dos direcciones (una malla), no varillas sueltas.
class DatosZapataAislada {
  final double ladoXCm;
  final double ladoYCm;
  final double profundidadCm;
  final double recubrimientoCm;
  final DiametroVarilla diametroCama;
  final double separacionCamaCm;
  final int cantidadZapatas;

  const DatosZapataAislada({
    required this.ladoXCm,
    required this.ladoYCm,
    required this.profundidadCm,
    required this.recubrimientoCm,
    required this.diametroCama,
    required this.separacionCamaCm,
    this.cantidadZapatas = 1,
  });

  double get volumenConcretoM3 =>
      (ladoXCm / 100) * (ladoYCm / 100) * (profundidadCm / 100) * cantidadZapatas;

  int get cantidadBarrasDireccionX =>
      ((ladoYCm - 2 * recubrimientoCm) / separacionCamaCm).ceil() + 1;
  int get cantidadBarrasDireccionY =>
      ((ladoXCm - 2 * recubrimientoCm) / separacionCamaCm).ceil() + 1;

  double get longitudBarraDireccionXM => (ladoXCm - 2 * recubrimientoCm) / 100;
  double get longitudBarraDireccionYM => (ladoYCm - 2 * recubrimientoCm) / 100;

  /// Posiciones (cm) de las varillas orientadas en X, para la vista en
  /// planta — cada una es una línea horizontal a una altura Y distinta.
  List<double> posicionesYBarrasX() {
    final n = cantidadBarrasDireccionX;
    if (n <= 1) return [ladoYCm / 2];
    return List.generate(n, (i) => recubrimientoCm + (ladoYCm - 2 * recubrimientoCm) * i / (n - 1));
  }

  /// Posiciones (cm) de las varillas orientadas en Y, cada una es una
  /// línea vertical a una posición X distinta.
  List<double> posicionesXBarrasY() {
    final n = cantidadBarrasDireccionY;
    if (n <= 1) return [ladoXCm / 2];
    return List.generate(n, (i) => recubrimientoCm + (ladoXCm - 2 * recubrimientoCm) * i / (n - 1));
  }
}

class ResultadoZapataAislada {
  final ResultadoCorteAcero aceroDireccionX;
  final ResultadoCorteAcero aceroDireccionY;
  final double volumenConcretoM3;

  const ResultadoZapataAislada({
    required this.aceroDireccionX,
    required this.aceroDireccionY,
    required this.volumenConcretoM3,
  });
}

class CalcularZapataAislada {
  ResultadoZapataAislada call(DatosZapataAislada datos) {
    final aceroX = CalcularAcero().calcularPiezasCortas(
      longitudPiezaM: datos.longitudBarraDireccionXM,
      cantidadPiezas: datos.cantidadBarrasDireccionX * datos.cantidadZapatas,
      diametro: datos.diametroCama,
      longitudTraslapeM: 0.5,
    );

    final aceroY = CalcularAcero().calcularPiezasCortas(
      longitudPiezaM: datos.longitudBarraDireccionYM,
      cantidadPiezas: datos.cantidadBarrasDireccionY * datos.cantidadZapatas,
      diametro: datos.diametroCama,
      longitudTraslapeM: 0.5,
    );

    return ResultadoZapataAislada(
      aceroDireccionX: aceroX,
      aceroDireccionY: aceroY,
      volumenConcretoM3: datos.volumenConcretoM3,
    );
  }
}
