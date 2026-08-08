/// Una actividad de mano de obra con su precio unitario de
/// referencia. Los precios son EDITABLES en la app — son un punto de
/// partida (tabla de referencia del usuario), no precios fijos: varían
/// por zona, temporada y cada contratista.
class ActividadManoDeObra {
  final String nombre;
  final double precioReferenciaL;
  final String unidad;

  const ActividadManoDeObra({
    required this.nombre,
    required this.precioReferenciaL,
    required this.unidad,
  });

  static const List<ActividadManoDeObra> tabla = [
    ActividadManoDeObra(nombre: 'Trazo y nivelación topográfica', precioReferenciaL: 50, unidad: 'm²'),
    ActividadManoDeObra(nombre: 'Excavación a mano', precioReferenciaL: 200, unidad: 'm³'),
    ActividadManoDeObra(nombre: 'Relleno', precioReferenciaL: 100, unidad: 'm³'),
    ActividadManoDeObra(nombre: 'Fundición de zapata', precioReferenciaL: 400, unidad: 'm lineal'),
    ActividadManoDeObra(nombre: 'Armado de hierro', precioReferenciaL: 30, unidad: 'kg'),
    ActividadManoDeObra(nombre: 'Pega de bloque (incl. instalación de manguera)', precioReferenciaL: 350, unidad: 'm²'),
    ActividadManoDeObra(nombre: 'Fundición de solera', precioReferenciaL: 350, unidad: 'm lineal'),
    ActividadManoDeObra(nombre: 'Fundición de castillo', precioReferenciaL: 350, unidad: 'm lineal'),
    ActividadManoDeObra(nombre: 'Fundición de firme', precioReferenciaL: 300, unidad: 'm²'),
    ActividadManoDeObra(nombre: 'Fundición de losa (tubo, lámina y malla)', precioReferenciaL: 450, unidad: 'm²'),
    ActividadManoDeObra(nombre: 'Repello/Tallado y pulido en boquetes', precioReferenciaL: 120, unidad: 'm lineal'),
    ActividadManoDeObra(nombre: 'Repello/Tallado y pulido general', precioReferenciaL: 150, unidad: 'm²'),
    ActividadManoDeObra(nombre: 'Solera de cierre', precioReferenciaL: 450, unidad: 'm lineal'),
    ActividadManoDeObra(nombre: 'Armado de estructura metálica e instalación de techo', precioReferenciaL: 800, unidad: 'm²'),
    ActividadManoDeObra(nombre: 'Pintura en paredes nuevas', precioReferenciaL: 80, unidad: 'm²'),
    ActividadManoDeObra(nombre: 'Instalaciones hidrosanitarias', precioReferenciaL: 80, unidad: 'm lineal'),
  ];
}
