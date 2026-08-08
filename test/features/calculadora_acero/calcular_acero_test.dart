import 'package:flutter_test/flutter_test.dart';
import 'package:structia/features/calculadora_acero/domain/calcular_acero.dart';

void main() {
  group('CalcularAcero — casos simples (sin traslape)', () {
    final calcular = CalcularAcero();

    test('una sola pieza que cabe en una varilla comercial usa solo 1 varilla', () {
      final resultado = calcular(
        tramos: [const TramoRequerido(longitudM: 3.0, cantidad: 1)],
        diametro: DiametroVarilla.n4,
        longitudComercialM: 9.0,
      );

      expect(resultado.varillasComercialesNecesarias, 1);
      expect(resultado.traslapesNecesarios, 0);
      expect(resultado.desperdicioTotalM, closeTo(6.0, 0.001));
    });

    test('cada pieza consume SU PROPIA varilla, aunque varias cabrían juntas', () {
      // Así se compra en obra: 3 piezas de 3m = 3 varillas completas
      // (una por pieza), NO 1 varilla combinando los 3 cortes.
      final resultado = calcular(
        tramos: [const TramoRequerido(longitudM: 3.0, cantidad: 3)],
        diametro: DiametroVarilla.n4,
        longitudComercialM: 9.0,
      );

      expect(resultado.varillasComercialesNecesarias, 3);
      expect(resultado.desperdicioTotalM, closeTo(18.0, 0.001)); // 3 x 6m de retazo
    });
  });

  group('CalcularAcero — tramos más largos que la varilla comercial (con traslape)', () {
    final calcular = CalcularAcero();

    test('un tramo de 13 m con varilla de 9 m necesita exactamente 1 traslape', () {
      final resultado = calcular(
        tramos: [const TramoRequerido(longitudM: 13.0, cantidad: 1)],
        diametro: DiametroVarilla.n4,
        longitudComercialM: 9.0,
        longitudTraslapeM: 1.0,
      );

      // Segmentos esperados: 9 m (varilla completa) + 5 m (4 restantes + 1 de traslape)
      expect(resultado.traslapesNecesarios, 1);
      expect(resultado.longitudUtilTotalM, closeTo(13.0, 0.001));
      // Material realmente comprado/cortado = 13 + 1 traslape = 14 m -> cabe en 2 varillas de 9 m
      expect(resultado.varillasComercialesNecesarias, 2);
    });

    test('el peso comprado incluye el material extra del traslape', () {
      final resultadoSinTraslape = calcular(
        tramos: [const TramoRequerido(longitudM: 8.9, cantidad: 1)],
        diametro: DiametroVarilla.n4,
        longitudComercialM: 9.0,
      );
      final resultadoConTraslape = calcular(
        tramos: [const TramoRequerido(longitudM: 13.0, cantidad: 1)],
        diametro: DiametroVarilla.n4,
        longitudComercialM: 9.0,
        longitudTraslapeM: 1.0,
      );

      // 13 m con traslape debe pesar más que solo 13 m de acero "ideal" sin traslape
      final pesoIdealSinTraslape = 13.0 * DiametroVarilla.n4.kgPorMetro;
      expect(resultadoConTraslape.pesoCompradoKg, greaterThan(pesoIdealSinTraslape));
      expect(resultadoSinTraslape.traslapesNecesarios, 0);
    });

    test('usa la longitud de traslape sugerida (40 diámetros) si no se especifica una', () {
      final resultado = calcular(
        tramos: [const TramoRequerido(longitudM: 15.0, cantidad: 1)],
        diametro: DiametroVarilla.n4,
        longitudComercialM: 9.0,
      );

      expect(resultado.longitudTraslapeM, closeTo(DiametroVarilla.n4.traslapeSugeridoM, 0.001));
      expect(resultado.traslapesNecesarios, greaterThanOrEqualTo(1));
    });

    test('el retazo de un traslape NO se reutiliza para otras piezas separadas', () {
      // Un tramo de 13m necesita 2 varillas (9m + 5m con traslape).
      // El tramo de 3m es una pieza aparte: consume SU PROPIA varilla,
      // sin importar que sobre espacio en la varilla del traslape.
      final resultado = calcular(
        tramos: [
          const TramoRequerido(longitudM: 13.0, cantidad: 1),
          const TramoRequerido(longitudM: 3.0, cantidad: 1),
        ],
        diametro: DiametroVarilla.n4,
        longitudComercialM: 9.0,
        longitudTraslapeM: 1.0,
      );

      // 2 varillas para el tramo de 13m + 1 varilla dedicada para el de 3m = 3.
      expect(resultado.varillasComercialesNecesarias, 3);
    });
  });
}
