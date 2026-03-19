import 'aldeano_model.dart';

class AldeanoCampo {
  final Aldeano aldeanoBase;
  int vidaActual;
  int puntosReconstruccionActual;
  String coordenada;
  bool yaActuoEsteTurno;

  AldeanoCampo({
    required this.aldeanoBase,
    required this.vidaActual,
    required this.puntosReconstruccionActual,
    required this.coordenada,
    this.yaActuoEsteTurno = false,
  });

  factory AldeanoCampo.desdeAldeano({
    required Aldeano aldeano,
    required String coordenada,
  }) {
    return AldeanoCampo(
      aldeanoBase: aldeano,
      vidaActual: aldeano.vida,
      puntosReconstruccionActual: aldeano.puntosReconstruccion,
      coordenada: coordenada,
    );
  }

  AldeanoCampo copyWith({
    int? vidaActual,
    int? puntosReconstruccionActual,
    String? coordenada,
    bool? yaActuoEsteTurno,
  }) {
    return AldeanoCampo(
      aldeanoBase: aldeanoBase,
      vidaActual: vidaActual ?? this.vidaActual,
      puntosReconstruccionActual: puntosReconstruccionActual ?? this.puntosReconstruccionActual,
      coordenada: coordenada ?? this.coordenada,
      yaActuoEsteTurno: yaActuoEsteTurno ?? this.yaActuoEsteTurno,
    );
  }
}