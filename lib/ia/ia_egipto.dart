import 'package:mitic/models/casilla.dart';

import 'ia_base.dart';

class IAEgipto extends IABase {
  IAEgipto({
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

  int _puntosParaInvocar = 0;
  int _puntosParaMejorar = 0;

  @override
  void tomarDecision() {
    print('IA Egipto analizando situacion...');

    final puntosIniciales = yo.puntosAcumulados;
    _puntosParaMejorar = puntosIniciales ~/ 2;
    _puntosParaInvocar = puntosIniciales - _puntosParaMejorar;

    _reponerFormacionPrincipal();
    _completarTorresYGuerreros();

    // Los puntos de invocacion que no se gastaron pasan a mejoras.
    _puntosParaMejorar += _puntosParaInvocar;
    _puntosParaInvocar = 0;
    _mejorarPorCategorias();

    onPasarTurno();
  }

  void _reponerFormacionPrincipal() {
    _invocarEnPosicion('cultivo', 0, 1, esFormacionPrincipal: true);
    _invocarEnPosicion('cultivo', 0, 3, esFormacionPrincipal: true);
    _invocarEnPosicion('aldeano', 1, 3, esFormacionPrincipal: true);
    _invocarEnPosicion('hospital', 1, 1, esFormacionPrincipal: true);
  }

  void _completarTorresYGuerreros() {
    for (final posicion in _posicionesTorres) {
      _invocarEnPosicion('torre', posicion[0], posicion[1]);
    }
    for (final posicion in _posicionesGuerreros) {
      _invocarEnPosicion('guerrero', posicion[0], posicion[1]);
    }
  }

  void _invocarEnPosicion(
    String tipo,
    int fila,
    int columna, {
    bool esFormacionPrincipal = false,
  }) {
    if ((!esFormacionPrincipal && _puntosParaInvocar <= 0) ||
        !yo.tablero.estaVacia(fila, columna)) {
      return;
    }

    final item = _obtenerInvocable(tipo);
    if (item == null) return;

    final costo = item.costoInvocacion as int;
    final puntosDisponibles =
        esFormacionPrincipal ? yo.puntosAcumulados : _puntosParaInvocar;
    if (puntosDisponibles < costo || yo.puntosAcumulados < costo) return;

    final coordenada = yo.tablero.obtenerCoordenadas(fila, columna);
    print('Egipto invoca $tipo en $coordenada');
    onInvocar(fila, columna, tipo, item.id as String);
    if (_puntosParaInvocar >= costo) {
      _puntosParaInvocar -= costo;
    } else {
      _puntosParaMejorar -= costo - _puntosParaInvocar;
      _puntosParaInvocar = 0;
    }
  }

  void _mejorarPorCategorias() {
    if (_puntosParaMejorar <= 0) return;

    final categorias = <String, List<List<int>>>{};
    final cultivoClave = [0, 3];
    if (_esTipo(cultivoClave[0], cultivoClave[1], TipoCasilla.cultivo)) {
      categorias['cultivo'] = [cultivoClave];
    }

    _agregarCategoria(categorias, 'aldeano', TipoCasilla.aldeano);
    _agregarCategoria(categorias, 'hospital', TipoCasilla.hospital);
    _agregarCategoria(categorias, 'torre', TipoCasilla.torre);
    _agregarCategoria(categorias, 'guerrero', TipoCasilla.guerrero);

    if (categorias.isEmpty) return;

    final puntosPorCategoria = _puntosParaMejorar ~/ categorias.length;
    var sobrantes = _puntosParaMejorar % categorias.length;

    for (final entrada in categorias.entries) {
      var puntos = puntosPorCategoria;
      if (sobrantes > 0) {
        puntos++;
        sobrantes--;
      }
      _repartirEntreCasillas(entrada.key, entrada.value, puntos);
    }
  }

  void _agregarCategoria(
    Map<String, List<List<int>>> categorias,
    String tipo,
    TipoCasilla tipoCasilla,
  ) {
    final posiciones = <List<int>>[];
    for (var fila = 0; fila < 4; fila++) {
      for (var columna = 0; columna < 5; columna++) {
        if (_esTipo(fila, columna, tipoCasilla)) {
          posiciones.add([fila, columna]);
        }
      }
    }
    if (posiciones.isNotEmpty) categorias[tipo] = posiciones;
  }

  void _repartirEntreCasillas(
    String tipo,
    List<List<int>> posiciones,
    int puntos,
  ) {
    if (puntos <= 0 || posiciones.isEmpty) return;

    final base = puntos ~/ posiciones.length;
    var sobrantes = puntos % posiciones.length;
    for (final posicion in posiciones) {
      var puntosParaCasilla = base;
      if (sobrantes > 0) {
        puntosParaCasilla++;
        sobrantes--;
      }
      if (puntosParaCasilla <= 0 || yo.puntosAcumulados <= 0) continue;

      final puntosReales =
          puntosParaCasilla > yo.puntosAcumulados
              ? yo.puntosAcumulados
              : puntosParaCasilla;
      onMejorar(tipo, posicion[0], posicion[1], puntosReales);
    }
  }

  bool _esTipo(int fila, int columna, TipoCasilla tipo) {
    return yo.tablero.obtenerCasillaPorIndices(fila, columna).tipo == tipo;
  }

  dynamic _obtenerInvocable(String tipo) {
    if (tipo == 'guerrero') {
      final posibles =
          yo.guerrerosSeleccionados
              .where(
                (guerrero) => guerrero.costoInvocacion <= yo.puntosAcumulados,
              )
              .toList();
      if (posibles.isEmpty) return null;
      posibles.sort((a, b) => b.ataque.compareTo(a.ataque));
      return posibles.first;
    }

    final Iterable<dynamic>? items = switch (tipo) {
      'aldeano' => aldeanos?.values,
      'cultivo' => cultivos?.values,
      'hospital' => hospitales?.values,
      'torre' => torres?.values,
      _ => null,
    };
    if (items == null) return null;
    for (final item in items) {
      if (item.civilizacionId == yo.civilizacion.id) return item;
    }
    return null;
  }

  static const _posicionesTorres = [
    [1, 0],
    [1, 4],
    [2, 1],
    [2, 3],
    [3, 2],
  ];

  static const _posicionesGuerreros = [
    [0, 0],
    [0, 4],
    [1, 2],
    [2, 0],
    [2, 4],
    [3, 1],
    [3, 3],
  ];
}
