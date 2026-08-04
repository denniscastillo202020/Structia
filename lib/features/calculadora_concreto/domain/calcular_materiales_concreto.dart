/// Fila de la tabla práctica de dosificación de concreto, por
/// resistencia a compresión (f'c). Basada en tablas de referencia de
/// uso común en ingeniería civil para obra menor y mediana (proporción
/// en volumen, cantidades por m³ de concreto ya compactado), en línea
/// con los criterios del método ACI 211.1 para diseño de mezclas
/// normales. Bolsa de cemento de referencia: 42.5 kg.
///
/// IMPORTANTE: esta tabla es una guía práctica de campo. Para
/// elementos estructurales que exijan una resistencia garantizada
/// (columnas, vigas, losas de un diseño formal), la dosificación
/// definitiva debe confirmarse con un diseño de mezcla de laboratorio
/// y el criterio de un ingeniero estructural — los agregados varían
/// de una cantera a otra y eso cambia las proporciones reales.
class DosificacionConcreto {
  final int fc; // kg/cm²
  final String proporcion; // Cemento : Arena : Piedra, en volumen
  final double bolsasCementoPorM3;
  final double arenaM3PorM3;
  final double gravaM3PorM3;
  final double aguaLitrosPorM3;
  final String tamanoAgregadoRecomendado;
  final String usoTypico;

  const DosificacionConcreto({
    required this.fc,
    required this.proporcion,
    required this.bolsasCementoPorM3,
    required this.arenaM3PorM3,
    required this.gravaM3PorM3,
    required this.aguaLitrosPorM3,
    required this.tamanoAgregadoRecomendado,
    required this.usoTypico,
  });

  String get etiqueta => "f'c = $fc kg/cm² ($proporcion)";

  static const List<DosificacionConcreto> tabla = [
    DosificacionConcreto(
      fc: 140,
      proporcion: '1 : 2.5 : 3.5',
      bolsasCementoPorM3: 7.01,
      arenaM3PorM3: 0.51,
      gravaM3PorM3: 0.54,
      aguaLitrosPorM3: 184,
      tamanoAgregadoRecomendado: '3/4"',
      usoTypico: 'Solera de pobre, rellenos, contrapisos sin carga',
    ),
    DosificacionConcreto(
      fc: 175,
      proporcion: '1 : 2.5 : 2.5',
      bolsasCementoPorM3: 8.43,
      arenaM3PorM3: 0.54,
      gravaM3PorM3: 0.55,
      aguaLitrosPorM3: 185,
      tamanoAgregadoRecomendado: '1/2"',
      usoTypico: 'Aceras, cimientos corridos, muros de baja carga',
    ),
    DosificacionConcreto(
      fc: 210,
      proporcion: '1 : 2 : 2',
      bolsasCementoPorM3: 9.73,
      arenaM3PorM3: 0.52,
      gravaM3PorM3: 0.53,
      aguaLitrosPorM3: 186,
      tamanoAgregadoRecomendado: '1/2"',
      usoTypico: 'Zapatas, vigas, columnas y losas de vivienda (uso general)',
    ),
    DosificacionConcreto(
      fc: 245,
      proporcion: '1 : 1.5 : 1.5',
      bolsasCementoPorM3: 11.5,
      arenaM3PorM3: 0.50,
      gravaM3PorM3: 0.51,
      aguaLitrosPorM3: 187,
      tamanoAgregadoRecomendado: '1/2"',
      usoTypico: 'Elementos con mayor exigencia de carga',
    ),
    DosificacionConcreto(
      fc: 280,
      proporcion: '1 : 1 : 1.5',
      bolsasCementoPorM3: 13.34,
      arenaM3PorM3: 0.45,
      gravaM3PorM3: 0.51,
      aguaLitrosPorM3: 189,
      tamanoAgregadoRecomendado: '1/2"',
      usoTypico: 'Columnas y vigas de edificaciones, alta resistencia',
    ),
  ];
}

class ResultadoMaterialesConcreto {
  final double volumenM3;
  final double bolsasCemento;
  final double arenaM3;
  final double gravaM3;
  final double aguaLitros;

  const ResultadoMaterialesConcreto({
    required this.volumenM3,
    required this.bolsasCemento,
    required this.arenaM3,
    required this.gravaM3,
    required this.aguaLitros,
  });
}

/// Calcula cantidades de materiales para un volumen de concreto dado,
/// a partir de la tabla práctica [DosificacionConcreto.tabla].
class CalcularMaterialesConcreto {
  ResultadoMaterialesConcreto call({
    required double volumenM3,
    required DosificacionConcreto dosificacion,
  }) {
    return ResultadoMaterialesConcreto(
      volumenM3: volumenM3,
      bolsasCemento: dosificacion.bolsasCementoPorM3 * volumenM3,
      arenaM3: dosificacion.arenaM3PorM3 * volumenM3,
      gravaM3: dosificacion.gravaM3PorM3 * volumenM3,
      aguaLitros: dosificacion.aguaLitrosPorM3 * volumenM3,
    );
  }
}
