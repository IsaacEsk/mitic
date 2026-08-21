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
              guerrero.resplandor
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
              // Imagen
              Positioned(
                top: margenSuperior,
                left: (ladoCelda - imagenSize) / 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: guerrero.animar ? imagenSize * 0.7 : imagenSize,
                  height: guerrero.animar ? imagenSize * 0.7 : imagenSize,
                  curve: Curves.easeOutBack,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[600],
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(guerrero.guerreroBase.imagen),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              // Stats
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
                          const Text('⚔️', style: TextStyle(fontSize: 12)),
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
                      Row(
                        children: [
                          const Text('❤️', style: TextStyle(fontSize: 12)),
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

              if (!guerrero.yaAtacoEsteTurno)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    // decoration: BoxDecoration(
                    //   color: Colors.amber.withOpacity(0.9),
                    //   borderRadius: BorderRadius.circular(20),
                    // ),
                    child: const Text('⚔️', style: TextStyle(fontSize: 10)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
