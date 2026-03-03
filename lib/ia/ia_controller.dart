import 'dart:math';
import 'package:flutter/material.dart';
import '../models/juego_model.dart';
import '../models/guerrero_model.dart';
import '../models/jugador_model.dart';
import '../models/guerrero_field_model.dart';

class IAController {
  final Jugador yo; // La IA (jugador 1)
  final Jugador enemigo; // El humano (jugador 0)
  final Random random = Random();

  // Callbacks para ejecutar acciones en el tablero
  final Function(Guerrero guerrero) onInvocar;
  final Function(GuerreroField atacante, dynamic objetivo) onAtacar;
  final Function(int puntos) onReconstruir;
  final Function(GuerreroField guerrero, int puntos) onCurar;
  final Function(GuerreroField guerrero, int puntos) onMejorar;
  final Function() onPasarTurno;

  IAController({
    required this.yo,
    required this.enemigo,
    required this.onInvocar,
    required this.onAtacar,
    required this.onReconstruir,
    required this.onCurar,
    required this.onMejorar,
    required this.onPasarTurno,
  });

  // ============================================
  // MÉTODO PRINCIPAL: TOMA UNA DECISIÓN
  // ============================================
  void tomarDecision() {
    print('🤖 IA analizando situación...');

    // 1. Verificar si puede invocar a su principal
    if (_puedeInvocarPrincipal()) {
      _invocarPrincipal();
      return;
    }

    // 2. Verificar si necesita invocar (menos de 2 guerreros)
    if (_necesitaInvocar()) {
      _invocarMejorDisponible();
      return;
    }

    // 3. Verificar si puede atacar
    if (_puedeAtacar()) {
      _atacar();
      return;
    }

    // 4. Verificar si necesita reconstruir
    if (_necesitaReconstruir()) {
      _reconstruir();
      return;
    }

    // 5. Verificar si necesita curar
    if (_necesitaCurar()) {
      _curar();
      return;
    }

    // 6. Si nada, pasa turno
    print('🤖 IA no encuentra acción útil, pasa turno');
    onPasarTurno();
  }

  // ============================================
  // FUNCIONES DE VERIFICACIÓN
  // ============================================
  bool _puedeInvocarPrincipal() {
    final principalId = '${yo.civilizacion.id}_001';
    final principalEnMano = yo.guerrerosEnMano.any((g) => g.id == principalId);
    final principalEnCampo = yo.guerrerosEnCampo.any(
      (g) => g.guerreroBase.id == principalId,
    );

    return principalEnMano && !principalEnCampo && yo.puntosAcumulados >= 12;
  }

  bool _necesitaInvocar() {
    final guerrerosEnCampo =
        yo.guerrerosEnCampo.where((g) => g.guerreroBase.id.isNotEmpty).length;
    return guerrerosEnCampo < 2 &&
        yo.guerrerosEnMano.isNotEmpty &&
        yo.puntosAcumulados >= 10;
  }

  bool _puedeAtacar() {
    return yo.guerrerosEnCampo.any(
      (g) => !g.yaAtacoEsteTurno && g.guerreroBase.id.isNotEmpty,
    );
  }

  bool _necesitaReconstruir() {
    return yo.puntosAcumulados > 5 &&
        yo.monumentoEnCampo.vidaActual < yo.monumentoEnCampo.vidaMaxima * 0.5;
  }

  bool _necesitaCurar() {
    return yo.guerrerosEnCampo.any(
      (g) =>
          g.guerreroBase.id.isNotEmpty &&
          g.vidaActual < g.guerreroBase.vida * 0.7 &&
          yo.puntosAcumulados > 5,
    );
  }

  // ============================================
  // FUNCIONES DE ACCIÓN
  // ============================================
  void _invocarPrincipal() {
    print('🤖 IA decide invocar a su guerrero principal');
    final principal = yo.guerrerosEnMano.firstWhere(
      (g) => g.id == '${yo.civilizacion.id}_001',
    );
    onInvocar(principal);
  }

  void _invocarMejorDisponible() {
    print('🤖 IA decide invocar al mejor disponible');
    // Elegir el guerrero más fuerte (más ataque) que pueda pagar
    final posibles =
        yo.guerrerosEnMano
            .where((g) => g.costoInvocacion <= yo.puntosAcumulados)
            .toList();

    if (posibles.isNotEmpty) {
      posibles.sort((a, b) => b.ataque.compareTo(a.ataque));
      onInvocar(posibles.first);
    } else {
      onPasarTurno();
    }
  }

  void _atacar() {
    print('🤖 IA decide atacar');

    // Encontrar un atacante disponible
    final atacante = yo.guerrerosEnCampo.firstWhere(
      (g) => !g.yaAtacoEsteTurno && g.guerreroBase.id.isNotEmpty,
    );

    // Elegir objetivo: primero enemigos vivos, si no, monumento
    final enemigosVivos =
        enemigo.guerrerosEnCampo
            .where((g) => g.guerreroBase.id.isNotEmpty)
            .toList();

    if (enemigosVivos.isNotEmpty) {
      // Atacar al enemigo más débil
      enemigosVivos.sort((a, b) => a.vidaActual.compareTo(b.vidaActual));
      onAtacar(atacante, enemigosVivos.first);
    } else {
      // Atacar monumento
      onAtacar(atacante, null); // null representa monumento
    }
  }

  void _reconstruir() {
    print('🤖 IA decide reconstruir');
    int puntos = min(10, yo.puntosAcumulados); // No gasta más de 10
    onReconstruir(puntos);
  }

  void _curar() {
    print('🤖 IA decide curar');
    final heridos =
        yo.guerrerosEnCampo
            .where(
              (g) =>
                  g.guerreroBase.id.isNotEmpty &&
                  g.vidaActual < g.guerreroBase.vida * 0.7,
            )
            .toList();

    if (heridos.isNotEmpty) {
      heridos.sort((a, b) => a.vidaActual.compareTo(b.vidaActual));
      int puntos = min(10, yo.puntosAcumulados);
      onCurar(heridos.first, puntos);
    } else {
      onPasarTurno();
    }
  }
}
