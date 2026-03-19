class Cultivo {
  final String id;
  final String civilizacionId;
  final String nombre;
  final int vida;
  final int puntosPorTurno;
  final int costoInvocacion;
  final String imagen;

  Cultivo({
    required this.id,
    required this.civilizacionId,
    required this.nombre,
    required this.vida,
    required this.puntosPorTurno,
    required this.costoInvocacion,
    required this.imagen,
  });

  factory Cultivo.fromJson(Map<String, dynamic> json) {
    return Cultivo(
      id: json['id'] as String,
      civilizacionId: json['civilizacion_id'] as String,
      nombre: json['nombre'] as String,
      vida: json['vida'] as int,
      puntosPorTurno: json['puntos_por_turno'] as int,
      costoInvocacion: json['costo_invocacion'] as int,
      imagen: json['imagen'] as String,
    );
  }

  Cultivo copyWith({
    String? id,
    String? civilizacionId,
    String? nombre,
    int? vida,
    int? puntosPorTurno,
    int? costoInvocacion,
    String? imagen,
  }) {
    return Cultivo(
      id: id ?? this.id,
      civilizacionId: civilizacionId ?? this.civilizacionId,
      nombre: nombre ?? this.nombre,
      vida: vida ?? this.vida,
      puntosPorTurno: puntosPorTurno ?? this.puntosPorTurno,
      costoInvocacion: costoInvocacion ?? this.costoInvocacion,
      imagen: imagen ?? this.imagen,
    );
  }
}