import 'package:flutter_test/flutter_test.dart';
import 'package:structia/features/calculadora_concreto/domain/calcular_materiales_concreto.dart';

void main() {
  group('CalcularMaterialesConcreto', () {
    final calcular = CalcularMaterialesConcreto();
    final dosificacion210 = DosificacionConcreto.tabla.firstWhere((d) => d.fc == 210);

    test('para 1 m³ devuelve exactamente los valores de la tabla (f\'c=210)', () {
      final resultado = calcular(volumenM3: 1.0, dosificacion: dosificacion210);

      expect(resultado.bolsasCemento, closeTo(8.20, 0.001));
      expect(resultado.arenaM3, closeTo(0.52, 0.001));
      expect(resultado.gravaM3, closeTo(0.53, 0.001));
      expect(resultado.aguaLitros, closeTo(186, 0.001));
    });

    test('el volumen es proporcional: el doble de volumen duplica los materiales', () {
      final resultado1 = calcular(volumenM3: 1.0, dosificacion: dosificacion210);
      final resultado2 = calcular(volumenM3: 2.0, dosificacion: dosificacion210);

      expect(resultado2.bolsasCemento, closeTo(resultado1.bolsasCemento * 2, 0.01));
      expect(resultado2.arenaM3, closeTo(resultado1.arenaM3 * 2, 0.01));
    });

    test('una mezcla de mayor resistencia (f\'c mayor) usa más cemento por m³', () {
      final d150 = DosificacionConcreto.tabla.firstWhere((d) => d.fc == 150);
      final d300 = DosificacionConcreto.tabla.firstWhere((d) => d.fc == 300);

      final resultado150 = calcular(volumenM3: 1.0, dosificacion: d150);
      final resultado300 = calcular(volumenM3: 1.0, dosificacion: d300);

      expect(resultado300.bolsasCemento, greaterThan(resultado150.bolsasCemento));
    });

    test('la tabla incluye las cinco resistencias estándar', () {
      final resistencias = DosificacionConcreto.tabla.map((d) => d.fc).toList();
      expect(resistencias, containsAll([150, 180, 210, 250, 300]));
    });
  });
}
