import 'package:flutter/material.dart';
import 'package:mitic/screens/SelectAliadosScreen.dart';
import '../services/mitic2_data_service.dart';
import '../models/civilizacion_model.dart';
import '../models/guerrero_model.dart';

class SelectCivScreen extends StatefulWidget {
  const SelectCivScreen({super.key});

  @override
  State<SelectCivScreen> createState() => _SelectCivScreenState();
}

class _SelectCivScreenState extends State<SelectCivScreen> {
  List<Civilizacion> _civilizaciones = [];
  Map<String, Guerrero> _guerreros = {};
  Map<String, String> _translations = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final data = await Mitic2DataService.cargarTodo();
    final civs = data['civilizaciones'] as Map<String, Civilizacion>;
    final guerreros = data['guerreros'] as Map<String, Guerrero>;
    final translations = data['translations'] as Map<String, String>;

    setState(() {
      _civilizaciones = civs.values.toList();
      _guerreros = guerreros;
      _translations = translations;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double ancho = constraints.maxWidth;
            final double alto = constraints.maxHeight;

            if (_cargando) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              );
            }

            // Determinar número de columnas según el ancho
            int crossAxisCount = ancho > 900 ? 2 : (ancho > 600 ? 2 : 1);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Título
                  Container(
                    padding: const EdgeInsets.all(16),
                    // decoration: BoxDecoration(
                    //   color: Colors.gre[800],
                    //   borderRadius: BorderRadius.circular(30),
                    //   //border: Border.all(color: Colors.amber, width: 2),
                    // ),
                    child: const Text(
                      'SELECCIONA TU CIVILIZACIÓN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid de civilizaciones
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.8, // Rectangular horizontal
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _civilizaciones.length,
                      itemBuilder: (context, index) {
                        final civ = _civilizaciones[index];
                        final guerreroPrincipal = _guerreros['${civ.id}_001'];
                        return _buildCivCard(civ, guerreroPrincipal);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCivCard(Civilizacion civ, Guerrero? guerrero) {
    final civNombre = _translations[civ.id] ?? civ.nombre;

    return GestureDetector(
      onTap: () {
        print('🎮 Civilización seleccionada: ${civ.nombre}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SelectAliadosScreen(civilizacionSeleccionada: civ),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 👇 TAMAÑO DISPONIBLE PARA LA CARD
          final double cardHeight = constraints.maxHeight;
          final double cardWidth = constraints.maxWidth;

          // 👇 PROPORCIONES
          final double izquierdoWidth = cardWidth * 0.35; // 35% para monumento
          final double derechaWidth = cardWidth * 0.65; // 65% para info
          final double imagenSize =
              izquierdoWidth * 0.7; // 70% del ancho izquierdo
          final double fontSizeNombre = cardHeight * 0.06;
          final double fontSizeDesc = cardHeight * 0.04;
          final double fontSizeStats = cardHeight * 0.045;
          final double iconSize = cardHeight * 0.05;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[800]!, Colors.grey[900]!],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LADO IZQUIERDO: MONUMENTO (35%)
                Container(
                  width: izquierdoWidth,
                  padding: EdgeInsets.all(cardHeight * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Imagen del monumento (tamaño proporcional)
                      Container(
                        height: imagenSize,
                        width: imagenSize,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(civ.muralla.imagen),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: cardHeight * 0.02),
                      // Nombre del monumento (fuente responsiva)
                      Text(
                        civ.muralla.nombre,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: fontSizeNombre,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: cardHeight * 0.01),
                      // Vida del monumento
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: iconSize,
                          ),
                          SizedBox(width: cardHeight * 0.01),
                          Text(
                            '${civ.muralla.vida}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSizeStats,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // LADO DERECHO: INFO CIV + GUERRERO (65%)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(cardHeight * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nombre de la civilización
                        Text(
                          civNombre,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSizeNombre * 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: cardHeight * 0.02),
                        // Descripción
                        Text(
                          _translations[civ.muralla.descripcionId] ?? '',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: fontSizeDesc,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (guerrero != null) ...[
                          SizedBox(height: cardHeight * 0.03),
                          const Divider(color: Colors.black54, height: 1),
                          SizedBox(height: cardHeight * 0.02),
                          Row(
                            children: [
                              // Imagen del guerrero
                              Container(
                                height: imagenSize * 0.7,
                                width: imagenSize * 0.7,
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: AssetImage(guerrero.imagen),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: cardHeight * 0.03),
                              // Stats del guerrero
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      guerrero.nombreId,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: fontSizeStats,
                                      ),
                                    ),
                                    SizedBox(height: cardHeight * 0.01),
                                    Wrap(
                                      spacing: cardHeight * 0.02,
                                      children: [
                                        _buildStat(
                                          '⚔️',
                                          guerrero.ataque,
                                          cardHeight,
                                        ),
                                        _buildStat(
                                          '❤️',
                                          guerrero.vida,
                                          cardHeight,
                                        ),
                                        _buildStat(
                                          '⚡',
                                          guerrero.costoInvocacion,
                                          cardHeight,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper para stats responsivos
  Widget _buildStat(String icon, int value, double cardHeight) {
    final fontSize = cardHeight * 0.045;
    final iconSize = cardHeight * 0.05;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: iconSize)),
        SizedBox(width: cardHeight * 0.01),
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
