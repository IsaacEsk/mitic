import 'casilla.dart';

class Tablero {
  static const int filas = 4;
  static const int columnas = 5;

  late List<List<Casilla>> casillas;
  final bool esEnemigo;

  Tablero({required this.esEnemigo}) {
    _inicializarTablero();
  }

  // ============================================
  // INICIALIZAR CON CASILLAS VACÍAS
  // ============================================
  void _inicializarTablero() {
    casillas = List.generate(filas, (fila) {
      return List.generate(columnas, (columna) {
        final coordenada = '${String.fromCharCode(65 + columna)}${3 - fila}';
        return CasillaVacia(coordenada: coordenada);
      });
    });
  }

  // ============================================
  // OBTENER CASILLA POR COORDENADAS
  // ============================================
  Casilla? obtenerCasilla(String coordenada) {
    for (var fila = 0; fila < filas; fila++) {
      for (var col = 0; col < columnas; col++) {
        if (casillas[fila][col].coordenada == coordenada) {
          return casillas[fila][col];
        }
      }
    }
    return null;
  }

  // ============================================
  // OBTENER CASILLA POR ÍNDICES
  // ============================================
  Casilla obtenerCasillaPorIndices(int fila, int columna) {
    return casillas[fila][columna];
  }

  // ============================================
  // COLOCAR UNA CASILLA EN UNA POSICIÓN
  // ============================================
  void colocarCasilla(int fila, int columna, Casilla casilla) {
    if (fila >= 0 && fila < filas && columna >= 0 && columna < columnas) {
      casillas[fila][columna] = casilla;
    }
  }

  // ============================================
  // COLOCAR MONUMENTO EN SU POSICIÓN (C0)
  // ============================================
  // ============================================
  // COLOCAR MONUMENTO EN SU POSICIÓN
  // ============================================
  void colocarMonumento(CasillaMonumento monumento) {
    if (esEnemigo) {
      // Enemigo: monumento en fila 0 (su primera línea)
      casillas[0][2] = monumento;
    } else {
      // Propio: monumento en fila 3 (nuestra última línea)
      casillas[3][2] = monumento;
    }
  }

  // ============================================
  // VERIFICAR SI UNA CASILLA ESTÁ VACÍA
  // ============================================
  bool estaVacia(int fila, int columna) {
    return casillas[fila][columna].tipo == TipoCasilla.vacia;
  }

  // ============================================
  // ELIMINAR CASILLA (DEJARLA VACÍA)
  // ============================================
  void eliminarCasilla(int fila, int columna) {
    final coordenada = '${String.fromCharCode(65 + columna)}${3 - fila}';
    casillas[fila][columna] = CasillaVacia(coordenada: coordenada);
  }

  // ============================================
  // OBTENER TODAS LAS CASILLAS DE UN TIPO
  // ============================================
  List<Casilla> obtenerCasillasPorTipo(TipoCasilla tipo) {
    List<Casilla> resultado = [];
    for (var fila = 0; fila < filas; fila++) {
      for (var col = 0; col < columnas; col++) {
        if (casillas[fila][col].tipo == tipo) {
          resultado.add(casillas[fila][col]);
        }
      }
    }
    return resultado;
  }

  // ============================================
  // OBTENER COORDENADAS DE UNA CASILLA
  // ============================================
  String obtenerCoordenadas(int fila, int columna) {
    return '${String.fromCharCode(65 + columna)}${3 - fila}';
  }

  // ============================================
  // CONVERTIR COORDENADA A ÍNDICES
  // ============================================
  static List<int>? coordenadaToIndices(String coordenada) {
    if (coordenada.length != 2) return null;

    final columna = coordenada[0].toUpperCase().codeUnitAt(0) - 65;
    final fila = 3 - int.parse(coordenada[1]);

    if (columna < 0 || columna >= columnas || fila < 0 || fila >= filas) {
      return null;
    }

    return [fila, columna];
  }

  // ============================================
  // PARA DEBUG: IMPRIMIR EL TABLERO
  // ============================================
  void imprimirTablero() {
    print('╔══════════════════════════════════╗');
    for (var fila = 0; fila < filas; fila++) {
      String linea = '║ ';
      for (var col = 0; col < columnas; col++) {
        String icono = _getIconoCorto(casillas[fila][col].tipo);
        linea += '$icono  ';
      }
      print(linea + '║');
    }
    print('╚══════════════════════════════════╝');
  }

  String _getIconoCorto(TipoCasilla tipo) {
    switch (tipo) {
      case TipoCasilla.vacia:
        return '⬜';
      case TipoCasilla.monumento:
        return '🏛️';
      case TipoCasilla.guerrero:
        return '⚔️';
      case TipoCasilla.torre:
        return '🗼';
      case TipoCasilla.hospital:
        return '🏥';
      case TipoCasilla.cultivo:
        return '🌾';
      case TipoCasilla.aldeano:
        return '👨';
    }
  }
}
