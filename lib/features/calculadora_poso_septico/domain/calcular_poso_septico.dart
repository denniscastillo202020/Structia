import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';
import 'package:structia/features/calculadora_mamposteria/domain/calcular_mamposteria.dart';

/// Pozo séptico rectangular: paredes de bloque con refuerzo vertical
/// dentro de las celdas, y tapadera de concreto armada con una cama
/// de varillas en dos direcciones (igual que una zapata aislada).
class DatosPosoSeptico {
  final double largoInternoM;
  final double anchoInternoM;
  final double profundidadM;

  final TipoBloque tipoBloque;
  final double espesorJuntaCm;
  final double porcentajeDesperdicioBloque;
  final DosificacionMortero dosificacionMortero;

  final DiametroVarilla diametroVertical;
  final double separacionVerticalCm;

  final double espesorLosaCm;
  final DiametroVarilla diametroLosa;
  final double separacionLosaCm;
  final double recubrimientoLosaCm;
  final DosificacionConcreto dosificacionConcretoLosa;

  const DatosPosoSeptico({
    required this.largoInternoM,
    required this.anchoInternoM,
    required this.profundidadM,
    required this.tipoBloque,
    required this.espesorJuntaCm,
    required this.porcentajeDesperdicioBloque,
    required this.dosificacionMortero,
    required this.diametroVertical,
    required this.separacionVerticalCm,
    required this.espesorLosaCm,
    required this.diametroLosa,
    required this.separacionLosaCm,
    required this.recubrimientoLosaCm,
    required this.dosificacionConcretoLosa,
  });

  double get perimetroM => 2 * (largoInternoM + anchoInternoM);
  double get areaParedesM2 => perimetroM * profundidadM;
  double get areaLosaM2 => largoInternoM * anchoInternoM;
  double get volumenConcretoLosaM3 => areaLosaM2 * (espesorLosaCm / 100);
}

class ResultadoPosoSeptico {
  final ResultadoMamposteria paredes;
  final int cantidadVarillasVerticales;
  final ResultadoCorteAcero aceroVertical;
  final int cantidadBarrasLosaDireccionX;
  final int cantidadBarrasLosaDireccionY;
  final ResultadoCorteAcero aceroLosaDireccionX;
  final ResultadoCorteAcero aceroLosaDireccionY;
  final double volumenConcretoLosaM3;
  final ResultadoMaterialesConcreto concretoLosa;

  const ResultadoPosoSeptico({
    required this.paredes,
    required this.cantidadVarillasVerticales,
    required this.aceroVertical,
    required this.cantidadBarrasLosaDireccionX,
    required this.cantidadBarrasLosaDireccionY,
    required this.aceroLosaDireccionX,
    required this.aceroLosaDireccionY,
    required this.volumenConcretoLosaM3,
    required this.concretoLosa,
  });
}

/// Calcula bloque + mortero de las paredes (reusando la misma lógica
/// que "Muros y bloques"), el refuerzo vertical dentro de las celdas
/// del bloque (una varilla por celda, según la separación indicada),
/// y la tapadera de concreto armada con una cama de varillas en dos
/// direcciones (igual criterio que una zapata aislada).
class CalcularPosoSeptico {
  ResultadoPosoSeptico call(DatosPosoSeptico datos) {
    final paredes = CalcularMamposteria()(
      paredes: [
        Pared(
          id: 'poso',
          etiqueta: 'Paredes del pozo séptico',
          largoM: datos.perimetroM,
          altoM: datos.profundidadM,
        ),
      ],
      vanos: const [],
      tipoBloque: datos.tipoBloque,
      espesorJuntaCm: datos.espesorJuntaCm,
      porcentajeDesperdicio: datos.porcentajeDesperdicioBloque,
      dosificacionMortero: datos.dosificacionMortero,
    );

    final cantidadVarillasVerticales =
        (datos.perimetroM * 100 / datos.separacionVerticalCm).ceil() + 1;
    final aceroVertical = CalcularAcero()(
      tramos: [
        TramoRequerido(longitudM: datos.profundidadM, cantidad: cantidadVarillasVerticales),
      ],
      diametro: datos.diametroVertical,
    );

    final margenLosaM = datos.recubrimientoLosaCm / 100;
    final cantidadBarrasX =
        ((datos.anchoInternoM - 2 * margenLosaM) * 100 / datos.separacionLosaCm).ceil() + 1;
    final cantidadBarrasY =
        ((datos.largoInternoM - 2 * margenLosaM) * 100 / datos.separacionLosaCm).ceil() + 1;
    final longitudBarraXM = datos.largoInternoM - 2 * margenLosaM;
    final longitudBarraYM = datos.anchoInternoM - 2 * margenLosaM;

    final aceroLosaX = CalcularAcero()(
      tramos: [TramoRequerido(longitudM: longitudBarraXM, cantidad: cantidadBarrasX)],
      diametro: datos.diametroLosa,
    );
    final aceroLosaY = CalcularAcero()(
      tramos: [TramoRequerido(longitudM: longitudBarraYM, cantidad: cantidadBarrasY)],
      diametro: datos.diametroLosa,
    );

    final concretoLosa = CalcularMaterialesConcreto()(
      volumenM3: datos.volumenConcretoLosaM3,
      dosificacion: datos.dosificacionConcretoLosa,
    );

    return ResultadoPosoSeptico(
      paredes: paredes,
      cantidadVarillasVerticales: cantidadVarillasVerticales,
      aceroVertical: aceroVertical,
      cantidadBarrasLosaDireccionX: cantidadBarrasX,
      cantidadBarrasLosaDireccionY: cantidadBarrasY,
      aceroLosaDireccionX: aceroLosaX,
      aceroLosaDireccionY: aceroLosaY,
      volumenConcretoLosaM3: datos.volumenConcretoLosaM3,
      concretoLosa: concretoLosa,
    );
  }
}
