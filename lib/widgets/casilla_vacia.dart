import 'package:flutter/material.dart';

class CasillaVaciaw extends StatelessWidget {
  final double ladoCelda;
  final String coordenada; // Nuestro secreto
  final VoidCallback onPressed;

  const CasillaVaciaw({
    super.key,
    required this.ladoCelda,
    required this.coordenada,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final double tamanoBoton = ladoCelda * 0.9; // 90% como te gustó
    final double radioBorde = ladoCelda * 0.05; // Radio proporcional

    return Container(
      width: ladoCelda,
      height: ladoCelda,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.transparent), // Sin borde
      ),
      child: Center(
        child: SizedBox(
          width: tamanoBoton,
          height: tamanoBoton,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[600],
              elevation: 4,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radioBorde),
              ),
            ),
            child: Icon(Icons.add, size: tamanoBoton * 0.4),
          ),
        ),
      ),
    );
  }
}
