class Torre {
  final String id;
  final String civilizacionId;
  final String nombre;
  final int ataque;
  final int vida;
  final int costoInvocacion; // 👈 NUEVO
  final String imagen;

  Torre({
    required this.id,
    required this.civilizacionId,
    required this.nombre,
    required this.ataque,
    required this.vida,
    required this.costoInvocacion, // 👈 NUEVO
    required this.imagen,
  });

  factory Torre.fromJson(Map<String, dynamic> json) {
    return Torre(
      id: json['id'] as String,
      civilizacionId: json['civilizacion_id'] as String,
      nombre: json['nombre'] as String,
      ataque: json['ataque'] as int,
      vida: json['vida'] as int,
      costoInvocacion: json['costo_invocacion'] as int, // 👈 NUEVO
      imagen: json['imagen'] as String,
    );
  }

  Torre copyWith({
    String? id,
    String? civilizacionId,
    String? nombre,
    int? ataque,
    int? vida,
    int? costoInvocacion, // 👈 NUEVO
    String? imagen,
  }) {
    return Torre(
      id: id ?? this.id,
      civilizacionId: civilizacionId ?? this.civilizacionId,
      nombre: nombre ?? this.nombre,
      ataque: ataque ?? this.ataque,
      vida: vida ?? this.vida,
      costoInvocacion: costoInvocacion ?? this.costoInvocacion, // 👈 NUEVO
      imagen: imagen ?? this.imagen,
    );
  }
}
