import 'package:flutter/material.dart';
import 'package:mitic/models/cultivo_campo.dart';

class CultivoTablero extends StatelessWidget {
  final double ladoCelda;
  final CultivoCampo cultivo;
  final VoidCallback onTap;

  const CultivoTablero({
    super.key,
    required this.ladoCelda,
    required this.cultivo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double imagenSize = ladoCelda * 0.9;
    final double margenSuperior = (ladoCelda - imagenSize) / 2;
    final double statHeight = ladoCelda * 0.25;
    final double statIconSize = statHeight * 0.7;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          boxShadow:
              cultivo.resplandor
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
              // Imagen animada (crece y vuelve)
              Positioned(
                top: margenSuperior,
                left: (ladoCelda - imagenSize) / 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: cultivo.animar ? imagenSize * 1.1 : imagenSize,
                  height: cultivo.animar ? imagenSize * 1.1 : imagenSize,
                  curve: Curves.easeOutBack,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[600],
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(cultivo.cultivoBase.imagen),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              // Stats (siempre iguales)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: statHeight,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Text('🌾', style: TextStyle(fontSize: statIconSize)),
                          const SizedBox(width: 2),
                          Text(
                            '${cultivo.puntosPorTurnoActual}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: statHeight * 0.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('🌱', style: TextStyle(fontSize: statIconSize)),
                          const SizedBox(width: 2),
                          Text(
                            '${cultivo.vidaActual}',
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
      ),
    );
  }
}
