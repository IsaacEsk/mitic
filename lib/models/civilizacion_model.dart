// Represents a civilization entry pulled from `assets/data/civilizaciones.json`.
//
// Only a subset of the JSON structure is modelled at the moment: the
// "muralla" object is the only part that is interesting to our simple
// monument card.  In the future additional fields such as
// `habilidadEspecialId` can be exposed here if needed.

class Civilizacion {
  final String id;
  final String nombreId;
  final Muralla muralla;
  final String habilidadEspecialId;

  Civilizacion({
    required this.id,
    required this.nombreId,
    required this.muralla,
    required this.habilidadEspecialId,
  });

  factory Civilizacion.fromJson(Map<String, dynamic> json) {
    return Civilizacion(
      id: json['id'] as String,
      nombreId: json['nombre_id'] as String,
      muralla: Muralla.fromJson(json['muralla'] as Map<String, dynamic>),
      habilidadEspecialId: json['habilidad_especial_id'] as String,
    );
  }
}

/// Sub‑object that describes the monument/wall for the civilisation.
class Muralla {
  final String nombreId;
  final int vida;
  final String imagen;
  final String descripcionId;

  Muralla({
    required this.nombreId,
    required this.vida,
    required this.imagen,
    required this.descripcionId,
  });

  factory Muralla.fromJson(Map<String, dynamic> json) {
    var imagenPath = json['imagen'] as String;
    // if (imagenPath.startsWith('assets/')) {
    //   // keep path relative to `Image.asset` convention (no leading slash)
    //   imagenPath = imagenPath.substring(7);
    // }
    return Muralla(
      nombreId: json['nombre_id'] as String,
      vida: json['vida'] as int,
      imagen: imagenPath,
      descripcionId: json['descripcion_id'] as String,
    );
  }
}
