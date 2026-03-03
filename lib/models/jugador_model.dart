import 'guerrero_model.dart';
import 'civilizacion_model.dart';
import 'monument_model.dart';
import 'guerrero_field_model.dart';

class Jugador {
  // ============================================
  // LO QUE YA DIJISTE (BIEN AHÍ)
  // ============================================
  Civilizacion civilizacion; // La civilización seleccionada
  List<Guerrero>
  guerrerosSeleccionados; // 4 guerreros (1 principal + 3 aliados)
  MonumentField monumentoEnCampo; // Monumento con estado actual
  List<GuerreroField> guerrerosEnCampo; // Hasta 3 (o 4 si es china)
  int puntosAcumulados; // Puntos de los dados

  // ============================================
  // LO QUE FALTA (Y ES CLAVE)
  // ============================================
  int turno; // ¿Es su turno?
  bool yaAtacoEsteTurno; // Para controlar ataques múltiples
  List<Guerrero> guerrerosEnMano; // Los que aún no invocó
  Map<String, dynamic>
  estadoAccion; // Para saber en qué modo está (curando, atacando, etc.)

  // ============================================
  // CONSTRUCTOR
  // ============================================
  Jugador({
    required this.civilizacion,
    required this.guerrerosSeleccionados,
    required this.monumentoEnCampo,
    required this.guerrerosEnCampo,
    this.puntosAcumulados = 0,
    this.turno = 0,
    this.yaAtacoEsteTurno = false,
    List<Guerrero>? guerrerosEnMano,
    Map<String, dynamic>? estadoAccion,
  }) : guerrerosEnMano = guerrerosEnMano ?? [],
       estadoAccion = estadoAccion ?? {};
}
