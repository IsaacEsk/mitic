import 'dart:math';
import '../models/guerrero_model.dart';
import '../models/jugador_model.dart';
import '../models/guerrero_field_model.dart';

class IAController {
  final Jugador yo; // La IA (jugador 1)
  final Jugador enemigo; // El humano (jugador 0)
  final Random random = Random();

  // Callbacks para ejecutar acciones
  final Function(Guerrero guerrero) onInvocar;
  final Function(GuerreroField atacante, dynamic objetivo) onAtacar;
  final Function(int puntos) onReconstruir;
  final Function(GuerreroField guerrero, int puntos) onCurar;
  final Function(GuerreroField guerrero, int puntos) onMejorar;
  final Function() onPasarTurno;

  final Function(List<GuerreroField> atacantes) onAtacarMultiple; // NUEVO

  IAController({
    required this.yo,
    required this.enemigo,
    required this.onInvocar,
    required this.onAtacar,
    required this.onAtacarMultiple, // NUEVO
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

    // ============================================
    // PASO 1: Obtener información del tablero
    // ============================================
    final enemigosVivos = _getEnemigosVivos();
    final misGuerreros = _getMisGuerreros();
    final atacantesDisponibles = _getAtacantesDisponibles();

    // ============================================
    // PASO 2: ¿Debo reconstruir el monumento?
    // ============================================
    if (_deboReconstruir(enemigosVivos, misGuerreros)) {
      print('🤟  RECONSTRUYENDO: Monumento en riesgo crítico');
      _reconstruirYAtaque(atacantesDisponibles);
      return;
    }

    // ============================================
    // PASO 3: INVOCAR (si no hay guerreros)
    // ============================================

    if (_intentarInvocar()) {
      // Si invocó, atacar
      final nuevosAtacantes = _getAtacantesDisponibles();
      _atacarConTodos(nuevosAtacantes);
      return;
    } else {
      // No pudo invocar, verificar si hay atacantes
      final atacantes = _getAtacantesDisponibles();

      if (atacantes.isNotEmpty) {
        print('🤖 No invocó, pero tengo atacantes');

        // ¿Hay guerrero en riesgo?
        if (_hayGuerreroEnRiesgo(misGuerreros, enemigosVivos)) {
          // Ya se curó dentro de la función, ahora atacar
          _atacarConTodos(_getAtacantesDisponibles());
        }
        // ¿Tengo puntos para mejorar?
        else if (yo.puntosAcumulados > 5) {
          _hacerMejoras(misGuerreros);
          _atacarConTodos(_getAtacantesDisponibles());
        }
        // Si no, atacar directamente
        else {
          _atacarConTodos(atacantes);
        }
      } else {
        onPasarTurno();
      }
      return;
    }
  }

  List<GuerreroField> _getEnemigosVivos() {
    return enemigo.guerrerosEnCampo
        .where((g) => g.guerreroBase.id.isNotEmpty)
        .toList();
  }

  List<GuerreroField> _getMisGuerreros() {
    return yo.guerrerosEnCampo
        .where((g) => g.guerreroBase.id.isNotEmpty)
        .toList();
  }

  List<GuerreroField> _getAtacantesDisponibles() {
    return yo.guerrerosEnCampo
        .where((g) => g.guerreroBase.id.isNotEmpty && !g.yaAtacoEsteTurno)
        .toList();
  }

  bool _deboReconstruir(
    List<GuerreroField> enemigosVivos,
    List<GuerreroField> misGuerreros,
  ) {
    // Si no hay enemigos, no hay riesgo
    if (enemigosVivos.isEmpty) return false;

    // Calcular ataque total enemigo
    final ataqueEnemigoTotal = enemigosVivos.fold(
      0,
      (sum, g) => sum + g.ataqueActual,
    );

    // Si mi monumento tiene más vida que el ataque enemigo, estoy seguro
    if (yo.monumentoEnCampo.vidaActual > ataqueEnemigoTotal) return false;

    // ============================================
    // CASO CRÍTICO: El enemigo puede matar mi monumento
    // ============================================
    print(
      '🤔 Monumento en riesgo: $ataqueEnemigoTotal vs ${yo.monumentoEnCampo.vidaActual}',
    );

    // Verificar si puedo invocar un guerrero que me salve
    if (_puedoInvocarYSalvarme(ataqueEnemigoTotal)) {
      print('🤔 Prefiero invocar antes que reconstruir');
      return false; // No reconstruyo, mejor invoco
    }

    // Si no puedo salvarme invocando, toca reconstruir
    return true;
  }

  bool _puedoInvocarYSalvarme(int ataqueEnemigoTotal) {
    // Verificar si tengo espacio
    final espaciosLibres =
        yo.guerrerosEnCampo.where((g) => g.guerreroBase.id.isEmpty).length;

    if (espaciosLibres == 0) return false;

    // Verificar si tengo un guerrero que pueda pagar
    final posibles =
        yo.guerrerosEnMano
            .where((g) => g.costoInvocacion <= yo.puntosAcumulados)
            .toList();

    if (posibles.isEmpty) return false;

    // Simular: si invoco al más fuerte, ¿el enemigo seguirá pudiendo matar mi monumento?
    posibles.sort((a, b) => b.ataque.compareTo(a.ataque));
    final mejorPosible = posibles.first;

    // Si invoco, el enemigo tendrá que dividir su ataque entre mis guerreros
    // Regla simple: si el ataque enemigo es menor a la vida de mi monumento + la vida del nuevo guerrero
    final vidaExtra = mejorPosible.vida;
    final nuevaVidaTotal = yo.monumentoEnCampo.vidaActual + vidaExtra;

    return nuevaVidaTotal > ataqueEnemigoTotal;
  }

  void _reconstruirYAtaque(List<GuerreroField> atacantes) {
    // Reconstruir con todos los puntos
    if (yo.puntosAcumulados > 0) {
      onReconstruir(yo.puntosAcumulados);
    }

    // Atacar si puedo
    if (atacantes.isNotEmpty) {
      _atacarConTodos(atacantes);
    } else {
      onPasarTurno();
    }
  }

  void _atacarConTodos(List<GuerreroField> atacantes) {
    if (atacantes.isNotEmpty) {
      onAtacarMultiple(atacantes);
    } else {
      print('🤖 No hay atacantes, pasando turno');
      onPasarTurno();
    }
  }

  void _hacerMejoras(List<GuerreroField> misGuerreros) {
    if (misGuerreros.isEmpty || yo.puntosAcumulados <= 0) {
      print('🤖 No hay guerreros o puntos para mejorar');
      return;
    }

    // ============================================
    // PASO 1: ELEGIR UN GUERRERO AL AZAR
    // ============================================
    misGuerreros.shuffle(); // Desordena la lista
    final elegido = misGuerreros.first; // Toma el primero (ahora aleatorio)

    print('🤖 Guerrero elegido al azar: ${elegido.guerreroBase.nombreId}');

    // ============================================
    // PASO 2: DECIDIR CUÁNTOS PUNTOS USAR
    // ============================================
    // Mínimo 1, máximo todos los puntos disponibles
    int maxPuntos = yo.puntosAcumulados;
    int puntosUsar = Random().nextInt(maxPuntos) + 1; // 1 a maxPuntos

    print('🤖 Usando $puntosUsar de $maxPuntos puntos disponibles');

    // ============================================
    // PASO 3: DECIDIR CÓMO REPARTIR (ataque/vida)
    // ============================================
    int puntosAtaque = 0;
    int puntosVida = 0;

    // 70% de probabilidad de mejorar ataque (lo más común)
    // 30% de probabilidad de mejorar vida (más defensivo)
    if (Random().nextInt(100) < 70) {
      // Mejorar ataque
      puntosAtaque = puntosUsar;
      print('🤖 Enfocando en ATAQUE');
    } else {
      // Mejorar vida
      puntosVida = puntosUsar;
      print('🤖 Enfocando en VIDA');
    }

    // EXTRA: 10% de probabilidad de repartir mitad y mitad
    if (Random().nextInt(100) < 10 && puntosUsar > 1) {
      puntosAtaque = puntosUsar ~/ 2;
      puntosVida = puntosUsar - puntosAtaque;
      print('🤖 REPARTIENDO: $puntosAtaque ataque / $puntosVida vida');
    }

    // ============================================
    // PASO 4: APLICAR MEJORAS
    // ============================================
    if (puntosAtaque > 0) {
      print(
        '🤖 Mejorando ATAQUE de ${elegido.guerreroBase.nombreId} +$puntosAtaque',
      );
      onMejorar(elegido, puntosAtaque); // Asumo que onMejorar es para ataque
    }

    if (puntosVida > 0) {
      print(
        '🤖 Mejorando VIDA de ${elegido.guerreroBase.nombreId} +$puntosVida',
      );
      // Si tienes una función separada para curar, úsala aquí
      // onCurar(elegido, puntosVida);
    }
  }

  bool _hayGuerreroEnRiesgo(
    List<GuerreroField> misGuerreros,
    List<GuerreroField> enemigosVivos,
  ) {
    if (enemigosVivos.isEmpty) return false;

    // Calcular ataque total enemigo
    final ataqueEnemigoTotal = enemigosVivos.fold(
      0,
      (sum, g) => sum + g.ataqueActual,
    );

    // Buscar guerreros dopados (ataque > base × 1.5)
    final guerrerosDopados =
        misGuerreros.where((g) {
          final ataqueBase = g.guerreroBase.ataque;
          return g.ataqueActual > ataqueBase * 1.5;
        }).toList();

    if (guerrerosDopados.isEmpty) return false;

    // Verificar si alguno está en riesgo de muerte
    for (var guerrero in guerrerosDopados) {
      if (guerrero.vidaActual < ataqueEnemigoTotal) {
        print(
          '🤖 Guerrero dopado en riesgo: ${guerrero.guerreroBase.nombreId}',
        );
        print(
          '🤖 Vida: ${guerrero.vidaActual}, Ataque enemigo: $ataqueEnemigoTotal',
        );

        // Calcular puntos necesarios para sobrevivir
        final puntosNecesarios = ataqueEnemigoTotal - guerrero.vidaActual + 1;

        if (yo.puntosAcumulados >= puntosNecesarios) {
          print('🤖 CURANDO para salvar al guerrero');
          onCurar(guerrero, puntosNecesarios);
          return true;
        } else {
          print('🤖 No alcanzan puntos para curarlo :(');
        }
      }
    }

    return false;
  }

  bool _oportunidadDeOro(
    List<GuerreroField> enemigosVivos,
    List<GuerreroField> atacantes,
    List<GuerreroField> misGuerreros,
  ) {
    if (enemigosVivos.isNotEmpty) return false;

    print('🤖 🥇 ¡OPORTUNIDAD DE ORO! Enemigo sin guerreros');

    if (atacantes.isEmpty) {
      print('🤖 No tengo guerreros para atacar el monumento');
      return false;
    }

    // ============================================
    // PASO 1: INVOCAR MIENTRAS HAYA ESPACIO Y PUNTOS
    // ============================================
    while (_puedeInvocar()) {
      if (!_intentarInvocar()) break; // Si no puede invocar, salimos
    }

    // ============================================
    // PASO 2: MEJORAR CON TODOS LOS PUNTOS RESTANTES
    // ============================================
    if (yo.puntosAcumulados > 0 && misGuerreros.isNotEmpty) {
      print('🤖 Potenciando ataque con ${yo.puntosAcumulados} puntos');

      // Elegir al guerrero con más ataque (para hacerlo aún más letal)
      misGuerreros.sort((a, b) => b.ataqueActual.compareTo(a.ataqueActual));
      final mejor = misGuerreros.first;

      // Usar TODOS los puntos en mejora
      onMejorar(mejor, yo.puntosAcumulados);
    }

    // ============================================
    // PASO 3: ATACAR MONUMENTO CON TODO
    // ============================================
    print('🤖 ATACANDO MONUMENTO con todos los guerreros (potenciados)');

    // Obtener lista actualizada de atacantes (por si invocó o mejoró)
    final atacantesActualizados = _getAtacantesDisponibles();
    onAtacarMultiple(atacantesActualizados);

    return true;
  }

  bool _puedeInvocar() {
    // Verificar si hay espacio en el campo
    final espaciosLibres =
        yo.guerrerosEnCampo.where((g) => g.guerreroBase.id.isEmpty).length;

    if (espaciosLibres == 0) return false;

    // Verificar si hay guerreros en mano que pueda pagar
    return yo.guerrerosEnMano.any(
      (g) => g.costoInvocacion <= yo.puntosAcumulados,
    );
  }

  bool _intentarInvocar() {
    final espaciosLibres =
        yo.guerrerosEnCampo.where((g) => g.guerreroBase.id.isEmpty).length;

    if (espaciosLibres == 0) {
      print('🤖 No hay espacios libres');
      return false;
    }

    print('🤖 Hay espacios libres, intentando invocar...');

    final principalId = '${yo.civilizacion.id}_001';
    final tengoPrincipalEnCampo = yo.guerrerosEnCampo.any(
      (g) => g.guerreroBase.id == principalId,
    );

    // Caso: Principal no está en campo
    if (!tengoPrincipalEnCampo) {
      return _intentarInvocarPrincipal(principalId);
    }

    // Caso: Principal ya está en campo, invocar aliados
    return _intentarInvocarAliado(principalId);
  }

  bool _intentarInvocarPrincipal(String principalId) {
    print('🤖 El principal NO está en el campo');

    final principalEnMano = yo.guerrerosEnMano.any((g) => g.id == principalId);

    if (!principalEnMano) {
      print('🤖 Principal no encontrado en la mano');
      return false;
    }

    final guerreroPrincipal = yo.guerrerosEnMano.firstWhere(
      (g) => g.id == principalId,
    );

    if (yo.puntosAcumulados >= guerreroPrincipal.costoInvocacion) {
      print('🤖 Invocando al principal');
      onInvocar(guerreroPrincipal);
      return true;
    } else {
      print('🤖 No alcanzan puntos para el principal');
      return false;
    }
  }

  bool _intentarInvocarAliado(String principalId) {
    print('🤖 El principal YA está en el campo, buscando aliados...');

    final aliadosDisponibles =
        yo.guerrerosEnMano.where((g) => g.id != principalId).toList();

    if (aliadosDisponibles.isEmpty) {
      print('🤖 No hay aliados disponibles');
      return false;
    }

    // Ordenar por mejor relación ataque/costo
    aliadosDisponibles.sort((a, b) {
      final double ratioA = a.ataque / a.costoInvocacion;
      final double ratioB = b.ataque / b.costoInvocacion;
      return ratioB.compareTo(ratioA);
    });

    for (var aliado in aliadosDisponibles) {
      if (yo.puntosAcumulados >= aliado.costoInvocacion) {
        print('🤖 Invocando aliado: ${aliado.nombreId}');
        onInvocar(aliado);
        return true;
      }
    }

    print('🤖 No alcanzan puntos para ningún aliado');
    return false;
  }

  void _mejorarAlMejorCandidato(List<GuerreroField> misGuerreros) {
    // Buscar el guerrero con más vida (menos probable que muera)
    misGuerreros.sort((a, b) => b.vidaActual.compareTo(a.vidaActual));
    final mejorCandidato = misGuerreros.first;

    print('🤖 Mejorando a ${mejorCandidato.guerreroBase.nombreId}');
    onMejorar(mejorCandidato, yo.puntosAcumulados);
  }
}
