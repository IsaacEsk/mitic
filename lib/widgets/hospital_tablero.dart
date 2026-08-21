import 'package:flutter/material.dart';
import 'package:mitic/models/hospital_campo.dart';

class HospitalTablero extends StatelessWidget {
  final double ladoCelda;
  final HospitalCampo hospital;
  final VoidCallback onTap;

  const HospitalTablero({
    super.key,
    required this.ladoCelda,
    required this.hospital,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double imagenSize = ladoCelda * 0.9;
    final double margenSuperior = (ladoCelda - imagenSize) / 2;
    final double statHeight = ladoCelda * 0.25;
    final double statIconSize = statHeight * 0.7;

    // 👇 Determinar el color del resplandor según el estado
    Color resplandorColor;
    if (hospital.resplandor) {
      resplandorColor = Colors.red; // Cuando recibe daño
    } else if (hospital.animar) {
      resplandorColor = Colors.green; // Cuando cura
    } else {
      resplandorColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          boxShadow:
              resplandorColor != Colors.transparent
                  ? [
                    BoxShadow(
                      color: resplandorColor.withValues(alpha: 0.8),
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
                child: Container(
                  width: imagenSize,
                  height: imagenSize,
                  decoration: BoxDecoration(
                    color: Colors.brown[600],
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(hospital.hospitalBase.imagen),
                      fit: BoxFit.cover,
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
                          Text('💊', style: TextStyle(fontSize: statIconSize)),
                          const SizedBox(width: 2),
                          Text(
                            '${hospital.poderCuracionActual}',
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
                          Text('🏥', style: TextStyle(fontSize: statIconSize)),
                          const SizedBox(width: 2),
                          Text(
                            '${hospital.vidaActual}',
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
