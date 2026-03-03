import 'jugador_model.dart';

class Juego {
  List<Jugador> jugadores; // [0] = tú, [1] = enemigo(s)
  int turnoActual; // 0 o 1
  int fase; // 0 = inicio, 1 = dados, 2 = acción, 3 = ataque, etc.

  Juego({required this.jugadores, this.turnoActual = 0, this.fase = 0});
}
