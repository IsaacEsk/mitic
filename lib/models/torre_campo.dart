import 'torre_model.dart';

class TorreCampo {
  final Torre torreBase; // Datos originales
  int vidaActual;
  int ataqueActual;
  bool yaAtacoEsteTurno;
  String coordenada;

  TorreCampo({
    required this.torreBase,
    required this.vidaActual,
    required this.ataqueActual,
    this.yaAtacoEsteTurno = false,
    required this.coordenada,
  });

  // Constructor desde Torre base
  factory TorreCampo.desdeTorre({
    required Torre torre,
    required String coordenada,
  }) {
    return TorreCampo(
      torreBase: torre,
      vidaActual: torre.vida,
      ataqueActual: torre.ataque,
      coordenada: coordenada,
    );
  }

  // Para clonar con cambios
  TorreCampo copyWith({
    int? vidaActual,
    int? ataqueActual,
    bool? yaAtacoEsteTurno,
    String? coordenada,
  }) {
    return TorreCampo(
      torreBase: torreBase,
      vidaActual: vidaActual ?? this.vidaActual,
      ataqueActual: ataqueActual ?? this.ataqueActual,
      yaAtacoEsteTurno: yaAtacoEsteTurno ?? this.yaAtacoEsteTurno,
      coordenada: coordenada ?? this.coordenada,
    );
  }
}
