import 'dart:math';
import 'dart:ui';

import 'package:mitic/ia/ia_china.dart';
import 'package:mitic/ia/ia_romanos.dart';
import 'package:mitic/ia/ia_sarracenos.dart';
import 'package:mitic/models/aldeano_model.dart';
import 'package:mitic/models/cultivo_model.dart';
import 'package:mitic/models/hospital_model.dart';
import 'package:mitic/models/juego2.dart';
import 'package:mitic/models/torre_model.dart';

import 'ia_base.dart';
import 'ia_maya.dart';
import 'ia_azteca.dart';

class IAFactory {
  static IABase crearIA({
    required Juego2 juego,
    required VoidCallback onPasarTurno,
    required Map<String, Aldeano>? aldeanos,
    required Map<String, Cultivo>? cultivos,
    required Map<String, Torre>? torres,
    required Map<String, Hospital>? hospitales,
    required Function(int fila, int columna, String tipo, String id) onInvocar,
    required Function(String tipo, int fila, int columna, int puntos) onMejorar,
  }) {
    final yo = juego.jugadorActual;
    final enemigo = juego.oponente;
    final String civId = yo.civilizacion.id;

    // Lista de IAs disponibles
    final List<IABase Function()> iaConstructores = [
      () => IAMaya(
        juego: juego,
        yo: yo,
        enemigo: enemigo,
        onPasarTurno: onPasarTurno,
        aldeanos: aldeanos,
        cultivos: cultivos,
        torres: torres,
        hospitales: hospitales,
        onInvocar: onInvocar,
        onMejorar: onMejorar,
      ),
      () => IAAzteca(
        juego: juego,
        yo: yo,
        enemigo: enemigo,
        onPasarTurno: onPasarTurno,
        aldeanos: aldeanos,
        cultivos: cultivos,
        torres: torres,
        hospitales: hospitales,
        onInvocar: onInvocar,
        onMejorar: onMejorar,
      ),
      () => IAChina(
        juego: juego,
        yo: yo,
        enemigo: enemigo,
        onPasarTurno: onPasarTurno,
        aldeanos: aldeanos,
        cultivos: cultivos,
        torres: torres,
        hospitales: hospitales,
        onInvocar: onInvocar,
        onMejorar: onMejorar,
      ),
      () => IASarracenos(
        juego: juego,
        yo: yo,
        enemigo: enemigo,
        onPasarTurno: onPasarTurno,
        aldeanos: aldeanos,
        cultivos: cultivos,
        torres: torres,
        hospitales: hospitales,
        onInvocar: onInvocar,
        onMejorar: onMejorar,
      ),
      () => IARomanos(
        juego: juego,
        yo: yo,
        enemigo: enemigo,
        onPasarTurno: onPasarTurno,
        aldeanos: aldeanos,
        cultivos: cultivos,
        torres: torres,
        hospitales: hospitales,
        onInvocar: onInvocar,
        onMejorar: onMejorar,
      ),
    ];

    switch (civId) {
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
          onInvocar: onInvocar,
          onMejorar: onMejorar,
        );
      case 'azteca':
        return IAAzteca(
          juego: juego,
          yo: yo,
          enemigo: enemigo,
          onPasarTurno: onPasarTurno,
          aldeanos: aldeanos,
          cultivos: cultivos,
          torres: torres,
          hospitales: hospitales,
          onInvocar: onInvocar,
          onMejorar: onMejorar,
        );
      case 'china':
        return IAChina(
          juego: juego,
          yo: yo,
          enemigo: enemigo,
          onPasarTurno: onPasarTurno,
          aldeanos: aldeanos,
          cultivos: cultivos,
          torres: torres,
          hospitales: hospitales,
          onInvocar: onInvocar,
          onMejorar: onMejorar,
        );
      case 'sarracenos':
        return IASarracenos(
          juego: juego,
          yo: yo,
          enemigo: enemigo,
          onPasarTurno: onPasarTurno,
          aldeanos: aldeanos,
          cultivos: cultivos,
          torres: torres,
          hospitales: hospitales,
          onInvocar: onInvocar,
          onMejorar: onMejorar,
        );
      case 'romanos':
        return IARomanos(
          juego: juego,
          yo: yo,
          enemigo: enemigo,
          onPasarTurno: onPasarTurno,
          aldeanos: aldeanos,
          cultivos: cultivos,
          torres: torres,
          hospitales: hospitales,
          onInvocar: onInvocar,
          onMejorar: onMejorar,
        );
      default:
        // 👇 SELECCIÓN ALEATORIA ENTRE TODAS LAS IAS DISPONIBLES
        final random = Random();
        final iaAleatoria =
            iaConstructores[random.nextInt(iaConstructores.length)];
        print(
          '🎲 IA por defecto: No hay IA específica para $civId, usando IA aleatoria',
        );
        return iaAleatoria();
    }
  }
}
