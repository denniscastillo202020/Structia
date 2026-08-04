/// Una fila editable (etiqueta/valor) de un cálculo detectado por OCR,
/// antes de que el usuario la confirme y se guarde.
class FilaBorrador {
  String etiqueta;
  String valor;

  FilaBorrador({required this.etiqueta, required this.valor});
}

/// Un cálculo reconstruido a partir de una captura de pantalla, pendiente
/// de revisión del usuario antes de guardarse como [CalculoGuardado].
class CalculoBorrador {
  String tipo;
  String titulo;
  String subtitulo;
  final List<FilaBorrador> filas;

  CalculoBorrador({
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.filas,
  });
}

/// Tipos válidos para el desplegable de corrección manual, en el mismo
/// orden/etiquetas que usa el resto de la app (ver `_IconoPorTipo`).
const kTiposCalculoGuardado = <String>[
  'Columna',
  'Viga',
  'Zapata',
  'Mampostería',
  'Presupuesto',
  'Acero',
  'Concreto',
];
