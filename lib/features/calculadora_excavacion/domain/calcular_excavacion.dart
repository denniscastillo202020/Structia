import 'package:flutter/foundation.dart';

/// Una zapata a excavar, con las mismas dimensiones de fundición que
/// usaste en la calculadora de Zapatas, más la profundidad.
class ZapataExcavacion {
  final String id;
  final String etiqueta;
  final double largoZapataM;
  final double anchoZapataM;
  final double profundidadM;
  final int cantidad;

  const ZapataExcavacion({
    required this.id,
    required this.etiqueta,
    required this.largoZapataM,
    required this.anchoZapataM,
    required this.profundidadM,
    this.cantidad = 1,
  });
}

/// Márgenes de trabajo típicos para excavar a mano: espacio extra
/// alrededor de la zapata para colocar el encofrado y trabajar con
/// comodidad, más un poco de sobreexcavación en el fondo para
/// nivelar. Son valores de referencia — ajústalos si tu caso lo
/// requiere.
class ConstantesExcavacion {
  static const double margenTrabajoM = 0.10; // por lado
  static const double sobreexcavacionFondoM = 0.05;
}

@immutable
class DetalleZapataExcavacion {
  final String etiqueta;
  final double volumenExcavacionM3;
  final double volumenRellenoM3;

  const DetalleZapataExcavacion({
    required this.etiqueta,
    required this.volumenExcavacionM3,
    required this.volumenRellenoM3,
  });
}

@immutable
class ResultadoExcavacion {
  final double volumenExcavacionTotalM3;
  final double volumenRellenoTotalM3;
  final double volumenConcretoReferenciaM3;
  final List<DetalleZapataExcavacion> detallesPorZapata;

  const ResultadoExcavacion({
    required this.volumenExcavacionTotalM3,
    required this.volumenRellenoTotalM3,
    required this.volumenConcretoReferenciaM3,
    required this.detallesPorZapata,
  });
}

/// Calcula el volumen de excavación y de relleno (tierra que se
/// compacta alrededor de la zapata después de fundir) a partir de
/// las dimensiones de cada zapata. Estimación de campo — el tipo de
/// suelo, el nivel freático y la profundidad real de desplante
/// siempre deben confirmarlos un ingeniero según el estudio de
/// suelos.
class CalcularExcavacion {
  ResultadoExcavacion call({required List<ZapataExcavacion> zapatas}) {
    var excavacionTotal = 0.0;
    var rellenoTotal = 0.0;
    var concretoReferencia = 0.0;
    final detalles = <DetalleZapataExcavacion>[];

    for (final z in zapatas) {
      if (z.largoZapataM <= 0 || z.anchoZapataM <= 0 || z.profundidadM <= 0) continue;

      final largoExc = z.largoZapataM + 2 * ConstantesExcavacion.margenTrabajoM;
      final anchoExc = z.anchoZapataM + 2 * ConstantesExcavacion.margenTrabajoM;
      final profExc = z.profundidadM + ConstantesExcavacion.sobreexcavacionFondoM;

      final volExcavacionUnidad = largoExc * anchoExc * profExc;
      final volConcretoUnidad = z.largoZapataM * z.anchoZapataM * z.profundidadM;
      final volRellenoUnidadRaw = volExcavacionUnidad - volConcretoUnidad;
      final volRellenoUnidad = volRellenoUnidadRaw < 0 ? 0.0 : volRellenoUnidadRaw;

      excavacionTotal += volExcavacionUnidad * z.cantidad;
      rellenoTotal += volRellenoUnidad * z.cantidad;
      concretoReferencia += volConcretoUnidad * z.cantidad;

      detalles.add(DetalleZapataExcavacion(
        etiqueta: z.etiqueta,
        volumenExcavacionM3: volExcavacionUnidad * z.cantidad,
        volumenRellenoM3: volRellenoUnidad * z.cantidad,
      ));
    }

    return ResultadoExcavacion(
      volumenExcavacionTotalM3: excavacionTotal,
      volumenRellenoTotalM3: rellenoTotal,
      volumenConcretoReferenciaM3: concretoReferencia,
      detallesPorZapata: detalles,
    );
  }
}
