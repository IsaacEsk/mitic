import 'package:flutter/material.dart';
import '../enums/modoaccion.dart';

// Card del monumento
Widget buildMonumentoCardYU({
  required String nombre,
  required int vida,
  required String imagenPath,
  // NUEVOS PARÁMETROS
  bool esObjetivo = false, // Si puede ser atacado (naranja)
  VoidCallback? onTap, // Qué pasa cuando lo tocan
}) {
  // Determinar color del borde
  Color borderColor = Colors.amber[800]!;
  double borderWidth = 3;

  if (esObjetivo) {
    borderColor = Colors.orange;
    borderWidth = 4;
  }

  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (esObjetivo)
            BoxShadow(
              color: Colors.orange.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Colors.amber[100]!.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera especial para monumento (dorada)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber[800],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber[700]!, Colors.amber[900]!],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'MONUMENTO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Marco de la imagen
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.brown[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[700]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child:
                    imagenPath.isNotEmpty
                        ? Image.asset(
                          imagenPath,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stack) => Container(
                                color: Colors.brown[300],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.brown[700],
                                    size: 40,
                                  ),
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.brown[300],
                          child: Center(
                            child: Icon(
                              Icons.account_balance,
                              size: 50,
                              color: Colors.brown[700],
                            ),
                          ),
                        ),
              ),
            ),
          ),

          // Nombre del monumento
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),

          // Stats (vida)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[400]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  vida.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Card del monumento enemigo
Widget buildMonumentoCardYUopponent({
  required String nombre,
  required int vida,
  required String imagenPath,
  // NUEVOS PARÁMETROS
  bool esObjetivo = false,
  VoidCallback? onTap,
}) {
  // Determinar color del borde
  Color borderColor = Colors.amber[800]!;
  double borderWidth = 3;

  if (esObjetivo) {
    borderColor = Colors.orange;
    borderWidth = 4;
  }

  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (esObjetivo)
            BoxShadow(
              color: Colors.orange.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Colors.amber[100]!.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats (vida) - ARRIBA
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[400]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  vida.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Marco de la imagen
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.brown[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[700]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child:
                    imagenPath.isNotEmpty
                        ? Image.asset(
                          imagenPath,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stack) => Container(
                                color: Colors.brown[300],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.brown[700],
                                    size: 40,
                                  ),
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.brown[300],
                          child: Center(
                            child: Icon(
                              Icons.account_balance,
                              size: 50,
                              color: Colors.brown[700],
                            ),
                          ),
                        ),
              ),
            ),
          ),

          // Nombre del monumento
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),

          // Cabecera especial para monumento (dorada) - ABAJO
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber[800],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(13),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber[700]!, Colors.amber[900]!],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'MONUMENTO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Card de guerrero
Widget buildGuerreroCardYU({
  required String nombre,
  required int vida,
  required int ataque,
  required int costo,
  required String imagenPath,
  bool disponible = false,
  required ModoAccion modoActual,
  required VoidCallback? onTap,
  bool isSelected = false,
  // NUEVOS PARÁMETROS PARA ATAQUE
  bool puedeAtacar = false, // Si este guerrero puede atacar (rojo)
  bool esObjetivo = false, // Si este guerrero es un objetivo posible (naranja)
  bool yaAtaco = false, // Si ya atacó este turno (gris)
}) {
  // ============================================
  // DETERMINAR COLOR Y GROSOR DEL BORDE
  // ============================================
  Color borderColor = disponible ? Colors.grey[400]! : Colors.brown[700]!;
  double borderWidth = 3;

  if (!disponible) {
    if (modoActual == ModoAccion.curar) {
      borderColor = Colors.green;
      borderWidth = isSelected ? 5 : 4;
    } else if (modoActual == ModoAccion.mejorar) {
      borderColor = Colors.orange;
      borderWidth = isSelected ? 5 : 4;
    } else if (modoActual == ModoAccion.atacar) {
      if (puedeAtacar) {
        borderColor = Colors.red;
        borderWidth = isSelected ? 5 : 4;
      } else if (yaAtaco) {
        borderColor = Colors.grey;
        borderWidth = 3;
      }
    } else if (modoActual == ModoAccion.atacarSeleccionando) {
      if (esObjetivo) {
        borderColor = Colors.orange;
        borderWidth = 4;
      }
    }
  }

  // ============================================
  // DETERMINAR SI ES SELECCIONABLE
  // ============================================
  final bool isSelectable =
      (modoActual == ModoAccion.curar && !disponible) ||
      (modoActual == ModoAccion.mejorar && !disponible) ||
      (modoActual == ModoAccion.atacar && puedeAtacar) ||
      (modoActual == ModoAccion.atacarSeleccionando && esObjetivo);

  return GestureDetector(
    onTap: isSelectable ? onTap : null,
    child: Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (isSelectable && isSelected)
            BoxShadow(
              color: borderColor.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Colors.brown[100]!.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child:
          disponible
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Vacío',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera con nombre
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: yaAtaco ? Colors.grey[600] : Colors.brown[800],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13),
                      ),
                      gradient:
                          yaAtaco
                              ? null
                              : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.brown[700]!,
                                  Colors.brown[900]!,
                                ],
                              ),
                    ),
                    child: Text(
                      nombre,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: yaAtaco ? Colors.grey[300] : Colors.white,
                        shadows:
                            yaAtaco
                                ? null
                                : const [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Marco de la imagen
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.brown[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.brown[600]!, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child:
                            imagenPath.isNotEmpty
                                ? Image.asset(
                                  imagenPath,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stack) => Container(
                                        color: Colors.brown[300],
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.brown[700],
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                )
                                : Container(
                                  color: Colors.brown[300],
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.brown[700],
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ),

                  // Stats (vida y ataque)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatChip(
                          '❤️',
                          vida.toString(),
                          yaAtaco ? Colors.grey : Colors.red,
                        ),
                        _buildStatChip(
                          '🗡️',
                          ataque.toString(),
                          yaAtaco ? Colors.grey : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    ),
  );
}

// Card de guerrero oponente
Widget buildGuerreroCardYUopponet({
  required String nombre,
  required int vida,
  required int ataque,
  required int costo,
  required String imagenPath,
  bool disponible = false,
  bool esObjetivo = false,
  VoidCallback? onTap, // <--- AGREGADO
}) {
  // Determinar color del borde
  Color borderColor = disponible ? Colors.grey[400]! : Colors.brown[700]!;
  double borderWidth = 3;

  if (!disponible && esObjetivo) {
    borderColor = Colors.orange;
    borderWidth = 4;
  }

  return GestureDetector(
    onTap: onTap, // <--- AHORA SÍ LO USA
    child: Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (esObjetivo)
            BoxShadow(
              color: Colors.orange.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Colors.brown[100]!.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child:
          disponible
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Vacío',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats (vida y ataque)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatChip('❤️', vida.toString(), Colors.red),
                        _buildStatChip('🗡️', ataque.toString(), Colors.orange),
                      ],
                    ),
                  ),

                  // Marco de la imagen
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.brown[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.brown[600]!, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child:
                            imagenPath.isNotEmpty
                                ? Image.asset(
                                  imagenPath,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stack) => Container(
                                        color: Colors.brown[300],
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.brown[700],
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                )
                                : Container(
                                  color: Colors.brown[300],
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.brown[700],
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ),

                  // Cabecera con nombre (abajo)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.brown[800],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(13),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.brown[700]!, Colors.brown[900]!],
                      ),
                    ),
                    child: Text(
                      nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
    ),
  );
}

// Stat chip mejorado
Widget _buildStatChip(String icon, String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.5), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 14, color: color)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ============================================
// CONTADOR DE PUNTOS (para poner abajo de los guerreros)
// ============================================
Widget buildPuntosCounter(int puntos, {bool esEnemigo = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors:
            esEnemigo
                ? [Colors.red[700]!, Colors.red[900]!] // Rojo para enemigos
                : [Colors.amber[700]!, Colors.amber[900]!], // Dorado para ti
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flash_on, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          '$puntos',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
