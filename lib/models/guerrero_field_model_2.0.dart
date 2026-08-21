import 'guerrero_model.dart';

class GuerreroCampo {
  Guerrero guerreroBase; // Datos originales
  int vidaActual;
  int ataqueActual;
  bool yaAtacoEsteTurno;
  String coordenada; // Ej: "C0", "A3", etc.
  bool puedeMoverse; // Para controlar si ya se movió este turno
  bool animar = false; // 👈 NUEVO
  bool resplandor = false;

  GuerreroCampo({
    required this.guerreroBase,
    required this.vidaActual,
    required this.ataqueActual,
    this.yaAtacoEsteTurno = false,
    required this.coordenada,
    this.puedeMoverse = true,
    this.animar = false,
  });

  // Constructor para crear desde Guerrero base
  factory GuerreroCampo.desdeGuerrero({
    required Guerrero guerrero,
    required String coordenada,
  }) {
    return GuerreroCampo(
      guerreroBase: guerrero,
      vidaActual: guerrero.vida,
      ataqueActual: guerrero.ataque,
      coordenada: coordenada,
    );
  }
}
