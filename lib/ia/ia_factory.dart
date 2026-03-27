import 'dart:ui';

import 'package:mitic/models/aldeano_model.dart';
import 'package:mitic/models/cultivo_model.dart';
import 'package:mitic/models/hospital_model.dart';
import 'package:mitic/models/juego2.dart';
import 'package:mitic/models/torre_model.dart';

import 'ia_base.dart';
import 'ia_maya.dart';

class IAFactory {
  static IABase crearIA({
    required Juego2 juego,
    required VoidCallback onPasarTurno,
    required Map<String, Aldeano>? aldeanos, // 👈 NUEVO
    required Map<String, Cultivo>? cultivos, // 👈 NUEVO
    required Map<String, Torre>? torres, // 👈 NUEVO
    required Map<String, Hospital>? hospitales, // 👈 NUEVO
    required Function(int fila, int columna, String tipo, String id)
    onInvocar, // 👈 NUEVO
  }) {
    final yo = juego.jugadorActual;
    final enemigo = juego.oponente;

    switch (yo.civilizacion.id) {
      case 'maya':
        return IAMaya(
          juego: juego,
          yo: yo,
          enemigo: enemigo,
          onPasarTurno: onPasarTurno,
          aldeanos: aldeanos,
          cultivos: cultivos,
          torres: torres,
          hospitales: hospitales,
          onInvocar: onInvocar, // 👈 NUEVO
        );
      default:
        return IAMaya(
          juego: juego,
          yo: yo,
          enemigo: enemigo,
          onPasarTurno: onPasarTurno,
          aldeanos: aldeanos,
          cultivos: cultivos,
          torres: torres,
          hospitales: hospitales,
          onInvocar: onInvocar, // 👈 NUEVO
        );
    }
  }
}
