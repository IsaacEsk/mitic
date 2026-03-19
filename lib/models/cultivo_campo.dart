import 'cultivo_model.dart';

class CultivoCampo {
  final Cultivo cultivoBase;
  int vidaActual;
  int puntosPorTurnoActual;
  String coordenada;

  CultivoCampo({
    required this.cultivoBase,
    required this.vidaActual,
    required this.puntosPorTurnoActual,
    required this.coordenada,
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
    );
  }

  CultivoCampo copyWith({
    int? vidaActual,
    int? puntosPorTurnoActual,
    String? coordenada,
  }) {
    return CultivoCampo(
      cultivoBase: cultivoBase,
      vidaActual: vidaActual ?? this.vidaActual,
      puntosPorTurnoActual: puntosPorTurnoActual ?? this.puntosPorTurnoActual,
      coordenada: coordenada ?? this.coordenada,
    );
  }
}