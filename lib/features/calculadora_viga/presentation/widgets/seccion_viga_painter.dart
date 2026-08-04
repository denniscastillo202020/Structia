import 'package:flutter/material.dart';
import 'package:structia/features/calculadora_viga/domain/calcular_viga.dart';

/// Dibuja el corte transversal de una viga: concreto, estribo,
/// varillas superiores e inferiores — para visualizar de un vistazo
/// cómo queda armada la sección.
class SeccionVigaPainter extends CustomPainter {
  final DatosViga datos;

  SeccionVigaPainter(this.datos);

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

    final rectConcreto = Rect.fromPoints(punto(0, 0), punto(datos.anchoCm, datos.peralteCm));
    canvas.drawRect(rectConcreto, paintConcreto);
    canvas.drawRect(rectConcreto, paintContorno);

    final paintEstribo = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final rectEstribo = Rect.fromPoints(
      punto(datos.recubrimientoCm, datos.recubrimientoCm),
      punto(datos.anchoCm - datos.recubrimientoCm, datos.peralteCm - datos.recubrimientoCm),
    );
    canvas.drawRect(rectEstribo, paintEstribo);

    final radioVarillaPx = (3.0 * escala).clamp(3.0, 14.0);

    final paintSuperior = Paint()..color = const Color(0xFFFF6F00);
    for (final pos in datos.posicionesVarillasSuperiores()) {
      canvas.drawCircle(punto(pos.xCm, pos.yCm), radioVarillaPx, paintSuperior);
    }

    final paintInferior = Paint()..color = const Color(0xFF1565C0);
    for (final pos in datos.posicionesVarillasInferiores()) {
      canvas.drawCircle(punto(pos.xCm, pos.yCm), radioVarillaPx, paintInferior);
    }
  }

  double _calcularEscala(Size size) {
    const margenPx = 24.0;
    final escalaX = (size.width - margenPx * 2) / datos.anchoCm;
    final escalaY = (size.height - margenPx * 2) / datos.peralteCm;
    return escalaX < escalaY ? escalaX : escalaY;
  }

  Offset _calcularOffset(Size size, double escala) {
    final anchoDibujo = datos.anchoCm * escala;
    final altoDibujo = datos.peralteCm * escala;
    return Offset(
      (size.width - anchoDibujo) / 2,
      (size.height - altoDibujo) / 2,
    );
  }

  @override
  bool shouldRepaint(covariant SeccionVigaPainter oldDelegate) => oldDelegate.datos != datos;
}
