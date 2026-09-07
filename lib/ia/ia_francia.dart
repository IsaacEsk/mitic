import 'package:mitic/models/casilla.dart';
import 'package:mitic/models/guerrero_model.dart';

import 'ia_base.dart';

class IAFrancia extends IABase {
  IAFrancia({
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
    print('🤖 IA Francia analizando situación...');
    print('📊 Puntos acumulados: ${yo.puntosAcumulados}');

    _defenderSiEsNecesario();
    _construirEconomia();
    _construirDefensa();
    _mejorarPosicionesClave();
    _pasarTurno();
  }

  void _defenderSiEsNecesario() {
    final vidaMonumento = yo.tablero.obtenerCasillaPorIndices(0, 2);
    if (vidaMonumento.tipo != TipoCasilla.monumento) return;

    final monumento = vidaMonumento as CasillaMonumento;
    final ataqueAmenaza = _ataqueTotalEnemigo();
    final vidaMinima = ataqueAmenaza + _vidaDeUnGuerreroDisponible();

    if (ataqueAmenaza > 0 && monumento.vidaActual <= vidaMinima) {
      print(
        '🛡️ Francia detecta amenaza: monumento ${monumento.vidaActual} vs ataque $ataqueAmenaza',
      );
      _invocarMejorGuerreroEnPosicionDefensiva();
    }
  }

  int _ataqueTotalEnemigo() {
    var total = 0;
    for (var fila = 0; fila < 4; fila++) {
      for (var columna = 0; columna < 5; columna++) {
        final casilla = enemigo.tablero.obtenerCasillaPorIndices(fila, columna);
        if (casilla.tipo == TipoCasilla.guerrero) {
          total += (casilla as CasillaGuerrero).guerrero.ataqueActual;
        } else if (casilla.tipo == TipoCasilla.torre) {
          total += (casilla as CasillaTorre).torre.ataqueActual;
        }
      }
    }
    return total;
  }

  int _vidaDeUnGuerreroDisponible() {
    final guerreros = yo.guerrerosSeleccionados;
    if (guerreros.isEmpty) return 0;
    return guerreros
        .map((guerrero) => guerrero.vida)
        .reduce((actual, siguiente) => actual > siguiente ? actual : siguiente);
  }

  void _construirEconomia() {
    _invocarSiPosible('cultivo', _posicionesEconomia());
    _invocarSiPosible('cultivo', _posicionesEconomia());
    _invocarSiPosible('aldeano', _posicionesEconomia());

    final cultivos = _casillasDeTipo(TipoCasilla.cultivo);
    if (cultivos.isNotEmpty && yo.puntosAcumulados >= 2) {
      final objetivo = _menorProduccion(cultivos);
      onMejorar('cultivo', objetivo['fila']!, objetivo['columna']!, 2);
    }
  }

  void _construirDefensa() {
    final torres = _casillasDeTipo(TipoCasilla.torre);
    final hospitalesEnCampo = _casillasDeTipo(TipoCasilla.hospital);
    final guerreros = _casillasDeTipo(TipoCasilla.guerrero);

    if (hospitalesEnCampo.isEmpty) {
      _invocarSiPosible('hospital', _posicionesHospital());
    }

    if (torres.length < 2) {
      _invocarSiPosible('torre', _posicionesTorres());
    }

    if (guerreros.length < 3) {
      _invocarSiPosible('guerrero', _posicionesGuerreros());
    }

    if (_hayAmenazaEnemiga() && _puedeInvocarGuerrero()) {
      _invocarSiPosible('guerrero', _posicionesGuerreros());
    }
  }

  void _mejorarPosicionesClave() {
    if (yo.puntosAcumulados <= 0) return;

    final torres = _casillasDeTipo(TipoCasilla.torre);
    final guerreros = _casillasDeTipo(TipoCasilla.guerrero);
    final hospitalesEnCampo = _casillasDeTipo(TipoCasilla.hospital);

    if (torres.isNotEmpty && yo.puntosAcumulados >= 3) {
      final torre = _torreConMenorAtaque(torres);
      final puntos = yo.puntosAcumulados >= 5 ? 3 : yo.puntosAcumulados;
      onMejorar('torre', torre['fila']!, torre['columna']!, puntos);
      return;
    }

    if (guerreros.isNotEmpty && yo.puntosAcumulados >= 2) {
      final guerrero = _guerreroConMayorAtaque(guerreros);
      final puntos = yo.puntosAcumulados >= 4 ? 4 : yo.puntosAcumulados;
      onMejorar('guerrero', guerrero['fila']!, guerrero['columna']!, puntos);
      return;
    }

    if (hospitalesEnCampo.isNotEmpty && yo.puntosAcumulados >= 2) {
      final hospital = hospitalesEnCampo.first;
      final puntos = yo.puntosAcumulados >= 3 ? 3 : yo.puntosAcumulados;
      onMejorar('hospital', hospital['fila']!, hospital['columna']!, puntos);
    }
  }

  void _invocarMejorGuerreroEnPosicionDefensiva() {
    _invocarSiPosible('guerrero', [
      ..._posicionesGuerreros(),
      ..._posicionesHospital(),
    ]);
  }

  void _invocarSiPosible(String tipo, List<Map<String, int>> posiciones) {
    if (posiciones.isEmpty) return;

    final item = _obtenerInvocable(tipo);
    if (item == null || yo.puntosAcumulados < _costo(item)) return;

    for (final posicion in posiciones) {
      final fila = posicion['fila']!;
      final columna = posicion['columna']!;
      if (!yo.tablero.estaVacia(fila, columna)) continue;

      final coordenada = yo.tablero.obtenerCoordenadas(fila, columna);
      print('🇫🇷 Francia invoca $tipo en $coordenada');
      onInvocar(fila, columna, tipo, _id(item));
      return;
    }
  }

  dynamic _obtenerInvocable(String tipo) {
    switch (tipo) {
      case 'aldeano':
        return _primeroDeCivilizacion(aldeanos?.values.toList());
      case 'cultivo':
        return _primeroDeCivilizacion(cultivos?.values.toList());
      case 'hospital':
        return _primeroDeCivilizacion(hospitales?.values.toList());
      case 'torre':
        return _primeroDeCivilizacion(torres?.values.toList());
      case 'guerrero':
        final posibles = yo.guerrerosSeleccionados.toList();
        if (posibles.isEmpty) return null;
        posibles.sort((a, b) => _valorGuerrero(b).compareTo(_valorGuerrero(a)));
        return posibles.first;
    }
    return null;
  }

  dynamic _primeroDeCivilizacion(List<dynamic>? items) {
    if (items == null) return null;
    for (final item in items) {
      if (item.civilizacionId == yo.civilizacion.id) return item;
    }
    return null;
  }

  int _costo(dynamic item) => item.costoInvocacion as int;

  String _id(dynamic item) => item.id as String;

  bool _puedeInvocarGuerrero() {
    return yo.guerrerosSeleccionados.any(
      (guerrero) => guerrero.costoInvocacion <= yo.puntosAcumulados,
    );
  }

  bool _hayAmenazaEnemiga() => _ataqueTotalEnemigo() >= 10;

  List<Map<String, int>> _posicionesEconomia() {
    return [
      {'fila': 0, 'columna': 0},
      {'fila': 0, 'columna': 4},
      {'fila': 1, 'columna': 0},
      {'fila': 1, 'columna': 4},
    ];
  }

  List<Map<String, int>> _posicionesHospital() {
    return [
      {'fila': 1, 'columna': 0},
      {'fila': 1, 'columna': 4},
      {'fila': 2, 'columna': 1},
      {'fila': 2, 'columna': 3},
    ];
  }

  List<Map<String, int>> _posicionesTorres() {
    return [
      {'fila': 1, 'columna': 0},
      {'fila': 1, 'columna': 4},
      {'fila': 1, 'columna': 1},
      {'fila': 1, 'columna': 3},
    ];
  }

  List<Map<String, int>> _posicionesGuerreros() {
    return [
      {'fila': 1, 'columna': 1},
      {'fila': 1, 'columna': 3},
      {'fila': 1, 'columna': 0},
      {'fila': 1, 'columna': 4},
      {'fila': 2, 'columna': 2},
      {'fila': 2, 'columna': 1},
      {'fila': 2, 'columna': 3},
      {'fila': 3, 'columna': 2},
    ];
  }

  List<Map<String, int>> _casillasDeTipo(TipoCasilla tipo) {
    final resultado = <Map<String, int>>[];
    for (var fila = 0; fila < 4; fila++) {
      for (var columna = 0; columna < 5; columna++) {
        if (yo.tablero.obtenerCasillaPorIndices(fila, columna).tipo == tipo) {
          resultado.add({'fila': fila, 'columna': columna});
        }
      }
    }
    return resultado;
  }

  Map<String, int> _menorProduccion(List<Map<String, int>> cultivosEnCampo) {
    var elegido = cultivosEnCampo.first;
    var menor = _produccionEn(elegido);
    for (final cultivo in cultivosEnCampo.skip(1)) {
      final produccion = _produccionEn(cultivo);
      if (produccion < menor) {
        elegido = cultivo;
        menor = produccion;
      }
    }
    return elegido;
  }

  int _produccionEn(Map<String, int> posicion) {
    final casilla =
        yo.tablero.obtenerCasillaPorIndices(
              posicion['fila']!,
              posicion['columna']!,
            )
            as CasillaCultivo;
    return casilla.cultivo.puntosPorTurnoActual;
  }

  Map<String, int> _torreConMenorAtaque(List<Map<String, int>> posiciones) {
    var elegido = posiciones.first;
    var menor = _ataqueTorreEn(elegido);
    for (final torre in posiciones.skip(1)) {
      final ataque = _ataqueTorreEn(torre);
      if (ataque < menor) {
        elegido = torre;
        menor = ataque;
      }
    }
    return elegido;
  }

  int _ataqueTorreEn(Map<String, int> posicion) {
    final casilla =
        yo.tablero.obtenerCasillaPorIndices(
              posicion['fila']!,
              posicion['columna']!,
            )
            as CasillaTorre;
    return casilla.torre.ataqueActual;
  }

  Map<String, int> _guerreroConMayorAtaque(List<Map<String, int>> posiciones) {
    var elegido = posiciones.first;
    var mayor = _ataqueGuerreroEn(elegido);
    for (final guerrero in posiciones.skip(1)) {
      final ataque = _ataqueGuerreroEn(guerrero);
      if (ataque > mayor) {
        elegido = guerrero;
        mayor = ataque;
      }
    }
    return elegido;
  }

  int _ataqueGuerreroEn(Map<String, int> posicion) {
    final casilla =
        yo.tablero.obtenerCasillaPorIndices(
              posicion['fila']!,
              posicion['columna']!,
            )
            as CasillaGuerrero;
    return casilla.guerrero.ataqueActual;
  }

  int _valorGuerrero(Guerrero guerrero) {
    return guerrero.ataque * 3 + guerrero.vida;
  }

  void _pasarTurno() {
    print('🇫🇷 IA Francia pasa turno');
    onPasarTurno();
  }
}
