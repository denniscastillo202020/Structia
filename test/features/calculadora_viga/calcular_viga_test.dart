import 'package:flutter_test/flutter_test.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';
import 'package:structia/features/calculadora_viga/domain/calcular_viga.dart';

void main() {
  group('CalcularViga', () {
    test('calcula acero superior, inferior y estribos para una viga típica', () {
      const datos = DatosViga(
        anchoCm: 25,
        peralteCm: 40,
        luzM: 4.0,
        recubrimientoCm: 4,
        tipoApoyo: TipoApoyoViga.simplementeApoyada,
        diametroSuperior: DiametroVarilla.n5,
        cantidadVarillasSuperiores: 2,
        diametroInferior: DiametroVarilla.n5,
        cantidadVarillasInferiores: 3,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 15,
      );

      final resultado = CalcularViga()(datos);

      expect(resultado.cantidadEstribosPorViga, greaterThan(0));
      expect(resultado.aceroSuperior.pesoCompradoKg, greaterThan(0));
      expect(resultado.aceroInferior.pesoCompradoKg, greaterThan(0));
      expect(resultado.aceroInferior.pesoCompradoKg, greaterThan(resultado.aceroSuperior.pesoCompradoKg));
    });

    test('una luz mayor que la varilla comercial genera traslapes', () {
      const datos = DatosViga(
        anchoCm: 25,
        peralteCm: 40,
        luzM: 12.0,
        recubrimientoCm: 4,
        tipoApoyo: TipoApoyoViga.continua,
        diametroSuperior: DiametroVarilla.n5,
        cantidadVarillasSuperiores: 2,
        diametroInferior: DiametroVarilla.n5,
        cantidadVarillasInferiores: 2,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 15,
      );

      final resultado = CalcularViga()(datos);
      expect(resultado.aceroSuperior.traslapesNecesarios, greaterThan(0));
    });

    test('varias vigas iguales multiplican correctamente el material', () {
      const datosUna = DatosViga(
        anchoCm: 25,
        peralteCm: 40,
        luzM: 4.0,
        recubrimientoCm: 4,
        tipoApoyo: TipoApoyoViga.simplementeApoyada,
        diametroSuperior: DiametroVarilla.n5,
        cantidadVarillasSuperiores: 2,
        diametroInferior: DiametroVarilla.n5,
        cantidadVarillasInferiores: 3,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 15,
        cantidadVigas: 1,
      );
      const datosCinco = DatosViga(
        anchoCm: 25,
        peralteCm: 40,
        luzM: 4.0,
        recubrimientoCm: 4,
        tipoApoyo: TipoApoyoViga.simplementeApoyada,
        diametroSuperior: DiametroVarilla.n5,
        cantidadVarillasSuperiores: 2,
        diametroInferior: DiametroVarilla.n5,
        cantidadVarillasInferiores: 3,
        diametroEstribo: DiametroVarilla.n3,
        separacionEstribosCm: 15,
        cantidadVigas: 5,
      );

      final resultadoUna = CalcularViga()(datosUna);
      final resultadoCinco = CalcularViga()(datosCinco);

      expect(resultadoCinco.aceroInferior.pesoCompradoKg,
          greaterThan(resultadoUna.aceroInferior.pesoCompradoKg));
      expect(resultadoCinco.volumenConcretoM3, closeTo(resultadoUna.volumenConcretoM3 * 5, 0.0001));
    });
  });
}
