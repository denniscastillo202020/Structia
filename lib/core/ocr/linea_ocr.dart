/// Una palabra/elemento reconocido por OCR, con su posición horizontal
/// dentro de la imagen. Solo lo necesario para reconstruir columnas
/// (etiqueta/valor) sin depender del paquete de ML Kit.
class ElementoOcr {
  final String texto;
  final double left;
  final double right;

  const ElementoOcr({required this.texto, required this.left, required this.right});
}

/// Una fila de texto ya agrupada por posición vertical (todas las palabras
/// que quedaron a la misma altura en la captura), ordenada de izquierda a
/// derecha.
class LineaOcr {
  final String texto;
  final List<ElementoOcr> elementos;

  const LineaOcr({required this.texto, required this.elementos});
}
