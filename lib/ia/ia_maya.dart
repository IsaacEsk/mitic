import 'ia_base.dart';

class IAMaya extends IABase {
  IAMaya({
    required super.juego,
    required super.yo,
    required super.enemigo,
    required super.onPasarTurno,
    required super.aldeanos,
    required super.cultivos,
    required super.torres,
    required super.hospitales,
    required super.onInvocar,
  });

  @override
  void tomarDecision() {
    print('🤖 IA Maya analizando situación...');

    // ============================================
    // MIENTRAS TENGA PUNTOS Y CASILLAS VACÍAS, INVOCAR
    // ============================================
    while (_puedeInvocar()) {
      _invocarAlgo();
    }

    // Cuando ya no pueda invocar más, pasa turno
    _pasarTurno();
  }

  bool _puedeInvocar() {
    final costoMinimo = _getCostoMinimo();
    return yo.puntosAcumulados >= costoMinimo && hayCasillasVacias();
  }

  int _getCostoMinimo() {
    int minimo = 999;

    // Buscar el costo más bajo entre todo lo que puede invocar
    if (aldeanos != null) {
      final aldeano = aldeanos!.values.firstWhere(
        (a) => a.civilizacionId == yo.civilizacion.id,
        //orElse: () => null,
      );
      if (aldeano != null && aldeano.costoInvocacion < minimo) {
        minimo = aldeano.costoInvocacion;
      }
    }

    if (cultivos != null) {
      final cultivo = cultivos!.values.firstWhere(
        (c) => c.civilizacionId == yo.civilizacion.id,
        //orElse: () => null,
      );
      if (cultivo != null && cultivo.costoInvocacion < minimo) {
        minimo = cultivo.costoInvocacion;
      }
    }

    if (torres != null) {
      final torre = torres!.values.firstWhere(
        (t) => t.civilizacionId == yo.civilizacion.id,
        //orElse: () => null,
      );
      if (torre != null && torre.costoInvocacion < minimo) {
        minimo = torre.costoInvocacion;
      }
    }

    if (hospitales != null) {
      final hospital = hospitales!.values.firstWhere(
        (h) => h.civilizacionId == yo.civilizacion.id,
        // orElse: () => null,
      );
      if (hospital != null && hospital.costoInvocacion < minimo) {
        minimo = hospital.costoInvocacion;
      }
    }

    // Guerreros (del jugador)
    for (var guerrero in yo.guerrerosSeleccionados) {
      if (guerrero.costoInvocacion < minimo) {
        minimo = guerrero.costoInvocacion;
      }
    }

    return minimo;
  }

  void _invocarAlgo() {
    final casillasVacias = getCasillasVacias();
    if (casillasVacias.isEmpty) return;

    final casilla = casillasVacias[random.nextInt(casillasVacias.length)];
    final fila = casilla['fila']!;
    final columna = casilla['columna']!;
    final coordenada = yo.tablero.obtenerCoordenadas(fila, columna);

    // ============================================
    // DECIDIR QUÉ INVOCAR (prioridades con porcentajes)
    // ============================================

    // 1. Torres (70%)
    if (random.nextInt(100) < 70 && _puedeInvocarTorre()) {
      _invocarTorre(fila, columna, coordenada);
      return;
    }

    // 2. Hospitales (20%)
    if (random.nextInt(100) < 20 && _puedeInvocarHospital()) {
      _invocarHospital(fila, columna, coordenada);
      return;
    }

    // 3. Aldeano (20% de lo que queda, pero ajustamos)
    if (random.nextInt(100) < 20 && _puedeInvocarAldeano()) {
      _invocarAldeano(fila, columna, coordenada);
      return;
    }

    // 4. Cultivo (restante)
    if (random.nextInt(100) < 20 && _puedeInvocarCultivo()) {
      _invocarCultivo(fila, columna, coordenada);
      return;
    }
  }

  // ============================================
  // VERIFICACIONES
  // ============================================
  bool _puedeInvocarGuerrero() {
    // Buscar el guerrero más barato que pueda pagar
    return yo.guerrerosSeleccionados.any(
      (g) => g.costoInvocacion <= yo.puntosAcumulados,
    );
  }

  bool _puedeInvocarAldeano() {
    if (aldeanos == null) return false;
    final aldeano = aldeanos!.values.firstWhere(
      (a) => a.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return aldeano != null && yo.puntosAcumulados >= aldeano.costoInvocacion;
  }

  bool _puedeInvocarCultivo() {
    if (cultivos == null) return false;
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return cultivo != null && yo.puntosAcumulados >= cultivo.costoInvocacion;
  }

  bool _puedeInvocarTorre() {
    if (torres == null) return false;
    final torre = torres!.values.firstWhere(
      (t) => t.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return torre != null && yo.puntosAcumulados >= torre.costoInvocacion;
  }

  bool _puedeInvocarHospital() {
    if (hospitales == null) return false;
    final hospital = hospitales!.values.firstWhere(
      (h) => h.civilizacionId == yo.civilizacion.id,
      //orElse: () => null,
    );
    return hospital != null && yo.puntosAcumulados >= hospital.costoInvocacion;
  }

  // ============================================
  // INVOCACIONES
  // ============================================
  void _invocarGuerrero(int fila, int columna, String coordenada) {
    // Buscar el guerrero más barato que pueda pagar
    final posibles =
        yo.guerrerosSeleccionados
            .where((g) => g.costoInvocacion <= yo.puntosAcumulados)
            .toList();

    if (posibles.isEmpty) return;

    // Ordenar por costo (invierte para que el más caro sea más probable? mejor el más barato)
    posibles.sort((a, b) => a.costoInvocacion.compareTo(b.costoInvocacion));
    final guerrero = posibles.first;

    print('🤖 IA invoca ${guerrero.nombreId} en $coordenada');
    onInvocar(fila, columna, 'guerrero', guerrero.id);
  }

  void _invocarAldeano(int fila, int columna, String coordenada) {
    if (aldeanos == null) return;
    final aldeano = aldeanos!.values.firstWhere(
      (a) => a.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA invoca ${aldeano.nombre} en $coordenada');
    onInvocar(fila, columna, 'aldeano', aldeano.id);
  }

  void _invocarCultivo(int fila, int columna, String coordenada) {
    if (cultivos == null) return;
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA invoca ${cultivo.nombre} en $coordenada');
    onInvocar(fila, columna, 'cultivo', cultivo.id);
  }

  void _invocarTorre(int fila, int columna, String coordenada) {
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
    print('🤖 IA Maya pasa turno');
    onPasarTurno();
  }
}
