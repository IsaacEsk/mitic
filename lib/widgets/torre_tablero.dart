import 'package:flutter/material.dart';
import 'package:mitic/models/torre_campo.dart';

class TorreTablero extends StatelessWidget {
  final double ladoCelda;
  final TorreCampo torre;
  final VoidCallback onTap;

  const TorreTablero({
    super.key,
    required this.ladoCelda,
    required this.torre,
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
              torre.resplandor
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
              // Imagen animada (carga lento, dispara rápido)
              Positioned(
                top: margenSuperior,
                left: (ladoCelda - imagenSize) / 2,
                child: AnimatedContainer(
                  duration:
                      torre.animar
                          ? const Duration(milliseconds: 400) // Carga lento
                          : const Duration(milliseconds: 100), // Dispara rápido
                  width: torre.animar ? imagenSize * 0.7 : imagenSize,
                  height: torre.animar ? imagenSize * 0.7 : imagenSize,
                  curve: Curves.easeOutBack,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[600],
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(torre.torreBase.imagen),
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
                          Text('🏹', style: TextStyle(fontSize: statIconSize)),
                          const SizedBox(width: 2),
                          Text(
                            '${torre.ataqueActual}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _calcularFontSize(
                                torre.ataqueActual,
                                statHeight,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('🏰', style: TextStyle(fontSize: statIconSize)),
                          const SizedBox(width: 2),
                          Text(
                            '${torre.vidaActual}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _calcularFontSize(
                                torre.vidaActual,
                                statHeight,
                              ),
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

  // Función más flexible con configuración
  double _calcularFontSize(
    int valor,
    double statHeight, {
    double baseMultiplier = 0.5,
  }) {
    final String texto = valor.toString();
    final int longitud = texto.length;

    // Mapa de configuración: [longitud] = multiplicador
    final Map<int, double> config = {
      3: baseMultiplier, // <= 3 dígitos: normal
      4: baseMultiplier * 0.8, // 4 dígitos: 80% del tamaño
      5: baseMultiplier * 0.6, // 5 dígitos: 60% del tamaño
      6: baseMultiplier * 0.4, // 6 dígitos: 40% del tamaño
    };

    // Si es más de 6 dígitos, usar el mínimo
    final double multiplier =
        config[longitud.clamp(3, 6)] ?? baseMultiplier * 0.3;

    return statHeight * multiplier;
  }
}
