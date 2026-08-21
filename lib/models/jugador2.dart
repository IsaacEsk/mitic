import 'package:mitic/models/casilla.dart';
import 'package:mitic/models/civilizacion_model.dart';
import 'package:mitic/models/guerrero_model.dart';
import 'package:mitic/models/monument_model.dart';
import 'tablero.dart';

class Jugador2 {
  final Civilizacion civilizacion; // Civilización seleccionada
  final List<Guerrero> guerrerosSeleccionados; // 4 guerreros
  final MonumentField monumentoEnCampo; // Monumento con estado
  int puntosAcumulados; // Puntos de los dados
  int turno; // ¿Es su turno?
  final Tablero tablero; // Tablero de 4x5

  Jugador2({
    required this.civilizacion,
    required this.guerrerosSeleccionados,
    required this.monumentoEnCampo,
    required this.puntosAcumulados,
    required this.turno,
    required this.tablero,
  });

  // ============================================
  // INICIALIZAR JUGADOR CON TABLERO VACÍO
  // ============================================
  factory Jugador2.inicial({
    required Civilizacion civilizacion,
    required List<Guerrero> guerrerosSeleccionados,
    required MonumentField monumentoEnCampo,
    int puntosAcumulados = 0,
    int turno = 0,
    required bool esEnemigo, // 👈 NUEVO PARÁMETRO
  }) {
    // Crear tablero vacío con la bandera
    final tablero = Tablero(esEnemigo: esEnemigo);

    // Colocar el monumento en su posición (ahora la decide el tablero)
    final monumento = CasillaMonumento(
      coordenada: esEnemigo ? 'C0' : 'C3', // Solo para referencia
      civilizacionId: civilizacion.id,
      nombre: monumentoEnCampo.nombre,
      vidaActual: monumentoEnCampo.vidaActual,
      imagenPath: monumentoEnCampo.imagenPath,
    );
    tablero.colocarMonumento(monumento);

    return Jugador2(
      civilizacion: civilizacion,
      guerrerosSeleccionados: guerrerosSeleccionados,
      monumentoEnCampo: monumentoEnCampo,
      puntosAcumulados: puntosAcumulados,
      turno: turno,
      tablero: tablero,
    );
  }

  // ============================================
  // COLOCAR UN ELEMENTO EN EL TABLERO
  // ============================================
  void colocarEnTablero(int fila, int columna, Casilla casilla) {
    tablero.colocarCasilla(fila, columna, casilla);
  }

  // ============================================
  // OBTENER CASILLA POR COORDENADAS
  // ============================================
  Casilla? obtenerCasilla(String coordenada) {
    return tablero.obtenerCasilla(coordenada);
  }

  // ============================================
  // ELIMINAR CASILLA (DEJAR VACÍA)
  // ============================================
  void eliminarCasilla(int fila, int columna) {
    tablero.eliminarCasilla(fila, columna);
  }

  // ============================================
  // VERIFICAR SI UNA CASILLA ESTÁ VACÍA
  // ============================================
  bool estaVacia(int fila, int columna) {
    return tablero.estaVacia(fila, columna);
  }

  // ============================================
  // PARA DEBUG
  // ============================================
  void imprimirTablero() {
    tablero.imprimirTablero();
  }
}
