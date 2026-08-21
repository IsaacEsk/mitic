import 'cultivo_model.dart';

class CultivoCampo {
  final Cultivo cultivoBase;
  int vidaActual;
  int puntosPorTurnoActual;
  String coordenada;
  bool animar = false;
  bool resplandor = false;

  CultivoCampo({
    required this.cultivoBase,
    required this.vidaActual,
    required this.puntosPorTurnoActual,
    required this.coordenada,
    this.animar = false,
  });

  factory CultivoCampo.desdeCultivo({
    required Cultivo cultivo,
    required String coordenada,
  }) {
    return CultivoCampo(
      cultivoBase: cultivo,
      vidaActual: cultivo.vida,
      puntosPorTurnoActual: cultivo.puntosPorTurno,
      coordenada: coordenada,
      animar: false,
    );
  }

  CultivoCampo copyWith({
    int? vidaActual,
    int? puntosPorTurnoActual,
    String? coordenada,
    bool? animar,
  }) {
    return CultivoCampo(
      cultivoBase: cultivoBase,
      vidaActual: vidaActual ?? this.vidaActual,
      puntosPorTurnoActual: puntosPorTurnoActual ?? this.puntosPorTurnoActual,
      coordenada: coordenada ?? this.coordenada,
      animar: animar ?? this.animar,
    );
  }
}
