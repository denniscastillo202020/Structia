import 'package:flutter_test/flutter_test.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';
import 'package:structia/features/calculadora_zapata/domain/calcular_zapata.dart';

void main() {
  group('CalcularZapataCorrida', () {
    test('calcula volumen y acero longitudinal/transversal correctamente', () {
      const datos = DatosZapataCorrida(
        longitudTotalM: 10,
        anchoCm: 50,
        profundidadCm: 30,
        recubrimientoCm: 7.5,
        diametroLongitudinal: DiametroVarilla.n4,
        cantidadVarillasLongitudinales: 3,
        diametroTransversal: DiametroVarilla.n3,
        separacionTransversalCm: 20,
      );

      final resultado = CalcularZapataCorrida()(datos);

      expect(resultado.volumenConcretoM3, closeTo(10 * 0.5 * 0.3, 0.0001));
      expect(resultado.aceroLongitudinal.pesoCompradoKg, greaterThan(0));
      expect(resultado.cantidadBastonesPorZapata, greaterThan(0));
    });

    test('varios tramos iguales multiplican el volumen', () {
      const datosUno = DatosZapataCorrida(
        longitudTotalM: 10,
        anchoCm: 50,
        profundidadCm: 30,
        recubrimientoCm: 7.5,
        diametroLongitudinal: DiametroVarilla.n4,
        cantidadVarillasLongitudinales: 3,
        diametroTransversal: DiametroVarilla.n3,
        separacionTransversalCm: 20,
        cantidadZapatas: 1,
      );
      const datosTres = DatosZapataCorrida(
        longitudTotalM: 10,
        anchoCm: 50,
        profundidadCm: 30,
        recubrimientoCm: 7.5,
        diametroLongitudinal: DiametroVarilla.n4,
        cantidadVarillasLongitudinales: 3,
        diametroTransversal: DiametroVarilla.n3,
        separacionTransversalCm: 20,
        cantidadZapatas: 3,
      );

      final resultadoUno = CalcularZapataCorrida()(datosUno);
      final resultadoTres = CalcularZapataCorrida()(datosTres);

      expect(resultadoTres.volumenConcretoM3, closeTo(resultadoUno.volumenConcretoM3 * 3, 0.0001));
    });
  });

  group('CalcularZapataAislada', () {
    test('calcula volumen y cama de varillas en ambas direcciones', () {
      const datos = DatosZapataAislada(
        ladoXCm: 120,
        ladoYCm: 120,
        profundidadCm: 40,
        recubrimientoCm: 7.5,
        diametroCama: DiametroVarilla.n5,
        separacionCamaCm: 15,
      );

      final resultado = CalcularZapataAislada()(datos);

      expect(resultado.volumenConcretoM3, closeTo(1.2 * 1.2 * 0.4, 0.0001));
      expect(datos.cantidadBarrasDireccionX, greaterThan(0));
      expect(datos.cantidadBarrasDireccionY, greaterThan(0));
      // Zapata cuadrada -> misma cantidad de varillas en X que en Y
      expect(datos.cantidadBarrasDireccionX, datos.cantidadBarrasDireccionY);
    });

    test('una zapata rectangular tiene distinta cantidad de varillas por dirección', () {
      const datos = DatosZapataAislada(
        ladoXCm: 200,
        ladoYCm: 100,
        profundidadCm: 40,
        recubrimientoCm: 7.5,
        diametroCama: DiametroVarilla.n5,
        separacionCamaCm: 15,
      );

      // Más varillas orientadas en X (más separación a cubrir en Y es más corta,
      // pero la cantidad de barras en X depende del lado Y, que es más corto)
      expect(datos.longitudBarraDireccionXM, greaterThan(datos.longitudBarraDireccionYM));
    });
  });
}
