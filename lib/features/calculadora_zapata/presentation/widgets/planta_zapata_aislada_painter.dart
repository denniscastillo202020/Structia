import 'package:flutter/material.dart';
import 'package:structia/features/calculadora_zapata/domain/calcular_zapata.dart';

/// Dibuja la vista en planta de una zapata aislada: el contorno de
/// concreto y la malla (cama) de varillas en ambas direcciones.
class PlantaZapataAisladaPainter extends CustomPainter {
  final DatosZapataAislada datos;

  PlantaZapataAisladaPainter(this.datos);

  @override
  void paint(Canvas canvas, Size size) {
    final escala = _calcularEscala(size);
    final offset = _calcularOffset(size, escala);

    Offset punto(double xCm, double yCm) {
      return Offset(offset.dx + xCm * escala, offset.dy + yCm * escala);
    }

    final paintConcreto = Paint()
      ..color = const Color(0xFFE8E0D5)
      ..style = PaintingStyle.fill;
    final paintContorno = Paint()
      ..color = const Color(0xFF6D6255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromPoints(punto(0, 0), punto(datos.ladoXCm, datos.ladoYCm));
    canvas.drawRect(rect, paintConcreto);
    canvas.drawRect(rect, paintContorno);

    final paintBarraX = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 2.5;
    for (final y in datos.posicionesYBarrasX()) {
      canvas.drawLine(
        punto(datos.recubrimientoCm, y),
        punto(datos.ladoXCm - datos.recubrimientoCm, y),
        paintBarraX,
      );
    }

    final paintBarraY = Paint()
      ..color = const Color(0xFFFF6F00)
      ..strokeWidth = 2.5;
    for (final x in datos.posicionesXBarrasY()) {
      canvas.drawLine(
        punto(x, datos.recubrimientoCm),
        punto(x, datos.ladoYCm - datos.recubrimientoCm),
        paintBarraY,
      );
    }
  }

  double _calcularEscala(Size size) {
    const margenPx = 20.0;
    final escalaX = (size.width - margenPx * 2) / datos.ladoXCm;
    final escalaY = (size.height - margenPx * 2) / datos.ladoYCm;
    return escalaX < escalaY ? escalaX : escalaY;
  }

  Offset _calcularOffset(Size size, double escala) {
    final anchoDibujo = datos.ladoXCm * escala;
    final altoDibujo = datos.ladoYCm * escala;
    return Offset((size.width - anchoDibujo) / 2, (size.height - altoDibujo) / 2);
  }

  @override
  bool shouldRepaint(covariant PlantaZapataAisladaPainter oldDelegate) => true;
}
