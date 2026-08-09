import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';

/// Firme (contrapiso): solo concreto sobre el terreno compactado, con
/// una opción de reforzarlo con malla electrosoldada (sin acero de
/// columna/viga/losa — es un elemento no estructural, de piso).
class DatosFirme {
  final double largoM;
  final double anchoM;
  final double espesorCm;
  final bool llevaMalla;
  final int cantidadTramos;

  const DatosFirme({
    required this.largoM,
    required this.anchoM,
    required this.espesorCm,
    required this.llevaMalla,
    this.cantidadTramos = 1,
  });

  double get areaM2 => largoM * anchoM * cantidadTramos;

  double get volumenConcretoM3 => areaM2 * (espesorCm / 100);
}

class ResultadoFirme {
  final double areaM2;
  final double volumenConcretoM3;
  final ResultadoMaterialesConcreto concreto;
  final int panelesMallaNecesarios;

  const ResultadoFirme({
    required this.areaM2,
    required this.volumenConcretoM3,
    required this.concreto,
    required this.panelesMallaNecesarios,
  });
}

/// Calcula concreto (y opcionalmente malla electrosoldada) para un
/// firme. Misma medida comercial de malla que la losa aligerada:
/// paneles de 2.30 x 6.00 m con traslape de 15 cm entre paneles.
class CalcularFirme {
  static const double _anchoPanelMallaM = 2.30;
  static const double _largoPanelMallaM = 6.00;
  static const double _traslapeMallaM = 0.15;

  int _panelesParaCubrir(double medidaTotalM, double medidaPanelM, double traslapeM) {
    if (medidaTotalM <= medidaPanelM) return 1;
    final coberturaAdicionalPorPanel = medidaPanelM - traslapeM;
    final panelesAdicionales = ((medidaTotalM - medidaPanelM) / coberturaAdicionalPorPanel).ceil();
    return 1 + panelesAdicionales;
  }

  ResultadoFirme call({
    required DatosFirme datos,
    required DosificacionConcreto dosificacion,
  }) {
    final concreto = CalcularMaterialesConcreto()(
      volumenM3: datos.volumenConcretoM3,
      dosificacion: dosificacion,
    );

    var panelesMalla = 0;
    if (datos.llevaMalla) {
      final panelesAncho = _panelesParaCubrir(datos.anchoM, _anchoPanelMallaM, _traslapeMallaM);
      final panelesLargo = _panelesParaCubrir(datos.largoM, _largoPanelMallaM, _traslapeMallaM);
      panelesMalla = panelesAncho * panelesLargo * datos.cantidadTramos;
    }

    return ResultadoFirme(
      areaM2: datos.areaM2,
      volumenConcretoM3: datos.volumenConcretoM3,
      concreto: concreto,
      panelesMallaNecesarios: panelesMalla,
    );
  }
}
