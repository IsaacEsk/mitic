import 'hospital_model.dart';

class HospitalCampo {
  final Hospital hospitalBase;
  int vidaActual;
  int poderCuracionActual;
  String coordenada;

  HospitalCampo({
    required this.hospitalBase,
    required this.vidaActual,
    required this.poderCuracionActual,
    required this.coordenada,
  });

  factory HospitalCampo.desdeHospital({
    required Hospital hospital,
    required String coordenada,
  }) {
    return HospitalCampo(
      hospitalBase: hospital,
      vidaActual: hospital.vida,
      poderCuracionActual: hospital.poderCuracion,
      coordenada: coordenada,
    );
  }

  HospitalCampo copyWith({
    int? vidaActual,
    int? poderCuracionActual,
    String? coordenada,
  }) {
    return HospitalCampo(
      hospitalBase: hospitalBase,
      vidaActual: vidaActual ?? this.vidaActual,
      poderCuracionActual: poderCuracionActual ?? this.poderCuracionActual,
      coordenada: coordenada ?? this.coordenada,
    );
  }
}
