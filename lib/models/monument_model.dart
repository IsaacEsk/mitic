import 'civilizacion_model.dart';

class MonumentField {
  String nombre;
  int vidaActual;
  int vidaMaxima; // Por si querés mostrar barra o límite
  String imagenPath;

  // Habilidad especial de la civilización (ya viene en Civilizacion, pero acá podrías tenerla)
  String habilidadId;

  MonumentField({
    required this.nombre,
    required this.vidaActual,
    required this.vidaMaxima,
    required this.imagenPath,
    required this.habilidadId,
  });

  // Para crear desde una Civilizacion
  factory MonumentField.fromCivilizacion(Civilizacion civ) {
    return MonumentField(
      nombre: civ.muralla.nombre,
      vidaActual: civ.muralla.vida,
      vidaMaxima: civ.muralla.vida,
      imagenPath: civ.muralla.imagen,
      habilidadId: civ.habilidadEspecialId,
    );
  }
}
