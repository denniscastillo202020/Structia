import 'package:flutter_test/flutter_test.dart';
import 'package:structia/features/calculadora_mamposteria/domain/calcular_mamposteria.dart';

void main() {
  group('CalcularMamposteria', () {
    final calcular = CalcularMamposteria();
    const bloque40x20x15 = TipoBloque(etiqueta: 'test', largoCm: 40, altoCm: 20, espesorCm: 15);
    final mortero14 = DosificacionMortero.tabla.firstWhere((d) => d.proporcion == '1 : 4');

    test('resta correctamente el área de vanos del área bruta', () {
      final resultado = calcular(
        paredes: [const Pared(id: 'p1', etiqueta: 'Pared 1', largoM: 5, altoM: 2.4)],
        vanos: [const Vano(id: 'v1', etiqueta: 'Puerta 1', anchoM: 1, altoM: 2.1)],
        tipoBloque: bloque40x20x15,
        espesorJuntaCm: 1.5,
        porcentajeDesperdicio: 5,
        dosificacionMortero: mortero14,
      );

      expect(resultado.areaBrutaM2, closeTo(12.0, 0.001));
      expect(resultado.areaVanosM2, closeTo(2.1, 0.001));
      expect(resultado.areaNetaM2, closeTo(9.9, 0.001));
    });

    test('el área neta nunca es negativa aunque los vanos superen la pared', () {
      final resultado = calcular(
        paredes: [const Pared(id: 'p1', etiqueta: 'Pared 1', largoM: 1, altoM: 1)],
        vanos: [const Vano(id: 'v1', etiqueta: 'Ventana 1', anchoM: 2, altoM: 2)],
        tipoBloque: bloque40x20x15,
        espesorJuntaCm: 1.5,
        porcentajeDesperdicio: 5,
        dosificacionMortero: mortero14,
      );

      expect(resultado.areaNetaM2, 0.0);
      expect(resultado.bloquesNetos, 0.0);
    });

    test('el desperdicio se reporta separado del bloque usable, nunca mezclado', () {
      final resultado = calcular(
        paredes: [const Pared(id: 'p1', etiqueta: 'Pared 1', largoM: 10, altoM: 2.4)],
        vanos: [],
        tipoBloque: bloque40x20x15,
        espesorJuntaCm: 1.5,
        porcentajeDesperdicio: 10,
        dosificacionMortero: mortero14,
      );

      expect(resultado.bloquesDesperdicio, closeTo(resultado.bloquesNetos * 0.10, 0.001));
      // El total mostrado es la suma de los dos valores YA redondeados
      // hacia arriba (lo que ve el usuario en pantalla), para que
      // "neto + desperdicio" cuadre siempre con "total a comprar".
      expect(
        resultado.bloquesTotalComprar,
        resultado.bloquesNetos.ceil() + resultado.bloquesDesperdicio.ceil(),
      );
      // El neto y el desperdicio deben quedar disponibles como cifras
      // independientes (no una sola cifra fusionada).
      expect(resultado.bloquesNetos, isNot(equals(resultado.bloquesTotalComprar)));
    });

    test('a mayor junta, más mortero y menos bloques por m²', () {
      final resultadoJuntaFina = calcular(
        paredes: [const Pared(id: 'p1', etiqueta: 'Pared 1', largoM: 10, altoM: 2.4)],
        vanos: [],
        tipoBloque: bloque40x20x15,
        espesorJuntaCm: 1.0,
        porcentajeDesperdicio: 5,
        dosificacionMortero: mortero14,
      );
      final resultadoJuntaGruesa = calcular(
        paredes: [const Pared(id: 'p1', etiqueta: 'Pared 1', largoM: 10, altoM: 2.4)],
        vanos: [],
        tipoBloque: bloque40x20x15,
        espesorJuntaCm: 2.0,
        porcentajeDesperdicio: 5,
        dosificacionMortero: mortero14,
      );

      expect(resultadoJuntaGruesa.bloquesPorM2, lessThan(resultadoJuntaFina.bloquesPorM2));
      expect(resultadoJuntaGruesa.morteroNetoM3, greaterThan(resultadoJuntaFina.morteroNetoM3));
    });

    test('el volumen de mortero total incluye el neto más el desperdicio', () {
      final resultado = calcular(
        paredes: [const Pared(id: 'p1', etiqueta: 'Pared 1', largoM: 10, altoM: 2.4)],
        vanos: [],
        tipoBloque: bloque40x20x15,
        espesorJuntaCm: 1.5,
        porcentajeDesperdicio: 8,
        dosificacionMortero: mortero14,
      );

      expect(
        resultado.morteroTotalM3,
        closeTo(resultado.morteroNetoM3 + resultado.morteroDesperdicioM3, 0.0001),
      );
      expect(resultado.sacosCementoMortero,
          closeTo(resultado.morteroTotalM3 * mortero14.bolsasCementoPorM3, 0.0001));
    });

    test('varias paredes se suman correctamente', () {
      final resultado = calcular(
        paredes: [
          const Pared(id: 'p1', etiqueta: 'Pared 1', largoM: 5, altoM: 2.4),
          const Pared(id: 'p2', etiqueta: 'Pared 2', largoM: 3, altoM: 2.4),
        ],
        vanos: [],
        tipoBloque: bloque40x20x15,
        espesorJuntaCm: 1.5,
        porcentajeDesperdicio: 5,
        dosificacionMortero: mortero14,
      );

      expect(resultado.areaBrutaM2, closeTo(19.2, 0.001));
    });
  });
}
