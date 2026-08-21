import 'dart:math';
import 'dart:ui';

import 'package:mitic/models/aldeano_model.dart';
import 'package:mitic/models/cultivo_model.dart';
import 'package:mitic/models/hospital_model.dart';
import 'package:mitic/models/juego2.dart';
import 'package:mitic/models/jugador2.dart';
import 'package:mitic/models/torre_model.dart';

abstract class IABase {
  final Juego2 juego;
  final Jugador2 yo;
  final Jugador2 enemigo;
  final VoidCallback onPasarTurno;
  final Random random = Random();

  // 👈 NUEVOS DATOS
  final Map<String, Aldeano>? aldeanos;
  final Map<String, Cultivo>? cultivos;
  final Map<String, Torre>? torres;
  final Map<String, Hospital>? hospitales;
  final Function(int fila, int columna, String tipo, String id)
  onInvocar; // 👈 NUEVO
  final Function(String tipo, int fila, int columna, int puntos) onMejorar;

  IABase({
    required this.juego,
    required this.yo,
    required this.enemigo,
    required this.onPasarTurno,
    required this.aldeanos,
    required this.cultivos,
    required this.torres,
    required this.hospitales,
    required this.onInvocar, // 👈 NUEVO
    required this.onMejorar,
  });

  void tomarDecision();

  bool hayCasillasVacias() {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        if (yo.tablero.estaVacia(i, j)) {
          return true;
        }
      }
    }
    return false;
  }

  List<Map<String, int>> getCasillasVacias() {
    final List<Map<String, int>> casillas = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        if (yo.tablero.estaVacia(i, j)) {
          casillas.add({'fila': i, 'columna': j});
        }
      }
    }
    return casillas;
  }
}
