import 'dart:math';
import 'package:mitic/models/casilla.dart';

import 'ia_base.dart';

class IASarracenos extends IABase {
  IASarracenos({
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
    print('🤖 IA Sarracenos analizando situación...');
    print('📊 Puntos acumulados: ${yo.puntosAcumulados}');
    print('⚔️ Guerreros en campo: ${_contarGuerrerosEnCampo()}');

    // ============================================
    // PRIORIDAD: INVOCAR GUERREROS HASTA TENER 5
    // ============================================
    final cantidadGuerreros = _contarGuerrerosEnCampo();

    if (cantidadGuerreros < 5) {
      _construirEjercito();
      _pasarTurno();
      return;
    }

    // ============================================
    // SI YA TIENE 5 GUERREROS: 50% MEJORAR / 50% INVOCAR
    // ============================================
    final random = Random().nextInt(100);

    if (random < 50) {
      print('🎲 50% - Decisión: MEJORAR');
      _mejorarPorPorcentaje();
    }
    _invocarPorPorcentaje();
    // else {
    //   print('🎲 50% - Decisión: INVOCAR');
    //   _invocarPorPorcentaje();
    // }
    _pasarTurno();
  }

  // ============================================
  // CONTAR GUERREROS EN CAMPO
  // ============================================
  int _contarGuerrerosEnCampo() {
    int contador = 0;
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          contador++;
        }
      }
    }
    return contador;
  }

  // ============================================
  // CONSTRUIR EJÉRCITO (INVOCAR GUERRERO)
  // ============================================
  void _construirEjercito() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col) && _puedeInvocarGuerrero()) {
          final coordenada = yo.tablero.obtenerCoordenadas(fila, col);
          _invocarGuerrero(fila, col, coordenada);
          return;
        }
      }
    }
    print('⚠️ Sarracenos no puede invocar más guerreros');
    //_pasarTurno();
  }

  // ============================================
  // MEJORAR SEGÚN PORCENTAJES
  // ============================================
  void _mejorarPorPorcentaje() {
    final random = Random().nextInt(100);

    if (random < 45) {
      // 45% guerreros
      print('⚔️ Mejorando guerreros');
      _mejorarGuerreros();
    } else if (random < 65) {
      // 20% hospitales
      print('🏥 Mejorando hospitales');
      _mejorarHospitales();
    } else if (random < 85) {
      // 20% torres
      print('🗼 Mejorando torres');
      _mejorarTorres();
    } else if (random < 90) {
      // 5% aldeanos
      print('🔨 Mejorando aldeanos');
      _mejorarAldeanos();
    } else {
      // 10% cultivos
      print('🌾 Mejorando cultivos');
      _mejorarCultivos();
    }
  }

  // ============================================
  // INVOCAR SEGÚN PORCENTAJES
  // ============================================
  void _invocarPorPorcentaje() {
    final random = Random().nextInt(100);

    if (random < 30) {
      // 30% guerrero
      print('⚔️ Invocando guerrero');
      _invocarGuerreroEnFila12();
    } else if (random < 50) {
      // 20% torre
      print('🗼 Invocando torre');
      _invocarTorreEnFila3();
    } else if (random < 70) {
      // 20% hospital
      print('🏥 Invocando hospital');
      _invocarHospitalEnCualquierFila();
    } else if (random < 90) {
      // 20% cultivo
      print('🌾 Invocando cultivo');
      _invocarCultivoEnCualquierFila();
    } else {
      // 10% aldeano
      print('🔨 Invocando aldeano');
      _invocarAldeanoEnCualquierFila();
    }
  }

  // ============================================
  // MEJORAS
  // ============================================
  void _mejorarGuerreros() {
    final List<Map<String, dynamic>> items = [];
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          items.add({
            'fila': fila,
            'columna': col,
            'objeto': (casilla as CasillaGuerrero).guerrero,
          });
        }
      }
    }
    _mejorarItems(items, 'guerrero', 'ataque');
  }

  void _mejorarHospitales() {
    final List<Map<String, dynamic>> items = [];
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.hospital) {
          items.add({
            'fila': fila,
            'columna': col,
            'objeto': (casilla as CasillaHospital).hospital,
          });
        }
      }
    }
    _mejorarItems(items, 'hospital', 'poderCuracion');
  }

  void _mejorarTorres() {
    final List<Map<String, dynamic>> items = [];
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.torre) {
          items.add({
            'fila': fila,
            'columna': col,
            'objeto': (casilla as CasillaTorre).torre,
          });
        }
      }
    }
    _mejorarItems(items, 'torre', 'ataque');
  }

  void _mejorarAldeanos() {
    final List<Map<String, dynamic>> items = [];
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.aldeano) {
          items.add({
            'fila': fila,
            'columna': col,
            'objeto': (casilla as CasillaAldeano).aldeano,
          });
        }
      }
    }
    _mejorarItems(items, 'aldeano', 'puntosReconstruccion');
  }

  void _mejorarCultivos() {
    final List<Map<String, dynamic>> items = [];
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.cultivo) {
          items.add({
            'fila': fila,
            'columna': col,
            'objeto': (casilla as CasillaCultivo).cultivo,
          });
        }
      }
    }
    _mejorarItems(items, 'cultivo', 'puntosPorTurno');
  }

  void _mejorarItems(
    List<Map<String, dynamic>> items,
    String tipo,
    String atributo,
  ) {
    if (items.isEmpty || yo.puntosAcumulados < 5) return;

    final int puntosPorItem = (yo.puntosAcumulados / items.length).floor();
    if (puntosPorItem == 0) return;

    for (var item in items) {
      onMejorar(
        tipo,
        item['fila'] as int,
        item['columna'] as int,
        puntosPorItem,
      );
    }
  }

  // ============================================
  // INVOCACIONES ESPECÍFICAS
  // ============================================
  void _invocarGuerreroEnFila12() {
    for (int fila = 1; fila <= 2; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col) && _puedeInvocarGuerrero()) {
          final coordenada = yo.tablero.obtenerCoordenadas(fila, col);
          _invocarGuerrero(fila, col, coordenada);
          return;
        }
      }
    }
    print('⚠️ No hay espacio para guerrero en filas 1-2');
  }

  void _invocarTorreEnFila3() {
    for (int col = 0; col < 5; col++) {
      if (yo.tablero.estaVacia(3, col) && _puedeInvocarTorre()) {
        final coordenada = yo.tablero.obtenerCoordenadas(3, col);
        _invocarTorre(3, col, coordenada);
        return;
      }
    }
    print('⚠️ No hay espacio para torre en fila 3');
  }

  void _invocarHospitalEnCualquierFila() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col) && _puedeInvocarHospital()) {
          final coordenada = yo.tablero.obtenerCoordenadas(fila, col);
          _invocarHospital(fila, col, coordenada);
          return;
        }
      }
    }
    print('⚠️ No hay espacio para hospital');
  }

  void _invocarCultivoEnCualquierFila() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col) && _puedeInvocarCultivo()) {
          final coordenada = yo.tablero.obtenerCoordenadas(fila, col);
          _invocarCultivo(fila, col, coordenada);
          return;
        }
      }
    }
    print('⚠️ No hay espacio para cultivo');
  }

  void _invocarAldeanoEnCualquierFila() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col) && _puedeInvocarAldeano()) {
          final coordenada = yo.tablero.obtenerCoordenadas(fila, col);
          _invocarAldeano(fila, col, coordenada);
          return;
        }
      }
    }
    print('⚠️ No hay espacio para aldeano');
  }

  // ============================================
  // VERIFICACIONES DE INVOCACIÓN
  // ============================================
  bool _puedeInvocarGuerrero() {
    return yo.guerrerosSeleccionados.any(
      (g) => g.costoInvocacion <= yo.puntosAcumulados,
    );
  }

  bool _puedeInvocarTorre() {
    if (torres == null) return false;
    final torre = torres!.values.firstWhere(
      (t) => t.civilizacionId == yo.civilizacion.id,
    );
    return yo.puntosAcumulados >= torre.costoInvocacion;
  }

  bool _puedeInvocarHospital() {
    if (hospitales == null) return false;
    final hospital = hospitales!.values.firstWhere(
      (h) => h.civilizacionId == yo.civilizacion.id,
    );
    return yo.puntosAcumulados >= hospital.costoInvocacion;
  }

  bool _puedeInvocarCultivo() {
    if (cultivos == null) return false;
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
    );
    return yo.puntosAcumulados >= cultivo.costoInvocacion;
  }

  bool _puedeInvocarAldeano() {
    if (aldeanos == null) return false;
    final aldeano = aldeanos!.values.firstWhere(
      (a) => a.civilizacionId == yo.civilizacion.id,
    );
    return yo.puntosAcumulados >= aldeano.costoInvocacion;
  }

  // ============================================
  // INVOCACIONES REALES
  // ============================================
  void _invocarGuerrero(int fila, int columna, String coordenada) {
    final posibles =
        yo.guerrerosSeleccionados
            .where((g) => g.costoInvocacion <= yo.puntosAcumulados)
            .toList();
    if (posibles.isEmpty) return;
    posibles.sort((a, b) => b.ataque.compareTo(a.ataque));
    final guerrero = posibles.first;
    print('🤖 Sarracenos invoca guerrero ${guerrero.nombreId} en $coordenada');
    onInvocar(fila, columna, 'guerrero', guerrero.id);
  }

  void _invocarTorre(int fila, int columna, String coordenada) {
    final torre = torres!.values.firstWhere(
      (t) => t.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 Sarracenos invoca torre ${torre.nombre} en $coordenada');
    onInvocar(fila, columna, 'torre', torre.id);
  }

  void _invocarHospital(int fila, int columna, String coordenada) {
    final hospital = hospitales!.values.firstWhere(
      (h) => h.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 Sarracenos invoca hospital ${hospital.nombre} en $coordenada');
    onInvocar(fila, columna, 'hospital', hospital.id);
  }

  void _invocarCultivo(int fila, int columna, String coordenada) {
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 Sarracenos invoca cultivo ${cultivo.nombre} en $coordenada');
    onInvocar(fila, columna, 'cultivo', cultivo.id);
  }

  void _invocarAldeano(int fila, int columna, String coordenada) {
    final aldeano = aldeanos!.values.firstWhere(
      (a) => a.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 Sarracenos invoca aldeano ${aldeano.nombre} en $coordenada');
    onInvocar(fila, columna, 'aldeano', aldeano.id);
  }

  void _pasarTurno() {
    print('🤖 Sarracenos pasan turno');
    onPasarTurno();
  }
}
