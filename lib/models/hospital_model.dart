class Hospital {
  final String id;
  final String civilizacionId;
  final String nombre;
  final int vida;
  final int poderCuracion;
  final int costoInvocacion;
  final String imagen;

  Hospital({
    required this.id,
    required this.civilizacionId,
    required this.nombre,
    required this.vida,
    required this.poderCuracion,
    required this.costoInvocacion,
    required this.imagen,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] as String,
      civilizacionId: json['civilizacion_id'] as String,
      nombre: json['nombre'] as String,
      vida: json['vida'] as int,
      poderCuracion: json['poder_curacion'] as int,
      costoInvocacion: json['costo_invocacion'] as int,
      imagen: json['imagen'] as String,
    );
  }

  Hospital copyWith({
    String? id,
    String? civilizacionId,
    String? nombre,
    int? vida,
    int? poderCuracion,
    int? costoInvocacion,
    String? imagen,
  }) {
    return Hospital(
      id: id ?? this.id,
      civilizacionId: civilizacionId ?? this.civilizacionId,
      nombre: nombre ?? this.nombre,
      vida: vida ?? this.vida,
      poderCuracion: poderCuracion ?? this.poderCuracion,
      costoInvocacion: costoInvocacion ?? this.costoInvocacion,
      imagen: imagen ?? this.imagen,
    );
  }
}
