import 'package:mitic/models/casilla.dart';

import 'ia_base.dart';

class IAAzteca extends IABase {
  IAAzteca({
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
    print('🤖 IA Azteca analizando situación...');

    // 1. PRIORIDAD: INVOCAR CULTIVO Y ALDEANO
    if (_faltaCultivo() && _puedeInvocarCultivo()) {
      _invocarCultivo(0, 0, 'A0');
    }

    if (_faltaAldeanoA0() && _puedeInvocarAldeano()) {
      _invocarAldeano(3, 0, 'A3');
    }

    // 3. INVOCAR GUERREROS EN FILA 1
    final guerrerosEnFila1 = _contarGuerrerosFila1();
    if (guerrerosEnFila1 < 5) {
      // Buscar primera columna vacía en fila 1
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(1, col)) {
          if (_puedeInvocarGuerrero()) {
            final coordenada = yo.tablero.obtenerCoordenadas(1, col);
            _invocarGuerrero(1, col, coordenada);
          }
        }
      }
    }
    if (guerrerosEnFila1 >= 5) {
      // Verificar si falta el aldeano en E0 (fila 0, columna 4)
      final faltaAldeanoE0 =
          yo.tablero.obtenerCasillaPorIndices(0, 4).tipo != TipoCasilla.aldeano;
      if (faltaAldeanoE0 && _puedeInvocarAldeano()) {
        _invocarAldeano(0, 4, 'E0');
        //return;
      }

      // Verificar si falta la torre en D0 (fila 0, columna 3)
      final faltaTorreD0 =
          yo.tablero.obtenerCasillaPorIndices(0, 3).tipo != TipoCasilla.torre;
      if (faltaTorreD0 && _puedeInvocarTorre()) {
        _invocarTorre(0, 3, 'D0');
        //return;
      }

      final faltaTorreB0 =
          yo.tablero.obtenerCasillaPorIndices(0, 1).tipo != TipoCasilla.torre;
      if (faltaTorreB0 && _puedeInvocarTorre()) {
        _invocarTorre(0, 1, 'B0');
        //return;
      }

      // 8. INVOCAR GUERREROS RESTANTES (filas 2 y 3)
      if (_puedeInvocarGuerrero()) {
        for (int fila = 2; fila <= 3; fila++) {
          for (int col = 0; col < 5; col++) {
            if (yo.tablero.estaVacia(fila, col)) {
              final coordenada = yo.tablero.obtenerCoordenadas(fila, col);
              _invocarGuerrero(fila, col, coordenada);
              // return;
            }
          }
        }
      }
    }
    _mejorarGuerrero();

    if (!_faltaCultivo() && random.nextInt(100) < 80) {
      _mejorarCultivo();
    }

    if (_puedeMejorarTorre() && random.nextInt(100) < 50) {
      _mejorarTorre();
      //return;
    }

    if (_puedeMejorarAldeano() && random.nextInt(100) < 30) {
      _mejorarAldeano();
      //return;
    }

    // 7. SI NADA, PASAR TURNO
    _pasarTurno();
  }

  // ============================================
  // ACCIONES DE MEJORA
  // ============================================
  void _mejorarHospital() {
    // 1. Buscar TODOS los hospitales en el tablero
    final List<Map<String, dynamic>> hospitalesEnCampo = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.hospital) {
          hospitalesEnCampo.add({
            'fila': fila,
            'columna': col,
            'hospital': (casilla as CasillaHospital).hospital,
          });
        }
      }
    }

    if (hospitalesEnCampo.isEmpty) return;

    final int cantidad = hospitalesEnCampo.length;
    final int puntosBase = (yo.puntosAcumulados / cantidad).floor();

    if (puntosBase == 0) return;

    // Elegir uno al azar
    final elegido = hospitalesEnCampo[random.nextInt(hospitalesEnCampo.length)];
    final int puntosADonar = random.nextInt(puntosBase) + 1;

    print(
      '🤖 IA mejora hospital en (${elegido['fila']},${elegido['columna']})',
    );
    print('   📊 Hospitales totales: $cantidad, Puntos: $puntosADonar');

    // 👈 ENVIAR COORDENADAS
    onMejorar('hospital', elegido['fila'], elegido['columna'], puntosADonar);
  }

  void _mejorarCultivo() {
    final List<Map<String, dynamic>> cultivosEnCampo = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.cultivo) {
          cultivosEnCampo.add({
            'fila': fila,
            'columna': col,
            'cultivo': (casilla as CasillaCultivo).cultivo,
          });
        }
      }
    }

    if (cultivosEnCampo.isEmpty) return;

    final int cantidad = cultivosEnCampo.length;
    final int puntosBase = (yo.puntosAcumulados / cantidad).floor();

    if (puntosBase == 0) return;

    final elegido = cultivosEnCampo[random.nextInt(cultivosEnCampo.length)];
    final int puntosADonar = puntosBase;

    print('🤖 IA mejora cultivo en (${elegido['fila']},${elegido['columna']})');
    print('   📊 Cultivos: $cantidad, Puntos: $puntosADonar');

    onMejorar('cultivo', elegido['fila'], elegido['columna'], puntosADonar);
  }

  void _mejorarTorre() {
    final List<Map<String, dynamic>> torresEnCampo = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.torre) {
          torresEnCampo.add({
            'fila': fila,
            'columna': col,
            'torre': (casilla as CasillaTorre).torre,
          });
        }
      }
    }

    if (torresEnCampo.isEmpty) return;

    final int cantidad = torresEnCampo.length;
    final int puntosBase = (yo.puntosAcumulados / cantidad).floor();

    if (puntosBase == 0) return;

    final elegido = torresEnCampo[random.nextInt(torresEnCampo.length)];
    final int puntosADonar = random.nextInt(puntosBase) + 1;

    print('🤖 IA mejora torre en (${elegido['fila']},${elegido['columna']})');
    print('   📊 Torres: $cantidad, Puntos: $puntosADonar');

    onMejorar('torre', elegido['fila'], elegido['columna'], puntosADonar);
  }

  void _mejorarGuerrero() {
    final List<Map<String, dynamic>> guerrerosEnCampo = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          guerrerosEnCampo.add({
            'fila': fila,
            'columna': col,
            'guerrero': (casilla as CasillaGuerrero).guerrero,
          });
        }
      }
    }

    if (guerrerosEnCampo.isEmpty) return;

    final int cantidad = guerrerosEnCampo.length;
    final int puntosBase = (yo.puntosAcumulados / cantidad).floor();

    if (puntosBase == 0) return;

    final elegido = guerrerosEnCampo[random.nextInt(guerrerosEnCampo.length)];
    final int puntosADonar = random.nextInt(puntosBase) + 1;

    print(
      '🤖 IA mejora guerrero en (${elegido['fila']},${elegido['columna']})',
    );
    print('   📊 Guerreros: $cantidad, Puntos: $puntosADonar');

    onMejorar(
      'guerrero',
      elegido['fila'],
      elegido['columna'],
      puntosADonar * 2,
    );
  }

  void _mejorarAldeano() {
    final List<Map<String, dynamic>> aldeanosEnCampo = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.aldeano) {
          aldeanosEnCampo.add({
            'fila': fila,
            'columna': col,
            'aldeano': (casilla as CasillaAldeano).aldeano,
          });
        }
      }
    }

    if (aldeanosEnCampo.isEmpty) return;

    final int cantidad = aldeanosEnCampo.length;
    final int puntosBase = (yo.puntosAcumulados / cantidad).floor();

    if (puntosBase == 0) return;

    final elegido = aldeanosEnCampo[random.nextInt(aldeanosEnCampo.length)];
    final int puntosADonar = random.nextInt(puntosBase) + 1;

    print('🤖 IA mejora aldeano en (${elegido['fila']},${elegido['columna']})');
    print('   📊 Aldeanos: $cantidad, Puntos: $puntosADonar');

    onMejorar('aldeano', elegido['fila'], elegido['columna'], puntosADonar);
  }

  // Verifica si falta el cultivo en C0
  bool _faltaCultivo() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(0, 0);
    return casilla.tipo != TipoCasilla.cultivo;
  }

  // Verifica si falta el aldeano en A0
  bool _faltaAldeanoA0() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(3, 0);
    return casilla.tipo != TipoCasilla.aldeano;
  }

  // Verifica si falta el hospital en H0
  bool _faltaHospital() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(0, 1);
    return casilla.tipo != TipoCasilla.hospital;
  }

  // Verifica si falta la torre en T0
  bool _faltaTorre() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(0, 3);
    return casilla.tipo != TipoCasilla.torre;
  }

  bool _puedeMejorarTorre() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.torre) {
          return yo.puntosAcumulados >= 5;
        }
      }
    }
    return false;
  }

  bool _puedeMejorarAldeano() {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = yo.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.aldeano) {
          return yo.puntosAcumulados >= 2;
        }
      }
    }
    return false;
  }

  // Cuenta cuántos guerreros hay en la fila 1 (segunda fila)
  int _contarGuerrerosFila1() {
    int count = 0;
    for (int col = 0; col < 5; col++) {
      final casilla = yo.tablero.obtenerCasillaPorIndices(1, col);
      if (casilla.tipo == TipoCasilla.guerrero) count++;
    }
    return count;
  }

  // ============================================
  // POSICIONES ESTRATÉGICAS MAYAS
  // ============================================
  bool _posicionTorreOcupada() {
    // Torres van en A3 y E3
    final torreA3 = yo.tablero.obtenerCasillaPorIndices(0, 1);
    final torreE3 = yo.tablero.obtenerCasillaPorIndices(0, 3);

    // Retorna true solo si AMBAS están ocupadas
    return (torreA3.tipo == TipoCasilla.torre &&
        torreE3.tipo == TipoCasilla.torre);
  }

  bool _posicionHospitalOcupada() {
    // Hospitales van en toda la fila 1 (A1 a E1)
    for (int col = 0; col < 5; col++) {
      final casilla = yo.tablero.obtenerCasillaPorIndices(1, col);
      if (casilla.tipo != TipoCasilla.hospital) {
        return false; // Si falta alguno, no está completa
      }
    }
    return true;
  }

  bool _posicionAldeanoOcupada() {
    // Aldeanos van en B0 y D0
    final aldeanoB0 = yo.tablero.obtenerCasillaPorIndices(0, 1);
    final aldeanoD0 = yo.tablero.obtenerCasillaPorIndices(0, 3);
    return (aldeanoB0.tipo == TipoCasilla.aldeano &&
        aldeanoD0.tipo == TipoCasilla.aldeano);
  }

  bool _posicionCultivoOcupada() {
    // Cultivos van en A0 y E0
    final cultivoA0 = yo.tablero.obtenerCasillaPorIndices(0, 0);
    final cultivoE0 = yo.tablero.obtenerCasillaPorIndices(0, 4);
    return (cultivoA0.tipo == TipoCasilla.cultivo &&
        cultivoE0.tipo == TipoCasilla.cultivo);
  }

  bool _posicionGuerreroOcupada() {
    // Guerreros ocupan filas 2 y 3 (excepto torres en A3/E3)
    int contador = 0;
    // Filas 2 (completa)
    for (int col = 0; col < 5; col++) {
      final casilla = yo.tablero.obtenerCasillaPorIndices(2, col);
      if (casilla.tipo == TipoCasilla.guerrero) contador++;
    }
    // Filas 3 (excepto columnas 0 y 4 que son torres)
    for (int col = 1; col <= 3; col++) {
      final casilla = yo.tablero.obtenerCasillaPorIndices(3, col);
      if (casilla.tipo == TipoCasilla.guerrero) contador++;
    }
    // Total esperado: 5 (fila2) + 3 (fila3 centro) = 8 guerreros
    return contador >= 8;
  }

  // ============================================
  // VERIFICACIONES ACTUALIZADAS
  // ============================================
  bool _puedeInvocarTorre() {
    // Ya tenemos torres en A3 y E3?
    if (_posicionTorreOcupada()) return false;

    if (torres == null) return false;
    final torre = torres!.values.firstWhere(
      (t) => t.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return yo.puntosAcumulados >= torre.costoInvocacion;
  }

  bool _puedeInvocarHospital() {
    // Ya tenemos todos los hospitales (fila 1 completa)?
    if (_posicionHospitalOcupada()) return false;

    if (hospitales == null) return false;
    final hospital = hospitales!.values.firstWhere(
      (h) => h.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return yo.puntosAcumulados >= hospital.costoInvocacion;
  }

  bool _puedeInvocarAldeano() {
    // Ya tenemos aldeanos en B0 y D0?
    if (_posicionAldeanoOcupada()) return false;

    if (aldeanos == null) return false;
    final aldeano = aldeanos!.values.firstWhere(
      (a) => a.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return yo.puntosAcumulados >= aldeano.costoInvocacion;
  }

  bool _puedeInvocarCultivo() {
    // Ya tenemos cultivos en A0 y E0?
    if (_posicionCultivoOcupada()) return false;

    if (cultivos == null) return false;
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return yo.puntosAcumulados >= cultivo.costoInvocacion;
  }

  bool _puedeInvocarGuerrero() {
    // Ya tenemos suficientes guerreros?
    if (_posicionGuerreroOcupada()) return false;

    // Buscar el guerrero más barato que pueda pagar
    return yo.guerrerosSeleccionados.any(
      (g) => g.costoInvocacion <= yo.puntosAcumulados,
    );
  }

  // ============================================
  // INVOCACIONES
  // ============================================
  void _invocarGuerrero(int fila, int columna, String coordenada) {
    // Buscar los guerreros que pueda pagar
    final posibles =
        yo.guerrerosSeleccionados
            .where((g) => g.costoInvocacion <= yo.puntosAcumulados)
            .toList();

    if (posibles.isEmpty) return;

    // Elegir uno al azar
    final guerrero = posibles[random.nextInt(posibles.length)];

    print('🤖 IA invoca ${guerrero.nombreId} en $coordenada');
    onInvocar(fila, columna, 'guerrero', guerrero.id);
  }

  void _invocarAldeano(int fila, int columna, String coordenada) {
    // 👇 VERIFICAR QUE LA CASILLA ESTÉ VACÍA
    if (!yo.tablero.estaVacia(fila, columna)) {
      print('⚠️ Casilla $coordenada ocupada, no se puede invocar aldeano');
      return;
    }

    if (aldeanos == null) return;
    final aldeano = aldeanos!.values.firstWhere(
      (a) => a.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA invoca ${aldeano.nombre} en $coordenada');
    onInvocar(fila, columna, 'aldeano', aldeano.id);
  }

  void _invocarCultivo(int fila, int columna, String coordenada) {
    // 👇 VERIFICAR QUE LA CASILLA ESTÉ VACÍA
    if (!yo.tablero.estaVacia(fila, columna)) {
      print('⚠️ Casilla $coordenada ocupada, no se puede invocar cultivo');
      return;
    }

    if (cultivos == null) return;
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA invoca ${cultivo.nombre} en $coordenada');
    onInvocar(fila, columna, 'cultivo', cultivo.id);
  }

  void _invocarTorre(int fila, int columna, String coordenada) {
    // 👇 VERIFICAR QUE LA CASILLA ESTÉ VACÍA
    if (!yo.tablero.estaVacia(fila, columna)) {
      print('⚠️ Casilla $coordenada ocupada, no se puede invocar torre');
      return;
    }

    if (torres == null) return;
    final torre = torres!.values.firstWhere(
      (t) => t.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA invoca ${torre.nombre} en $coordenada');
    onInvocar(fila, columna, 'torre', torre.id);
  }

  void _invocarHospital(int fila, int columna, String coordenada) {
    if (hospitales == null) return;
    final hospital = hospitales!.values.firstWhere(
      (h) => h.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA invoca ${hospital.nombre} en $coordenada');
    onInvocar(fila, columna, 'hospital', hospital.id);
  }

  void _pasarTurno() {
    print('🤖 IA Azteca pasa turno');
    onPasarTurno();
  }
}
