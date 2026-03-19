import 'jugador2.dart';

class Juego2 {
  List<Jugador2> jugadores; // [0] = tú, [1] = enemigo(s)
  int turnoActual; // 0 o 1
  int fase; // 0 = inicio, 1 = dados, 2 = acción, 3 = ataque, etc.

  Juego2({
    required this.jugadores,
    this.turnoActual = 0,
    this.fase = 0,
  });

  // ============================================
  // OBTENER JUGADOR ACTUAL
  // ============================================
  Jugador2 get jugadorActual => jugadores[turnoActual];

  // ============================================
  // OBTENER OPONENTE
  // ============================================
  Jugador2 get oponente => jugadores[turnoActual == 0 ? 1 : 0];

  // ============================================
  // CAMBIAR TURNO
  // ============================================
  void cambiarTurno() {
    turnoActual = turnoActual == 0 ? 1 : 0;
    fase = 0; // Reiniciamos fase
  }

  // ============================================
  // VERIFICAR SI EL JUEGO TERMINÓ
  // ============================================
  bool get juegoTerminado {
    return jugadores.any((j) => j.monumentoEnCampo.vidaActual <= 0);
  }

  // ============================================
  // OBTENER GANADOR (si existe)
  // ============================================
  Jugador2? get ganador {
    if (jugadores[0].monumentoEnCampo.vidaActual <= 0) return jugadores[1];
    if (jugadores[1].monumentoEnCampo.vidaActual <= 0) return jugadores[0];
    return null;
  }
}