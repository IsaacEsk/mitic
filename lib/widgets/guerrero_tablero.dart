import 'package:flutter/material.dart';
import 'package:mitic/models/guerrero_field_model_2.0.dart';

class GuerreroTablero extends StatelessWidget {
  final double ladoCelda;
  final GuerreroCampo guerrero;
  final VoidCallback onTap;

  const GuerreroTablero({
    super.key,
    required this.ladoCelda,
    required this.guerrero,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaños calculados
    final double imagenSize = ladoCelda * 0.9; // 90% de la celda
    final double margenSuperior =
        (ladoCelda - imagenSize) / 2; // Centrado vertical
    final double statHeight = ladoCelda * 0.25; // 15% para stats
    final double statIconSize = statHeight * 0.7;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ladoCelda,
        height: ladoCelda,
        child: Stack(
          children: [
            // ============================================
            // IMAGEN (centrada, ocupa casi toda la celda)
            // ============================================
            Positioned(
              top: margenSuperior,
              left: (ladoCelda - imagenSize) / 2,
              child: Container(
                width: imagenSize,
                height: imagenSize,
                decoration: BoxDecoration(
                  color: Colors.brown[300],
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(guerrero.guerreroBase.imagen),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // ============================================
            // STATS (abajo, sobre fondo semitransparente)
            // ============================================
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: statHeight,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                    0.6,
                  ), // Fondo oscuro semitransparente
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ATAQUE
                    Row(
                      children: [
                        Text('⚔️', style: TextStyle(fontSize: statIconSize)),
                        const SizedBox(width: 2),
                        Text(
                          '${guerrero.ataqueActual}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: statHeight * 0.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // VIDA
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: statIconSize,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${guerrero.vidaActual}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: statHeight * 0.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
