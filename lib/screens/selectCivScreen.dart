import 'package:flutter/material.dart';
import 'package:mitic/screens/SelectAliadosScreen.dart';
import '../services/mitic2_data_service.dart';
import '../models/civilizacion_model.dart';
import '../models/guerrero_model.dart';

class SelectCivScreen extends StatefulWidget {
  final String selectedLanguage; // 👈 NUEVO: recibir el idioma

  const SelectCivScreen({
    super.key,
    required this.selectedLanguage, // 👈 NUEVO
  });

  @override
  State<SelectCivScreen> createState() => _SelectCivScreenState();
}

class _SelectCivScreenState extends State<SelectCivScreen> {
  List<Civilizacion> _civilizaciones = [];
  Map<String, Guerrero> _guerreros = {};
  Map<String, String> _translations = {};
  bool _cargando = true;
  bool _imagenesListas = false;
  String _mensajeCarga = '';

  @override
  void initState() {
    super.initState();
    _mensajeCarga = _textoCarga(
      'cargando_datos',
      'Cargando datos...',
      'Loading data...',
    );
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final translations = await Mitic2DataService.cargarTraducciones(
        widget.selectedLanguage,
      );
      _translations = translations;

      setState(() {
        _mensajeCarga = _textoCarga(
          'cargando_civilizaciones',
          'Cargando civilizaciones...',
          'Loading civilizations...',
        );
      });

      final data = await Mitic2DataService.cargarTodo();
      final civs = data['civilizaciones'] as Map<String, Civilizacion>;
      final guerrerosBase = data['guerreros'] as Map<String, Guerrero>;

      final guerreros = guerrerosBase.map(
        (id, guerrero) => MapEntry(
          id,
          Guerrero(
            id: guerrero.id,
            nombreId: translations[guerrero.nombreId] ?? guerrero.nombreId,
            descripcionId:
                translations[guerrero.descripcionId] ?? guerrero.descripcionId,
            civilizacionId: guerrero.civilizacionId,
            ataque: guerrero.ataque,
            vida: guerrero.vida,
            costoInvocacion: guerrero.costoInvocacion,
            imagen: guerrero.imagen,
          ),
        ),
      );

      setState(() {
        _civilizaciones = civs.values.toList();
        _guerreros = guerreros;
        _translations = translations;
      });

      setState(() {
        _mensajeCarga = _textoCarga(
          'precargando_imagenes',
          'Precargando imágenes...',
          'Preloading images...',
        );
      });

      await _precacheAllImages();

      setState(() {
        _imagenesListas = true;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() {
        _mensajeCarga = _textoCarga(
          'error_carga',
          'Error cargando datos',
          'Error loading data',
        );
        _cargando = false;
      });
    }
  }

  String _textoCarga(String clave, String espanol, String ingles) {
    return _translations[clave] ??
        (widget.selectedLanguage == 'en' ? ingles : espanol);
  }

  Future<void> _precacheAllImages() async {
    final List<String> monumentosPaths =
        _civilizaciones.map((civ) {
          return civ.muralla.imagen;
        }).toList();

    final List<String> guerrerosPaths =
        _guerreros.values.map((guerrero) {
          return guerrero.imagen;
        }).toList();

    final List<String> allPaths = [...monumentosPaths, ...guerrerosPaths];
    final uniquePaths = allPaths.toSet().toList();

    final List<Future> precacheFutures =
        uniquePaths.map((path) {
          return precacheImage(AssetImage(path), context);
        }).toList();

    try {
      await Future.wait(precacheFutures);
      print('✅ Imágenes precargadas: ${uniquePaths.length}');
    } catch (e) {
      print('⚠️ Error precargando algunas imágenes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: _cargando ? _buildLoadingScreen() : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            _mensajeCarga,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '⚔️ Mitic',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // 👇 OBTENER TÍTULO TRADUCIDO
    final String titulo =
        _translations['select_civ_titulo'] ??
        (widget.selectedLanguage == 'es'
            ? 'SELECCIONA TU CIVILIZACIÓN'
            : 'SELECT YOUR CIVILIZATION');

    return LayoutBuilder(
      builder: (context, constraints) {
        final double ancho = constraints.maxWidth;
        final double alto = constraints.maxHeight;

        int crossAxisCount = ancho > 900 ? 2 : (ancho > 600 ? 2 : 1);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Título con traducción 👇
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.8,
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
    );
  }

  Widget _buildCivCard(Civilizacion civ, Guerrero? guerrero) {
    final civNombre = _translations[civ.nombreId] ?? civ.nombreId;

    return GestureDetector(
      onTap: () {
        print('🎮 Civilización seleccionada: $civNombre');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SelectAliadosScreen(
                  civilizacionSeleccionada: civ,
                  // 👇 PASAR EL IDIOMA A LA SIGUIENTE PANTALLA
                  selectedLanguage: widget.selectedLanguage,
                ),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cardHeight = constraints.maxHeight;
          final double cardWidth = constraints.maxWidth;

          final double izquierdoWidth = cardWidth * 0.35;
          final double imagenSize = izquierdoWidth * 0.7;
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
                      Text(
                        _translations[civ.muralla.nombreId] ??
                            civ.muralla.nombreId,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: fontSizeNombre,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: cardHeight * 0.01),
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
                        Text(
                          civNombre,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSizeNombre * 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: cardHeight * 0.02),
                        Text(
                          _translations[civ.muralla.descripcionId] ?? '',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: fontSizeDesc,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // SizedBox(height: cardHeight * 0.015),
                        // Text(
                        //   '${_translations['habilidad_especial'] ?? 'Habilidad especial'}: ${_translations[civ.habilidadEspecialId] ?? civ.habilidadEspecialId}',
                        //   style: TextStyle(
                        //     color: Colors.amber[200],
                        //     fontSize: fontSizeDesc,
                        //   ),
                        //   maxLines: 2,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                        if (guerrero != null) ...[
                          SizedBox(height: cardHeight * 0.03),
                          const Divider(color: Colors.black54, height: 1),
                          SizedBox(height: cardHeight * 0.02),
                          Row(
                            children: [
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
