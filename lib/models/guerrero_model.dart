/// Represents a warrior character defined in our JSON assets.
///
/// The fields mirror the structure of the entries under
/// `assets/data/personajes.json`.  Localization keys like
/// `nombreId` and `descripcionId` are retained so that the
/// UI widgets can look up the actual strings in a translation map
/// (e.g. loaded from `assets/data/es.json`).
class Guerrero {
  final String id;
  final String nombreId;
  final String descripcionId;
  final String civilizacionId;
  final int ataque;
  final int vida;
  final int costoInvocacion;
  final String imagen;

  Guerrero({
    required this.id,
    required this.nombreId,
    required this.descripcionId,
    required this.civilizacionId,
    required this.ataque,
    required this.vida,
    required this.costoInvocacion,
    required this.imagen,
  });

  factory Guerrero.fromJson(Map<String, dynamic> json) {
    // Remove 'assets/' prefix if present, since Image.asset() adds it automatically
    var imagenPath = json['imagen'] as String;
    if (imagenPath.startsWith('assets/')) {
      imagenPath = imagenPath.substring(7); // remove 'assets/' prefix
    }

    return Guerrero(
      id: json['id'] as String,
      nombreId: json['nombre_id'] as String,
      descripcionId: json['descripcion_id'] as String,
      civilizacionId: json['civilizacion_id'] as String,
      ataque: json['ataque'] as int,
      vida: json['vida'] as int,
      costoInvocacion: json['costo_invocacion'] as int,
      imagen: imagenPath,
    );
  }

  /// Returns the localized name using [translations] map; falls
  /// back to the key if not present.
  String nombre(Map<String, String> translations) {
    return translations[nombreId] ?? nombreId;
  }

  /// Same as [nombre] but for the description key.
  String descripcion(Map<String, String> translations) {
    return translations[descripcionId] ?? descripcionId;
  }
}
