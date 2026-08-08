import 'borrador_calculo.dart';
import 'linea_ocr.dart';

/// Prefijos con los que la app arma el título de cada tipo de cálculo al
/// tocar "Guardar en mi proyecto" (ver cada `_guardar...` en las
/// calculadoras). Se usan para detectar dónde empieza cada tarjeta dentro
/// de una captura y para adivinar el `tipo`.
const _prefijosTipo = <String, String>{
  'zapata aislada': 'Zapata',
  'zapata corrida': 'Zapata',
  'zapata': 'Zapata',
  'columna': 'Columna',
  'viga': 'Viga',
  'muros': 'Mampostería',
  'presupuesto': 'Presupuesto',
  'acero': 'Acero',
  'materiales de concreto': 'Concreto',
  'concreto': 'Concreto',
};

/// Líneas que casi siempre son ruido de la interfaz (hora, batería, señal,
/// título de la pantalla, flecha de volver) y no aportan datos.
final _lineasRuido = RegExp(
  r'^(mis c[aá]lculos guardados|muros y bloques|columnas|vigas|zapatas|'
  r'costos y mano de obra|acero de refuerzo|[0-9]{1,2}:[0-9]{2}( ?[ap]\.?m\.?)?|'
  r'[0-9]{1,3} ?%|wifi|←|<)$',
  caseSensitive: false,
);

String? _tipoDesdeTitulo(String linea) {
  final texto = linea.trim().toLowerCase();
  for (final entrada in _prefijosTipo.entries) {
    if (texto.startsWith(entrada.key)) return entrada.value;
  }
  return null;
}

/// El mayor salto horizontal entre elementos consecutivos de una línea:
/// casi siempre es la frontera entre la etiqueta (izquierda) y el valor
/// (derecha), porque así se dibuja cada fila en la app
/// (`Expanded(etiqueta)` + valor pegado a la derecha).
int? _indiceCorte(LineaOcr linea) {
  if (linea.elementos.length < 2) return null;
  final anchoPromedio = linea.elementos
          .map((e) => e.right - e.left)
          .fold(0.0, (a, b) => a + b) /
      linea.elementos.length;
  var mejorIndice = -1;
  var mejorHueco = anchoPromedio * 1.6; // umbral mínimo para contar como "salto"
  for (var i = 0; i < linea.elementos.length - 1; i++) {
    final hueco = linea.elementos[i + 1].left - linea.elementos[i].right;
    if (hueco > mejorHueco) {
      mejorHueco = hueco;
      mejorIndice = i;
    }
  }
  return mejorIndice == -1 ? null : mejorIndice;
}

bool _pareceFila(LineaOcr linea) {
  if (_indiceCorte(linea) != null) return true;
  final texto = linea.texto.trim();
  // Fallback para cuando el OCR no da posiciones útiles: algo que termine
  // en número/unidad reconocible (m³, m², cm, kg, %, sacos, unidad...).
  return RegExp(r'\d').hasMatch(texto) &&
      RegExp(r'(m³|m²|cm|kg|sacos|unidad|bloques|%|m\)?$|\d$)', caseSensitive: false)
          .hasMatch(texto);
}

FilaBorrador _dividirFila(LineaOcr linea) {
  final corte = _indiceCorte(linea);
  if (corte != null) {
    final etiqueta = linea.elementos.sublist(0, corte + 1).map((e) => e.texto).join(' ').trim();
    final valor = linea.elementos.sublist(corte + 1).map((e) => e.texto).join(' ').trim();
    if (etiqueta.isNotEmpty && valor.isNotEmpty) {
      return FilaBorrador(etiqueta: etiqueta, valor: valor);
    }
  }
  // Fallback por regex: etiqueta = texto hasta donde empieza el primer
  // tramo que arranca con dígito, seguido de espacio.
  final match = RegExp(r'^(.*?)\s+([\d].*)$').firstMatch(linea.texto.trim());
  if (match != null) {
    return FilaBorrador(etiqueta: match.group(1)!.trim(), valor: match.group(2)!.trim());
  }
  return FilaBorrador(etiqueta: linea.texto.trim(), valor: '');
}

/// Punto de entrada: recibe las líneas ya agrupadas por posición (una
/// captura puede traer varios cálculos guardados uno debajo del otro) y
/// devuelve un borrador editable por cada uno que logró reconocer.
List<CalculoBorrador> extraerCalculosDeTexto(List<LineaOcr> lineas) {
  final relevantes = lineas
      .where((l) => l.texto.trim().isNotEmpty && !_lineasRuido.hasMatch(l.texto.trim()))
      .toList();

  final inicios = <int>[];
  final tipos = <String>[];
  for (var i = 0; i < relevantes.length; i++) {
    final tipo = _tipoDesdeTitulo(relevantes[i].texto);
    if (tipo != null) {
      inicios.add(i);
      tipos.add(tipo);
    }
  }
  if (inicios.isEmpty) return [];

  final resultado = <CalculoBorrador>[];
  for (var c = 0; c < inicios.length; c++) {
    final inicio = inicios[c];
    final fin = c + 1 < inicios.length ? inicios[c + 1] : relevantes.length;
    final bloque = relevantes.sublist(inicio, fin);
    final titulo = bloque.first.texto.trim();

    var cursor = 1;
    final subtituloPartes = <String>[];
    while (cursor < bloque.length && !_pareceFila(bloque[cursor])) {
      subtituloPartes.add(bloque[cursor].texto.trim());
      cursor++;
    }

    final filas = <FilaBorrador>[];
    for (; cursor < bloque.length; cursor++) {
      final fila = _dividirFila(bloque[cursor]);
      if (fila.etiqueta.isNotEmpty) filas.add(fila);
    }

    resultado.add(CalculoBorrador(
      tipo: tipos[c],
      titulo: titulo,
      subtitulo: subtituloPartes.join(' · '),
      filas: filas,
    ));
  }
  return resultado;
}

/// Campos numéricos que la app usa para sumar totales entre varios
/// cálculos guardados (ver `CalculoGuardado` y la pantalla de "Mis
/// cálculos guardados").
class CamposNumericosCalculo {
  final double? volumenConcretoM3;
  final double? bolsasCemento;
  final double? arenaM3;
  final double? gravaM3;
  final double? pesoAceroKg;
  final double? bloquesTotal;
  final double? morteroM3;
  final double? areaNetaM2;

  const CamposNumericosCalculo({
    this.volumenConcretoM3,
    this.bolsasCemento,
    this.arenaM3,
    this.gravaM3,
    this.pesoAceroKg,
    this.bloquesTotal,
    this.morteroM3,
    this.areaNetaM2,
  });
}

double? _primerNumero(String valor) {
  final limpio = valor.replaceAll(',', '');
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(limpio);
  if (match == null) return null;
  return double.tryParse(match.group(0)!);
}

/// Deriva los totales numéricos a partir de las filas etiqueta/valor ya
/// revisadas por el usuario, buscando las etiquetas conocidas que usa cada
/// calculadora. Es una heurística "mejor esfuerzo": si no reconoce una
/// etiqueta, simplemente no aporta a ese total (el usuario puede corregirlo
/// a mano en "Mis cálculos guardados" si hace falta).
CamposNumericosCalculo camposNumericosDesde(List<FilaBorrador> filas) {
  double? volumenConcretoM3, bolsasCemento, arenaM3, gravaM3, bloquesTotal, morteroM3, areaNetaM2;
  double pesoAceroKg = 0;
  var huboPeso = false;

  for (final f in filas) {
    final etiqueta = f.etiqueta.trim().toLowerCase();
    final numero = _primerNumero(f.valor);
    if (numero == null) continue;

    if (etiqueta == 'volumen de concreto') {
      volumenConcretoM3 = numero;
    } else if (etiqueta.startsWith('cemento')) {
      bolsasCemento = numero;
    } else if (etiqueta == 'arena') {
      arenaM3 = numero;
    } else if (etiqueta == 'grava' || etiqueta.startsWith('grava')) {
      gravaM3 = numero;
    } else if (etiqueta.contains('peso') && f.valor.toLowerCase().contains('kg')) {
      pesoAceroKg += numero;
      huboPeso = true;
    } else if (etiqueta == 'bloque total a comprar' || etiqueta == 'total a comprar') {
      bloquesTotal = numero;
    } else if (etiqueta.startsWith('mortero total') || etiqueta.startsWith('total (')) {
      morteroM3 = numero;
    } else if (etiqueta.startsWith('área neta') || etiqueta.startsWith('area neta')) {
      areaNetaM2 = numero;
    }
  }

  return CamposNumericosCalculo(
    volumenConcretoM3: volumenConcretoM3,
    bolsasCemento: bolsasCemento,
    arenaM3: arenaM3,
    gravaM3: gravaM3,
    pesoAceroKg: huboPeso ? pesoAceroKg : null,
    bloquesTotal: bloquesTotal,
    morteroM3: morteroM3,
    areaNetaM2: areaNetaM2,
  );
}
