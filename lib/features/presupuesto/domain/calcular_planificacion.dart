/// Calcula honorarios de planificación profesional como referencia:
/// típicamente entre 3% (profesional con menos experiencia) y 5%
/// (mayor trayectoria) del costo total estimado de la obra. También
/// estima el sobrecosto de referencia por improvisar sin planificar
/// (7%-10%) y el costo de supervisión profesional (15%-30%).
///
/// Son porcentajes de referencia que el propio usuario compartió como
/// guía de mercado — no una tarifa fija ni una recomendación de
/// StructIA sobre lo que "debe" cobrarse.
class ResultadoPlanificacion {
  final double montoObraL;
  final double honorarioMinimoL; // 3%
  final double honorarioMaximoL; // 5%
  final double sobrecostoMinimoNoPlanificarL; // 7%
  final double sobrecostoMaximoNoPlanificarL; // 10%
  final double supervisionMinimaL; // 15% de la mano de obra directa
  final double supervisionMaximaL; // 30% de la mano de obra directa

  const ResultadoPlanificacion({
    required this.montoObraL,
    required this.honorarioMinimoL,
    required this.honorarioMaximoL,
    required this.sobrecostoMinimoNoPlanificarL,
    required this.sobrecostoMaximoNoPlanificarL,
    required this.supervisionMinimaL,
    required this.supervisionMaximaL,
  });
}

class CalcularPlanificacion {
  ResultadoPlanificacion call({
    required double montoObraL,
    double? costoManoDeObraDirectaL,
  }) {
    final baseSupervision = costoManoDeObraDirectaL ?? montoObraL;
    return ResultadoPlanificacion(
      montoObraL: montoObraL,
      honorarioMinimoL: montoObraL * 0.03,
      honorarioMaximoL: montoObraL * 0.05,
      sobrecostoMinimoNoPlanificarL: montoObraL * 0.07,
      sobrecostoMaximoNoPlanificarL: montoObraL * 0.10,
      supervisionMinimaL: baseSupervision * 0.15,
      supervisionMaximaL: baseSupervision * 0.30,
    );
  }
}
