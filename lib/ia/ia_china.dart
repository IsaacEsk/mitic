import 'dart:math';

import 'package:mitic/models/aldeano_campo.dart';
import 'package:mitic/models/casilla.dart';
import 'package:mitic/models/guerrero_field_model_2.0.dart';
import 'package:mitic/models/hospital_campo.dart';
import 'package:mitic/models/torre_campo.dart';

import 'ia_base.dart';

class IAChina extends IABase {
  IAChina({
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
    print('🤖 IA China analizando situación...');
    print('📊 Puntos acumulados: ${yo.puntosAcumulados}');

    // ============================================
    // PRIORIDAD: CONSTRUIR INFRAESTRUCTURA (menos de 100 puntos)
    // ============================================
    if (yo.puntosAcumulados < 100) {
      _construirInfraestructura();
      return;
    }

    // ============================================
    // PRIORIDAD: EXPANSIÓN Y MEJORAS (más de 100 puntos)
    // ============================================
    _expandirYMejorar();
  }

  // ============================================
  // FASE 1: CONSTRUIR INFRAESTRUCTURA
  // ============================================
  void _construirInfraestructura() {
    // 1. Invocar aldeano en A3 (3,0)
    if (_faltaAldeanoA3() && _puedeInvocarAldeano()) {
      _invocarAldeano(2, 0, 'A2');
      //return;
    }

    // 2. Invocar cultivo en A0 (0,0)
    if (_faltaCultivoA0() && _puedeInvocarCultivo()) {
      _invocarCultivo(0, 0, 'A0');
      //return;
    }

    // 3. Invocar hospital en B3 (3,1)
    if (_faltaHospitalB3() && _puedeInvocarHospital()) {
      _invocarHospital(2, 1, 'B2');
      //return;
    }

    // 4. Invocar cultivo en B0 (0,1)
    if (_faltaCultivoB0() && !_faltaHospitalB3() && _puedeInvocarCultivo()) {
      _invocarCultivo(0, 1, 'B0');
      //return;
    }

    // 5. Mejorar cultivo en A0 (si ya existe y hay puntos)
    if (_cultivoA0Existe()) {
      _mejorarCultivoA0();
      //return;
    }

    // Si no hay nada que construir, pasar turno
    _pasarTurno();
  }

  // ============================================
  // FASE 2: EXPANSIÓN Y MEJORAS
  // ============================================
  void _expandirYMejorar() {
    if (_faltaCultivoB0() && _puedeInvocarCultivo()) {
      _invocarCultivo(0, 1, 'B0');
    }

    if (_cultivoA0Existe()) {
      final random = Random().nextInt(100);
      if (random < 15) {
        _mejorarCultivoA0();
      }
    }

    // Prioridad: invocar torres en la fila 3
    final posicionesTorres = [
      {'fila': 3, 'columna': 0, 'coordenada': 'A3'}, // A3
      {'fila': 3, 'columna': 1, 'coordenada': 'B3'}, // B3 (hospital ya está)
      {'fila': 3, 'columna': 2, 'coordenada': 'C3'}, // C3
      {'fila': 3, 'columna': 3, 'coordenada': 'D3'}, // D3
      {'fila': 3, 'columna': 4, 'coordenada': 'E3'}, // E3
    ];

    bool invoquetorre = false;
    for (var pos in posicionesTorres) {
      final fila = pos['fila']! as int;
      final columna = pos['columna']! as int;
      final coordenada = pos['coordenada']! as String;

      if (_faltaTorreEn(fila, columna) && _puedeInvocarTorre()) {
        _invocarTorre(fila, columna, coordenada);
        invoquetorre = true;
        //break;
      }
    }

    if (yo.puntosAcumulados > 0) {
      final random = Random().nextInt(100);
      if (random < 20) {
        _mejorarTodasLasTorres();
      } else {
        _invocarTorresAdicionales();
        invoquetorre = true;
      }
    }
    _invocarAleatoriamente();

    if (yo.puntosAcumulados > 0) {
      _mejorarTodo();
    }

    _pasarTurno();
  }

  // ============================================
  // MEJORAR TODO (SEGÚN PROBABILIDADES)
  // ============================================
  void _mejorarTodo() {
    if (yo.puntosAcumulados <= 0) return;

    final random = Random().nextInt(100);

    if (random < 40) {
      // 40% - Mejorar torres
      _mejorarTodasLasTorres();
    } else if (random < 80) {
      // 40% - Mejorar guerreros
      _mejorarTodosLosGuerreros();
    } else if (random < 90) {
      // 10% - Mejorar aldeanos
      _mejorarTodosLosAldeanos();
    } else {
      // 10% - Mejorar hospitales
      _mejorarTodosLosHospitales();
    }
  }

  // ============================================
  // MEJORAR TODOS LOS GUERREROS
  // ============================================
  void _mejorarTodosLosGuerreros() {
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

    if (guerrerosEnCampo.isEmpty) {
      print('⚔️ No hay guerreros para mejorar');
      return;
    }

    final int cantidad = guerrerosEnCampo.length;
    final int puntosPorGuerrero = (yo.puntosAcumulados ~/ cantidad).floor();

    if (puntosPorGuerrero == 0) {
      print('⚔️ Puntos insuficientes para mejorar guerreros');
      return;
    }

    print(
      '⚔️ Mejorando $cantidad guerreros con $puntosPorGuerrero puntos cada uno',
    );

    for (var g in guerrerosEnCampo) {
      final fila = g['fila'] as int;
      final columna = g['columna'] as int;
      final guerrero = g['guerrero'] as GuerreroCampo;
      print(
        '   ⚔️ Mejorando guerrero en ($fila,$columna) (ataque actual: ${guerrero.ataqueActual})',
      );
      onMejorar('guerrero', fila, columna, puntosPorGuerrero);
    }
  }

  // ============================================
  // MEJORAR TODOS LOS ALDEANOS
  // ============================================
  void _mejorarTodosLosAldeanos() {
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

    if (aldeanosEnCampo.isEmpty) {
      print('🔨 No hay aldeanos para mejorar');
      return;
    }

    final int cantidad = aldeanosEnCampo.length;
    final int puntosPorAldeano = (yo.puntosAcumulados ~/ cantidad).floor();

    if (puntosPorAldeano == 0) {
      print('🔨 Puntos insuficientes para mejorar aldeanos');
      return;
    }

    print(
      '🔨 Mejorando $cantidad aldeanos con $puntosPorAldeano puntos cada uno',
    );

    for (var a in aldeanosEnCampo) {
      final fila = a['fila'] as int;
      final columna = a['columna'] as int;
      final aldeano = a['aldeano'] as AldeanoCampo;
      print(
        '   🔨 Mejorando aldeano en ($fila,$columna) (reconstrucción actual: ${aldeano.puntosReconstruccionActual})',
      );
      onMejorar('aldeano', fila, columna, puntosPorAldeano);
    }
  }

  // ============================================
  // MEJORAR TODOS LOS HOSPITALES
  // ============================================
  void _mejorarTodosLosHospitales() {
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

    if (hospitalesEnCampo.isEmpty) {
      print('🏥 No hay hospitales para mejorar');
      return;
    }

    final int cantidad = hospitalesEnCampo.length;
    final int puntosPorHospital = (yo.puntosAcumulados ~/ cantidad).floor();

    if (puntosPorHospital == 0) {
      print('🏥 Puntos insuficientes para mejorar hospitales');
      return;
    }

    print(
      '🏥 Mejorando $cantidad hospitales con $puntosPorHospital puntos cada uno',
    );

    for (var h in hospitalesEnCampo) {
      final fila = h['fila'] as int;
      final columna = h['columna'] as int;
      final hospital = h['hospital'] as HospitalCampo;
      print(
        '   🏥 Mejorando hospital en ($fila,$columna) (curación actual: ${hospital.poderCuracionActual})',
      );
      onMejorar('hospital', fila, columna, puntosPorHospital);
    }
  }

  void _invocarAleatoriamente() {
    // 1. Buscar todas las casillas vacías
    final List<Map<String, int>> casillasVacias = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (yo.tablero.estaVacia(fila, col)) {
          casillasVacias.add({'fila': fila, 'columna': col});
        }
      }
    }

    if (casillasVacias.isEmpty) {
      print('⚠️ No hay casillas vacías para invocar');
      return;
    }

    // 2. Elegir una casilla aleatoria
    final random = Random();
    final casilla = casillasVacias[random.nextInt(casillasVacias.length)];
    final fila = casilla['fila']!;
    final columna = casilla['columna']!;
    final coordenada = yo.tablero.obtenerCoordenadas(fila, columna);

    // 3. Decidir qué invocar según probabilidades
    final int probabilidad = random.nextInt(100);

    if (probabilidad < 80) {
      // 80% -> Guerrero
      if (_puedeInvocarGuerrero()) {
        _invocarGuerreroAleatorio(fila, columna, coordenada);
      } else {
        print('⚠️ No se puede invocar guerrero, intentando otra cosa');
        _invocarFallback(fila, columna, coordenada);
      }
    } else if (probabilidad < 90) {
      // 10% -> Aldeano
      if (_puedeInvocarAldeano()) {
        _invocarAldeano(fila, columna, coordenada);
      } else {
        _invocarFallback(fila, columna, coordenada);
      }
    } else if (probabilidad < 95) {
      // 5% -> Hospital
      if (_puedeInvocarHospital()) {
        _invocarHospital(fila, columna, coordenada);
      } else {
        _invocarFallback(fila, columna, coordenada);
      }
    } else {
      // 5% -> Torre
      if (_puedeInvocarTorre()) {
        _invocarTorre(fila, columna, coordenada);
      } else {
        _invocarFallback(fila, columna, coordenada);
      }
    }
  }

  // ============================================
  // INVOCAR GUERRERO ALEATORIO (el que pueda pagar)
  // ============================================
  void _invocarGuerreroAleatorio(int fila, int columna, String coordenada) {
    final posibles =
        yo.guerrerosSeleccionados
            .where((g) => g.costoInvocacion <= yo.puntosAcumulados)
            .toList();

    if (posibles.isEmpty) {
      print('⚠️ No hay guerreros disponibles para invocar');
      return;
    }

    final random = Random();
    final guerrero = posibles[random.nextInt(posibles.length)];
    print('🤖 IA China invoca guerrero ${guerrero.nombreId} en $coordenada');
    onInvocar(fila, columna, 'guerrero', guerrero.id);
  }

  // ============================================
  // FALLBACK: si no puede invocar lo que quería, intenta lo que pueda
  // ============================================
  void _invocarFallback(int fila, int columna, String coordenada) {
    // Prioridad: guerrero -> aldeano -> cultivo -> hospital -> torre
    if (_puedeInvocarGuerrero()) {
      _invocarGuerreroAleatorio(fila, columna, coordenada);
    } else if (_puedeInvocarAldeano()) {
      _invocarAldeano(fila, columna, coordenada);
    } else if (_puedeInvocarCultivo()) {
      _invocarCultivo(fila, columna, coordenada);
    } else if (_puedeInvocarHospital()) {
      _invocarHospital(fila, columna, coordenada);
    } else if (_puedeInvocarTorre()) {
      _invocarTorre(fila, columna, coordenada);
    } else {
      print('⚠️ No hay nada que invocar en fallback');
    }
  }

  void _invocarTorresAdicionales() {
    // Posiciones adicionales para torres (centro del tablero)
    final posicionesAdicionales = [
      {'fila': 1, 'columna': 2, 'coordenada': 'C1'}, // C1
      {'fila': 2, 'columna': 2, 'coordenada': 'C2'}, // C2
    ];

    for (var pos in posicionesAdicionales) {
      final fila = pos['fila']! as int;
      final columna = pos['columna']! as int;
      final coordenada = pos['coordenada']! as String;

      if (_faltaTorreEn(fila, columna) && _puedeInvocarTorre()) {
        _invocarTorre(fila, columna, coordenada);
      }
    }
  }

  void _mejorarTodasLasTorres() {
    // 1. Buscar todas las torres en el tablero
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

    if (torresEnCampo.isEmpty) {
      print('🗼 No hay torres para mejorar');
      return;
    }

    final int cantidadTorres = torresEnCampo.length;
    final int puntosPorTorre = (yo.puntosAcumulados ~/ cantidadTorres).floor();

    if (puntosPorTorre == 0) {
      print(
        '🗼 Puntos insuficientes para mejorar torres ($puntosPorTorre por torre)',
      );
      return;
    }

    print(
      '🗼 Mejorando $cantidadTorres torres con $puntosPorTorre puntos cada una',
    );

    // Mejorar cada torre
    for (var torreData in torresEnCampo) {
      final fila = torreData['fila'] as int;
      final columna = torreData['columna'] as int;
      final torre = torreData['torre'] as TorreCampo;

      print(
        '   🗼 Mejorando torre en ($fila,$columna) (ataque actual: ${torre.ataqueActual})',
      );
      onMejorar('torre', fila, columna, puntosPorTorre);
    }
  }

  bool _faltaTorreEn(int fila, int columna) {
    final casilla = yo.tablero.obtenerCasillaPorIndices(fila, columna);
    return casilla.tipo != TipoCasilla.torre;
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
    final aldeanoA3 = yo.tablero.obtenerCasillaPorIndices(3, 0);
    return (aldeanoA3.tipo == TipoCasilla.aldeano);
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
  // VERIFICACIONES DE POSICIONES
  // ============================================
  bool _faltaAldeanoA3() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(2, 0);
    return casilla.tipo != TipoCasilla.aldeano;
  }

  bool _faltaCultivoA0() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(0, 0);
    return casilla.tipo != TipoCasilla.cultivo;
  }

  bool _faltaHospitalB3() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(2, 1);
    return casilla.tipo != TipoCasilla.hospital;
  }

  bool _faltaCultivoB0() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(0, 1);
    return casilla.tipo != TipoCasilla.cultivo;
  }

  bool _cultivoA0Existe() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(0, 0);
    return casilla.tipo == TipoCasilla.cultivo;
  }

  // ============================================
  // MEJORA DEL CULTIVO EN A0
  // ============================================
  void _mejorarCultivoA0() {
    final casilla = yo.tablero.obtenerCasillaPorIndices(0, 0);
    if (casilla.tipo == TipoCasilla.cultivo) {
      final cultivo = (casilla as CasillaCultivo).cultivo;
      final puntos = yo.puntosAcumulados;
      print('🤖 IA China mejora cultivo en A0 con $puntos puntos');
      onMejorar('cultivo', 0, 0, puntos);
    } else {
      print('⚠️ No hay cultivo en A0 para mejorar');
      //_pasarTurno();
    }
  }

  // ============================================
  // INVOCACIONES (reutilizando las de la IA base)
  // ============================================
  void _invocarAldeano(int fila, int columna, String coordenada) {
    if (aldeanos == null) return;
    final aldeano = aldeanos!.values.firstWhere(
      (a) => a.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA China invoca ${aldeano.nombre} en $coordenada');
    onInvocar(fila, columna, 'aldeano', aldeano.id);
  }

  void _invocarCultivo(int fila, int columna, String coordenada) {
    if (cultivos == null) return;
    final cultivo = cultivos!.values.firstWhere(
      (c) => c.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA China invoca ${cultivo.nombre} en $coordenada');
    onInvocar(fila, columna, 'cultivo', cultivo.id);
  }

  void _invocarHospital(int fila, int columna, String coordenada) {
    if (hospitales == null) return;
    final hospital = hospitales!.values.firstWhere(
      (h) => h.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA China invoca ${hospital.nombre} en $coordenada');
    onInvocar(fila, columna, 'hospital', hospital.id);
  }

  void _invocarTorre(int fila, int columna, String coordenada) {
    if (torres == null) return;
    final torre = torres!.values.firstWhere(
      (t) => t.civilizacionId == yo.civilizacion.id,
    );
    print('🤖 IA China invoca torre ${torre.nombre} en $coordenada');
    onInvocar(fila, columna, 'torre', torre.id);
  }

  void _pasarTurno() {
    print('🤖 IA China pasa turno');
    onPasarTurno();
  }
}
