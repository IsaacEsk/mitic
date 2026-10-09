import 'package:mitic/models/casilla.dart';

import 'ia_base.dart';

class IAJerusalen extends IABase {
  IAJerusalen({
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
  void tomarDecision() {
    print('🏰 IA Jerusalén analizando situación...');
    print('📊 Puntos acumulados: ${yo.puntosAcumulados}');

    // FASE 1: Llenar cultivos en filas 0 y 1
    _llenarCultivosEnFilas0y1();

    // FASE 2: Invocar guerreros con puntos restantes
    _invocarGuerrerosEnFilas2y3();

    // FASE 3: Mejorar según estado del tablero
    _mejorarSegunEstadoTablero();

    onPasarTurno();
  }

  /// Llena las filas 0 y 1 completamente con cultivos.
  /// No invoca nada más hasta que estas filas estén llenas.
  void _llenarCultivosEnFilas0y1() {
    for (int fila = 0; fila < 2; fila++) {
      for (int columna = 0; columna < 5; columna++) {
        if (yo.tablero.estaVacia(fila, columna)) {
          _invocarCultivo(fila, columna);
        }
      }
    }
  }

  /// Invoca los mayores guerreros posibles en filas 2 y 3.
  void _invocarGuerrerosEnFilas2y3() {
    for (int fila = 2; fila < 4; fila++) {
      for (int columna = 0; columna < 5; columna++) {
        if (yo.tablero.estaVacia(fila, columna)) {
          _invocarGuerrero(fila, columna);
        }
      }
    }
  }

  /// Invoca un cultivo en la posición especificada.
  void _invocarCultivo(int fila, int columna) {
    final cultivo = _obtenerCultivoDeJerusalen();
    if (cultivo == null || yo.puntosAcumulados < cultivo.costoInvocacion) {
      return;
    }

    final coordenada = yo.tablero.obtenerCoordenadas(fila, columna);
    print('🏰 Jerusalén invoca cultivo en $coordenada');
    onInvocar(fila, columna, 'cultivo', cultivo.id);
  }

  /// Invoca el mayor guerrero posible en la posición especificada.
  void _invocarGuerrero(int fila, int columna) {
    final guerrero = _obtenerMayorGuerrero();
    if (guerrero == null || yo.puntosAcumulados < guerrero.costoInvocacion) {
      return;
    }

    final coordenada = yo.tablero.obtenerCoordenadas(fila, columna);
    print('⚔️ Jerusalén invoca guerrero ${guerrero.nombreId} en $coordenada');
    onInvocar(fila, columna, 'guerrero', guerrero.id);
  }

  /// Mejora según el estado del tablero.
  /// Si no está lleno: mejora cultivos.
  /// Si está lleno: 50% cultivos, 50% guerreros.
  void _mejorarSegunEstadoTablero() {
    if (yo.puntosAcumulados <= 0) return;

    if (_tableroLleno()) {
      _mejorar50Cultivos50Guerreros();
    } else {
      _mejorarCultivos();
    }
  }

  /// Verifica si todas las casillas están ocupadas (tablero lleno).
  bool _tableroLleno() {
    for (int fila = 0; fila < 4; fila++) {
      for (int columna = 0; columna < 5; columna++) {
        if (yo.tablero.estaVacia(fila, columna)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Mejora solo cultivos con todos los puntos disponibles.
  void _mejorarCultivos() {
    final cultivos = _obtenerCultivosEnTablero();
    if (cultivos.isEmpty) return;

    final puntos = yo.puntosAcumulados;
    final puntosPorCultivo = puntos ~/ cultivos.length;
    var sobrantes = puntos % cultivos.length;

    for (final cultivo in cultivos) {
      if (yo.puntosAcumulados <= 0) break;

      var puntosAMejorar = puntosPorCultivo;
      if (sobrantes > 0) {
        puntosAMejorar++;
        sobrantes--;
      }

      if (puntosAMejorar > yo.puntosAcumulados) {
        puntosAMejorar = yo.puntosAcumulados;
      }

      if (puntosAMejorar > 0) {
        onMejorar('cultivo', cultivo[0], cultivo[1], puntosAMejorar);
      }
    }
  }

  /// Mejora 50% cultivos y 50% guerreros cuando el tablero está lleno.
  void _mejorar50Cultivos50Guerreros() {
    final puntos = yo.puntosAcumulados;
    final puntosCultivos = puntos ~/ 2;
    final puntosGuerreros = puntos - puntosCultivos;

    _mejorarCultivosConPresupuesto(puntosCultivos);
    _mejorarGuerrerosConPresupuesto(puntosGuerreros);
  }

  /// Mejora cultivos con presupuesto específico.
  void _mejorarCultivosConPresupuesto(int presupuesto) {
    if (presupuesto <= 0) return;

    final cultivos = _obtenerCultivosEnTablero();
    if (cultivos.isEmpty) return;

    var puntosDisponibles = presupuesto;
    final puntosPorCultivo = puntosDisponibles ~/ cultivos.length;
    var sobrantes = puntosDisponibles % cultivos.length;

    for (final cultivo in cultivos) {
      if (puntosDisponibles <= 0) break;

      var puntosAMejorar = puntosPorCultivo;
      if (sobrantes > 0) {
        puntosAMejorar++;
        sobrantes--;
      }

      if (puntosAMejorar > puntosDisponibles) {
        puntosAMejorar = puntosDisponibles;
      }

      if (puntosAMejorar > 0 && yo.puntosAcumulados > 0) {
        final puntosReales =
            puntosAMejorar > yo.puntosAcumulados
                ? yo.puntosAcumulados
                : puntosAMejorar;
        onMejorar('cultivo', cultivo[0], cultivo[1], puntosReales);
        puntosDisponibles -= puntosReales;
      }
    }
  }

  /// Mejora guerreros con presupuesto específico.
  void _mejorarGuerrerosConPresupuesto(int presupuesto) {
    if (presupuesto <= 0) return;

    final guerreros = _obtenerGuerrerosEnTablero();
    if (guerreros.isEmpty) return;

    var puntosDisponibles = presupuesto;
    final puntosPorGuerrero = puntosDisponibles ~/ guerreros.length;
    var sobrantes = puntosDisponibles % guerreros.length;

    for (final guerrero in guerreros) {
      if (puntosDisponibles <= 0) break;

      var puntosAMejorar = puntosPorGuerrero;
      if (sobrantes > 0) {
        puntosAMejorar++;
        sobrantes--;
      }

      if (puntosAMejorar > puntosDisponibles) {
        puntosAMejorar = puntosDisponibles;
      }

      if (puntosAMejorar > 0 && yo.puntosAcumulados > 0) {
        final puntosReales =
            puntosAMejorar > yo.puntosAcumulados
                ? yo.puntosAcumulados
                : puntosAMejorar;
        onMejorar('guerrero', guerrero[0], guerrero[1], puntosReales);
        puntosDisponibles -= puntosReales;
      }
    }
  }

  /// Obtiene el cultivo de Jerusalén del catálogo.
  dynamic _obtenerCultivoDeJerusalen() {
    if (cultivos == null) return null;
    for (final cultivo in cultivos!.values) {
      if (cultivo.civilizacionId == yo.civilizacion.id) {
        return cultivo;
      }
    }
    return null;
  }

  /// Obtiene el mayor guerrero disponible de Jerusalén.
  dynamic _obtenerMayorGuerrero() {
    final posibles =
        yo.guerrerosSeleccionados
            .where((g) => g.costoInvocacion <= yo.puntosAcumulados)
            .toList();
    if (posibles.isEmpty) return null;

    // Ordenar por ataque descendente
    posibles.sort((a, b) => b.ataque.compareTo(a.ataque));
    return posibles.first;
  }

  /// Obtiene todas las posiciones de cultivos en el tablero.
  List<List<int>> _obtenerCultivosEnTablero() {
    final resultado = <List<int>>[];
    for (int fila = 0; fila < 4; fila++) {
      for (int columna = 0; columna < 5; columna++) {
        if (yo.tablero.obtenerCasillaPorIndices(fila, columna).tipo ==
            TipoCasilla.cultivo) {
          resultado.add([fila, columna]);
        }
      }
    }
    return resultado;
  }

  /// Obtiene todas las posiciones de guerreros en el tablero.
  List<List<int>> _obtenerGuerrerosEnTablero() {
    final resultado = <List<int>>[];
    for (int fila = 0; fila < 4; fila++) {
      for (int columna = 0; columna < 5; columna++) {
        if (yo.tablero.obtenerCasillaPorIndices(fila, columna).tipo ==
            TipoCasilla.guerrero) {
          resultado.add([fila, columna]);
        }
      }
    }
    return resultado;
  }
}
