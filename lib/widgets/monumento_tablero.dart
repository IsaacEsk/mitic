import 'package:flutter/material.dart';

class MonumentoTablero extends StatelessWidget {
  final double ladoCelda;
  final String imagenPath;
  final int vida;
  final VoidCallback onTap;
  final bool resplandor; // 👈 NUEVO

  const MonumentoTablero({
    super.key,
    required this.ladoCelda,
    required this.imagenPath,
    required this.vida,
    required this.onTap,
    this.resplandor = false, // 👈 NUEVO, por defecto falso
  });

  @override
  Widget build(BuildContext context) {
    final double imagenSize = ladoCelda * 0.9;
    final double margenSuperior = ladoCelda * 0.05;
    final double espacioRestante = ladoCelda * 0.2 * 0.7;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          boxShadow:
              resplandor
                  ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ]
                  : null,
        ),
        child: SizedBox(
          width: ladoCelda,
          height: ladoCelda,
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
      ),
    );
  }
}
