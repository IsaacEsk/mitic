import 'package:flutter/material.dart';

class MonumentoTablero extends StatelessWidget {
  final double ladoCelda;
  final String imagenPath;
  final int vida;
  final VoidCallback onTap;

  const MonumentoTablero({
    super.key,
    required this.ladoCelda,
    required this.imagenPath,
    required this.vida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaños calculados según tu especificación
    final double imagenSize = ladoCelda * 0.9; // 70% de la celda
    final double margenSuperior = ladoCelda * 0.05; // 10% arriba
    final double espacioRestante =
        ladoCelda * 0.2 * 0.7; // 20% abajo para la vida

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ladoCelda,
        height: ladoCelda,
        // decoration: BoxDecoration(
        //   border: Border.all(color: Colors.amber, width: 2),
        //   borderRadius: BorderRadius.circular(8),
        // ),
        child: Stack(
          children: [
            // Imagen centrada con margen superior
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
                    image: AssetImage(imagenPath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Vida en la parte inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  //padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  // decoration: BoxDecoration(
                  //   color: Colors.red[900]?.withOpacity(0.8),
                  //   borderRadius: BorderRadius.circular(12),
                  // ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: espacioRestante,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$vida',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: espacioRestante,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
