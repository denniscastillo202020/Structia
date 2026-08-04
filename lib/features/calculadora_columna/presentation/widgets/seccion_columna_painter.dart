import 'package:flutter/material.dart';
import 'package:structia/features/calculadora_columna/domain/calcular_columna.dart';

/// Dibuja el corte transversal de una columna: contorno de concreto,
/// estribo y varillas longitudinales — para que se entienda de un
/// vistazo cómo queda armada, no como detalle de taller.
class SeccionColumnaPainter extends CustomPainter {
  final DatosColumna datos;

  SeccionColumnaPainter(this.datos);

  @override
  void paint(Canvas canvas, Size size) {
    final escala = _calcularEscala(size);
    final offset = _calcularOffset(size, escala);

    Offset punto(double xCm, double yCm) {
      return Offset(offset.dx + xCm * escala, offset.dy + yCm * escala);
    }

    // Concreto (contorno exterior)
    final paintConcreto = Paint()
      ..color = const Color(0xFFE8E0D5)
      ..style = PaintingStyle.fill;
    final paintContorno = Paint()
      ..color = const Color(0xFF6D6255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rectConcreto = Rect.fromPoints(punto(0, 0), punto(datos.anchoCm, datos.profundidadCm));
    canvas.drawRect(rectConcreto, paintConcreto);
    canvas.drawRect(rectConcreto, paintContorno);

    // Estribo (línea interior, a la distancia del recubrimiento)
    final paintEstribo = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final rectEstribo = Rect.fromPoints(
      punto(datos.recubrimientoCm, datos.recubrimientoCm),
      punto(datos.anchoCm - datos.recubrimientoCm, datos.profundidadCm - datos.recubrimientoCm),
    );
    canvas.drawRect(rectEstribo, paintEstribo);

    // Varillas longitudinales (círculos)
    final paintVarilla = Paint()..color = const Color(0xFF1565C0);
    final paintVarillaBorde = Paint()
      ..color = const Color(0xFF0D3E73)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final radioVarillaPx = (3.0 * escala).clamp(3.0, 14.0);
    for (final pos in datos.posicionesVarillas()) {
      final centro = punto(pos.xCm, pos.yCm);
      canvas.drawCircle(centro, radioVarillaPx, paintVarilla);
      canvas.drawCircle(centro, radioVarillaPx, paintVarillaBorde);
    }
  }

  double _calcularEscala(Size size) {
    const margenPx = 24.0;
    final escalaX = (size.width - margenPx * 2) / datos.anchoCm;
    final escalaY = (size.height - margenPx * 2) / datos.profundidadCm;
    return escalaX < escalaY ? escalaX : escalaY;
  }

  Offset _calcularOffset(Size size, double escala) {
    final anchoDibujo = datos.anchoCm * escala;
    final altoDibujo = datos.profundidadCm * escala;
    return Offset(
      (size.width - anchoDibujo) / 2,
      (size.height - altoDibujo) / 2,
    );
  }

  @override
  bool shouldRepaint(covariant SeccionColumnaPainter oldDelegate) => oldDelegate.datos != datos;
}
