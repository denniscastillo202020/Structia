/// Un cálculo guardado por el usuario: una columna, viga, zapata, etc.
/// ya calculada, que se conserva para armar el total del proyecto.
class CalculoGuardado {
  final String id;
  final String tipo; // 'Columna' | 'Viga' | 'Zapata' | 'Concreto' | 'Acero'
  final String titulo;
  final String subtitulo;
  final List<Map<String, String>> filas; // [{etiqueta, valor}] para mostrar
  final DateTime fecha;

  // Campos numéricos para poder sumar totales entre varios cálculos.
  final double? volumenConcretoM3;
  final double? bolsasCemento;
  final double? arenaM3;
  final double? gravaM3;
  final double? pesoAceroKg;
  final double? bloquesTotal;
  final double? morteroM3;
  final double? areaNetaM2;
  final double? volumenExcavacionM3;
  final double? volumenRellenoM3;
  // Área de muros con repello y con pulido, POR SEPARADO del área
  // total de bloques (areaNetaM2), porque no todas las paredes de un
  // muro llevan acabado — se necesitan aparte para conectar cada una
  // con su propia línea de mano de obra (Pega de bloque vs. Repello).
  final double? areaConRepelloM2;
  final double? areaConPulidoM2;

  const CalculoGuardado({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.filas,
    required this.fecha,
    this.volumenConcretoM3,
    this.bolsasCemento,
    this.arenaM3,
    this.gravaM3,
    this.pesoAceroKg,
    this.bloquesTotal,
    this.morteroM3,
    this.areaNetaM2,
    this.volumenExcavacionM3,
    this.volumenRellenoM3,
    this.areaConRepelloM2,
    this.areaConPulidoM2,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'titulo': titulo,
        'subtitulo': subtitulo,
        'filas': filas,
        'fecha': fecha.toIso8601String(),
        'volumenConcretoM3': volumenConcretoM3,
        'bolsasCemento': bolsasCemento,
        'arenaM3': arenaM3,
        'gravaM3': gravaM3,
        'pesoAceroKg': pesoAceroKg,
        'bloquesTotal': bloquesTotal,
        'morteroM3': morteroM3,
        'areaNetaM2': areaNetaM2,
        'volumenExcavacionM3': volumenExcavacionM3,
        'volumenRellenoM3': volumenRellenoM3,
        'areaConRepelloM2': areaConRepelloM2,
        'areaConPulidoM2': areaConPulidoM2,
      };

  factory CalculoGuardado.fromJson(Map<String, dynamic> json) {
    return CalculoGuardado(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      subtitulo: json['subtitulo'] as String,
      filas: (json['filas'] as List)
          .map((f) => Map<String, String>.from(f as Map))
          .toList(),
      fecha: DateTime.parse(json['fecha'] as String),
      volumenConcretoM3: (json['volumenConcretoM3'] as num?)?.toDouble(),
      bolsasCemento: (json['bolsasCemento'] as num?)?.toDouble(),
      arenaM3: (json['arenaM3'] as num?)?.toDouble(),
      gravaM3: (json['gravaM3'] as num?)?.toDouble(),
      pesoAceroKg: (json['pesoAceroKg'] as num?)?.toDouble(),
      bloquesTotal: (json['bloquesTotal'] as num?)?.toDouble(),
      morteroM3: (json['morteroM3'] as num?)?.toDouble(),
      areaNetaM2: (json['areaNetaM2'] as num?)?.toDouble(),
      volumenExcavacionM3: (json['volumenExcavacionM3'] as num?)?.toDouble(),
      volumenRellenoM3: (json['volumenRellenoM3'] as num?)?.toDouble(),
      areaConRepelloM2: (json['areaConRepelloM2'] as num?)?.toDouble(),
      areaConPulidoM2: (json['areaConPulidoM2'] as num?)?.toDouble(),
    );
  }
}
