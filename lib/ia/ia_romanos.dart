import 'package:mitic/models/casilla.dart';

import 'ia_base.dart';

class IARomanos extends IABase {
  IARomanos({
    required super.juego,
    required super.yo,
    required super.enemigo,
    required super.onPasarTurno,
    required super.aldeanos,
    required super.cultivos,
    required super.torres,
    required super.hospitales,
    required super.onInvocar,
    required super.onMejorar,
  });

  @override
  @override
  void tomarDecision() {
    print('🤖 IA Romanos analizando situación...');
    print('📊 Puntos acumulados: ${yo.puntosAcumulados}');

    // PASO 1: Si puntos < 1000, priorizar cultivos
    if (yo.puntosAcumulados < 1000) {
      _construirImperioDeCultivos();
      return;
    }

    // PASO 2: Si ya tenemos 1000 puntos, construir ejército de guerreros
    print('🏛️ Romanos alcanzaron 1000 puntos, modo GUERRA activado!');
    _construirEjercitoDeGuerreros();
  }

  void _construirEjercitoDeGuerreros() {
    // 1. Intentar llenar todas las casillas vacías con guerreros
    if (_hayCasillasVacias()) {
      _invocarGuerreroEnCasillaVacia();
    }

    _mejorarGuerrerosMasivamente();

    _pasarTurno();
  }

  // ============================================
  // INVOCAR GUERRERO EN PRIMERA CASILLA VACÍA
  // ============================================
  void _invocarGuerreroEnCasillaVacia() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col) && _puedeInvocarGuerrero()) {
          final coordenada = yo.tablero.obtenerCoordenadas(fila, col);
          _invocarGuerrero(fila, col, coordenada);
          //return;
        }
      }
    }
    print('⚠️ Romanos no pueden invocar más guerreros');
  }

  // ============================================
  // MEJORAR GUERREROS MASIVAMENTE
  // ============================================
  void _mejorarGuerrerosMasivamente() {
    if (yo.puntosAcumulados <= 0) return;

    // Recolectar todos los guerreros
    final List<Map<String, int>> guerreros = [];
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          guerreros.add({'fila': fila, 'columna': col});
        }
      }
    }

    final int totalGuerreros = guerreros.length; // Máximo 20
    if (totalGuerreros == 0) return;
    if (yo.puntosAcumulados < totalGuerreros) {
      // Si tenemos menos puntos que guerreros, repartir de 1 en 1
      print('⚔️ Repartiendo puntos de 1 en 1 a $totalGuerreros guerreros');
      _repartirPuntosAGuerrerosUnoAUno(guerreros);
    } else {
      // Si tenemos más puntos, repartir uniformemente
      final int puntosPorGuerrero =
          (yo.puntosAcumulados / totalGuerreros).floor();
      final int puntosSobrantes =
          yo.puntosAcumulados - (puntosPorGuerrero * totalGuerreros);

      print(
        '⚔️ Mejorando $totalGuerreros guerreros con $puntosPorGuerrero puntos cada uno',
      );

      // Mejorar cada guerrero con la cantidad base
      for (var guerrero in guerreros) {
        if (puntosPorGuerrero > 0) {
          onMejorar(
            'guerrero',
            guerrero['fila']!,
            guerrero['columna']!,
            puntosPorGuerrero,
          );
        }
      }

      // Repartir los puntos sobrantes de 1 en 1
      if (puntosSobrantes > 0) {
        print('⚔️ Repartiendo $puntosSobrantes puntos sobrantes de 1 en 1');
        _repartirPuntosAGuerrerosUnoAUno(guerreros, maxPuntos: puntosSobrantes);
      }
    }
  }

  // ============================================
  // REPARTIR PUNTOS A GUERREROS UNO A UNO
  // ============================================
  void _repartirPuntosAGuerrerosUnoAUno(
    List<Map<String, int>> guerreros, {
    int maxPuntos = -1,
  }) {
    int puntosARepartir = (maxPuntos == -1) ? yo.puntosAcumulados : maxPuntos;
    if (puntosARepartir <= 0) return;

    int puntosRestantes = puntosARepartir;
    int index = 0;

    while (puntosRestantes > 0 && index < guerreros.length * 2) {
      for (var guerrero in guerreros) {
        if (puntosRestantes <= 0) break;
        onMejorar('guerrero', guerrero['fila']!, guerrero['columna']!, 1);
        puntosRestantes--;
      }
      index++;
    }

    print(
      '✅ Repartidos $puntosARepartir puntos entre ${guerreros.length} guerreros',
    );
  }

  // ============================================
  // VERIFICAR SI PUEDE INVOCAR GUERRERO
  // ============================================
  bool _puedeInvocarGuerrero() {
    return yo.guerrerosSeleccionados.any(
      (g) => g.costoInvocacion <= yo.puntosAcumulados,
    );
  }

  // ============================================
  // INVOCAR GUERRERO (EL MÁS OFENSIVO)
  // ============================================
  void _invocarGuerrero(int fila, int columna, String coordenada) {
    final posibles =
        yo.guerrerosSeleccionados
            .where((g) => g.costoInvocacion <= yo.puntosAcumulados)
            .toList();

    if (posibles.isEmpty) return;

    // Elegir el guerrero con más ataque
    posibles.sort((a, b) => b.ataque.compareTo(a.ataque));
    final guerrero = posibles.first;

    print('⚔️ Romanos invocan guerrero ${guerrero.nombreId} en $coordenada');
    onInvocar(fila, columna, 'guerrero', guerrero.id);
  }

  // ============================================
  // CONSTRUIR IMPERIO DE CULTIVOS
  // ============================================
  void _construirImperioDeCultivos() {
    // 1. Intentar llenar todas las casillas vacías con cultivos
    if (_hayCasillasVacias()) {
      _invocarCultivoEnCasillaVacia();
      //return;
    }

    // 2. Si ya está lleno de cultivos, mejorarlos masivamente

    _mejorarCultivosMasivamente();

    // Si no hay nada que hacer, pasar turno
    _pasarTurno();
  }

  // ============================================
  // VERIFICAR SI HAY CASILLAS VACÍAS
  // ============================================
  bool _hayCasillasVacias() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col)) {
          return true;
        }
      }
    }
    return false;
  }

  // ============================================
  // VERIFICAR SI EL TABLERO ESTÁ LLENO DE CULTIVOS
  // ============================================
  bool _estaLlenoDeCultivos() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo != TipoCasilla.cultivo) {
          return false;
        }
      }
    }
    return true;
  }

  // ============================================
  // INVOCAR CULTIVO EN PRIMERA CASILLA VACÍA
  // ============================================
  void _invocarCultivoEnCasillaVacia() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col) && _puedeInvocarCultivo()) {
          final coordenada = yo.tablero.obtenerCoordenadas(fila, col);
          _invocarCultivo(fila, col, coordenada);
          //return;
        }
      }
    }
    print('⚠️ Romanos no pueden invocar más cultivos');
  }

  // ============================================
  // MEJORAR CULTIVOS MASIVAMENTE
  // ============================================
  void _mejorarCultivosMasivamente() {
    if (yo.puntosAcumulados <= 0) return;

    // Primero, recolectar todos los cultivos
    final List<Map<String, int>> cultivos = [];
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.cultivo) {
          cultivos.add({'fila': fila, 'columna': col});
        }
      }
    }

    final int totalCultivos = cultivos.length; // 20 si está lleno
    if (totalCultivos == 0) return;
    if (yo.puntosAcumulados < totalCultivos) {
      // Si tenemos menos puntos que cultivos, repartir de 1 en 1
      print('🌾 Repartiendo puntos de 1 en 1 a $totalCultivos cultivos');
      _repartirPuntosUnoAUno(cultivos);
    } else {
      // Si tenemos más puntos, repartir uniformemente
      final int puntosPorCultivo =
          (yo.puntosAcumulados / totalCultivos).floor();
      final int puntosSobrantes =
          yo.puntosAcumulados - (puntosPorCultivo * totalCultivos);

      print(
        '🌾 Mejorando $totalCultivos cultivos con $puntosPorCultivo puntos cada uno',
      );

      // Mejorar cada cultivo con la cantidad base
      for (var cultivo in cultivos) {
        if (puntosPorCultivo > 0) {
          onMejorar(
            'cultivo',
            cultivo['fila']!,
            cultivo['columna']!,
            puntosPorCultivo,
          );
        }
      }

      // Repartir los puntos sobrantes de 1 en 1
      if (puntosSobrantes > 0) {
        print('🌾 Repartiendo $puntosSobrantes puntos sobrantes de 1 en 1');
        _repartirPuntosUnoAUno(cultivos, maxPuntos: puntosSobrantes);
      }
    }
  }

  // ============================================
  // REPARTIR PUNTOS UNO A UNO (DE FORMA ALEATORIA O POR ORDEN)
  // ============================================
  void _repartirPuntosUnoAUno(
    List<Map<String, int>> cultivos, {
    int maxPuntos = -1,
  }) {
    int puntosARepartir = (maxPuntos == -1) ? yo.puntosAcumulados : maxPuntos;
    if (puntosARepartir <= 0) return;

    // Hacemos una copia de la lista para ir gastando puntos
    int puntosRestantes = puntosARepartir;
    int index = 0;

    while (puntosRestantes > 0 && index < cultivos.length * 2) {
      // Evitar loop infinito
      for (var cultivo in cultivos) {
        if (puntosRestantes <= 0) break;
        onMejorar('cultivo', cultivo['fila']!, cultivo['columna']!, 1);
        puntosRestantes--;
      }
      index++;
    }

    print(
      '✅ Repartidos $puntosARepartir puntos entre ${cultivos.length} cultivos',
    );
  }

  // ============================================
  // VERIFICAR SI PUEDE INVOCAR CULTIVO
  // ============================================
  bool _puedeInvocarCultivo() {
    if (cultivos == null) return false;
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return yo.puntosAcumulados >= cultivo.costoInvocacion;
  }

  // ============================================
  // INVOCAR CULTIVO
  // ============================================
  void _invocarCultivo(int fila, int columna, String coordenada) {
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
    );
    print('🌾 Romanos invocan cultivo ${cultivo.nombre} en $coordenada');
    onInvocar(fila, columna, 'cultivo', cultivo.id);
  }

  void _pasarTurno() {
    print('🏛️ Romanos pasan turno');
    onPasarTurno();
  }
}
