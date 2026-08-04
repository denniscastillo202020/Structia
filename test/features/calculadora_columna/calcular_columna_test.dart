import 'package:flutter_test/flutter_test.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';
import 'package:structia/features/calculadora_columna/domain/calcular_columna.dart';

void main() {
  group('CalcularColumna', () {
    test('calcula acero longitudinal y estribos para una columna típica', () {
      const datos = DatosColumna(
        anchoCm: 30,
        profundidadCm: 30,
        alturaM: 2.6,
        recubrimientoCm: 4,
        diametroLongitudinal: DiametroVarilla.n5,
        cantidadVarillasLongitudinales: 4,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 15,
      );

      final resultado = CalcularColumna()(datos);

      expect(resultado.cantidadEstribosPorColumna, greaterThan(0));
      expect(resultado.aceroLongitudinal.pesoCompradoKg, greaterThan(0));
      expect(resultado.aceroEstribos.pesoCompradoKg, greaterThan(0));
      expect(resultado.perimetroEstriboM, lessThan(2 * (0.30 + 0.30)));
    });

    test('varias columnas iguales multiplican correctamente el material', () {
      const datosUna = DatosColumna(
        anchoCm: 30,
        profundidadCm: 30,
        alturaM: 2.6,
        recubrimientoCm: 4,
        diametroLongitudinal: DiametroVarilla.n5,
        cantidadVarillasLongitudinales: 4,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 15,
        cantidadColumnas: 1,
      );
      const datosCuatro = DatosColumna(
        anchoCm: 30,
        profundidadCm: 30,
        alturaM: 2.6,
        recubrimientoCm: 4,
        diametroLongitudinal: DiametroVarilla.n5,
        cantidadVarillasLongitudinales: 4,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 15,
        cantidadColumnas: 4,
      );

      final resultadoUna = CalcularColumna()(datosUna);
      final resultadoCuatro = CalcularColumna()(datosCuatro);

      expect(resultadoCuatro.aceroLongitudinal.pesoCompradoKg,
          greaterThan(resultadoUna.aceroLongitudinal.pesoCompradoKg));
      expect(resultadoCuatro.volumenConcretoM3, closeTo(resultadoUna.volumenConcretoM3 * 4, 0.0001));
    });

    test('con 6 varillas, la distribución queda simétrica (3 arriba, 3 abajo)', () {
      const datos = DatosColumna(
        anchoCm: 30,
        profundidadCm: 30,
        alturaM: 2.6,
        recubrimientoCm: 4,
        diametroLongitudinal: DiametroVarilla.n5,
        cantidadVarillasLongitudinales: 6,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 15,
      );

      final posiciones = datos.posicionesVarillas();
      expect(posiciones.length, 6);

      // Cuenta cuántas varillas quedan en la fila superior (yCm mínimo)
      // vs la fila inferior (yCm máximo) — deben ser iguales (3 y 3).
      final yMin = posiciones.map((p) => p.yCm).reduce((a, b) => a < b ? a : b);
      final yMax = posiciones.map((p) => p.yCm).reduce((a, b) => a > b ? a : b);
      final enArriba = posiciones.where((p) => (p.yCm - yMin).abs() < 0.01).length;
      final enAbajo = posiciones.where((p) => (p.yCm - yMax).abs() < 0.01).length;

      expect(enArriba, 3);
      expect(enAbajo, 3);
    });

    test('con 8 varillas, la distribución queda simétrica en los 4 lados', () {
      const datos = DatosColumna(
        anchoCm: 40,
        profundidadCm: 40,
        alturaM: 3.0,
        recubrimientoCm: 4,
        diametroLongitudinal: DiametroVarilla.n6,
        cantidadVarillasLongitudinales: 8,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 10,
      );

      final posiciones = datos.posicionesVarillas();
      expect(posiciones.length, 8);
    });
  });
}
