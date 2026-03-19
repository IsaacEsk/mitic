class Aldeano {
  final String id;
  final String civilizacionId;
  final String nombre;
  final int vida;
  final int puntosReconstruccion;
  final int costoInvocacion;
  final String imagen;

  Aldeano({
    required this.id,
    required this.civilizacionId,
    required this.nombre,
    required this.vida,
    required this.puntosReconstruccion,
    required this.costoInvocacion,
    required this.imagen,
  });

  factory Aldeano.fromJson(Map<String, dynamic> json) {
    return Aldeano(
      id: json['id'] as String,
      civilizacionId: json['civilizacion_id'] as String,
      nombre: json['nombre'] as String,
      vida: json['vida'] as int,
      puntosReconstruccion: json['puntos_reconstruccion'] as int,
      costoInvocacion: json['costo_invocacion'] as int,
      imagen: json['imagen'] as String,
    );
  }

  Aldeano copyWith({
    String? id,
    String? civilizacionId,
    String? nombre,
    int? vida,
    int? puntosReconstruccion,
    int? costoInvocacion,
    String? imagen,
  }) {
    return Aldeano(
      id: id ?? this.id,
      civilizacionId: civilizacionId ?? this.civilizacionId,
      nombre: nombre ?? this.nombre,
      vida: vida ?? this.vida,
      puntosReconstruccion: puntosReconstruccion ?? this.puntosReconstruccion,
      costoInvocacion: costoInvocacion ?? this.costoInvocacion,
      imagen: imagen ?? this.imagen,
    );
  }
}