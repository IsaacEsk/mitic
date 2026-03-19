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
      child: Container(
        width: ladoCelda,
        height: ladoCelda,
        child: Stack(
          children: [
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
                    image: AssetImage(cultivo.cultivoBase.imagen),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: statHeight,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // PUNTOS POR TURNO
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
                    // VIDA
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
    );
  }
}
