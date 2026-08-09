/// Un proyecto de obra (ej. "Proyecto de Carol", "Casa Marvin - 2do
/// piso"). Agrupa los cálculos guardados para que no se mezclen los
/// materiales de una obra con los de otra.
class Proyecto {
  final String id;
  final String nombre;
  final DateTime fecha;

  const Proyecto({
    required this.id,
    required this.nombre,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'fecha': fecha.toIso8601String(),
      };

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }
}
