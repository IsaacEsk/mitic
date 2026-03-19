import 'package:flutter/material.dart';

class CasillaVaciaEnemiga extends StatelessWidget {
  final double ladoCelda;
  final String coordenada;

  const CasillaVaciaEnemiga({
    super.key,
    required this.ladoCelda,
    required this.coordenada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ladoCelda,
      height: ladoCelda,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 1),
        color: Colors.grey[850], // Un poco más claro para diferenciar
      ),
      child: Center(
        child: Text(
          coordenada,
          style: TextStyle(color: Colors.white24, fontSize: ladoCelda * 0.15),
        ),
      ),
    );
  }
}
