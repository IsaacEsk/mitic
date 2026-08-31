import 'package:flutter/material.dart';
import 'package:mitic/screens/selectCivScreen.dart';
import 'package:mitic/services/translationService.dart';

class TutorialScreen extends StatefulWidget {
  final String selectedLanguage;

  const TutorialScreen({super.key, required this.selectedLanguage});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentStep = 0;
  late Map<String, String> _translations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    // Usamos el idioma que recibimos como parámetro
    final translations = await TranslationService.loadTranslations(
      widget.selectedLanguage,
    );
    setState(() {
      _translations = translations;
      _isLoading = false;
    });
  }

  String _getImagenPath(int step) {
    final isGif = step == 2 || step == 4 || (step >= 9 && step <= 12);
    final extension = isGif ? 'gif' : 'png';
    return 'assets/images/tutorial/tutorial_$step.$extension';
  }

  void _goToSelectCiv() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => SelectCivScreen(
              selectedLanguage: widget.selectedLanguage, // 👈 Pasar el idioma
            ),
      ),
      (route) => false,
    );
  }

  void _nextStep() {
    if (_currentStep < 11) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Último paso -> ir a SelectCivScreen
      _goToSelectCiv();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final stepNumber = _currentStep + 1;
    final tituloKey = 'tutorial_titulo_$stepNumber';
    final descKey = 'tutorial_desc_$stepNumber';
    final imagenPath = _getImagenPath(stepNumber);

    // Textos de los botones desde el JSON
    final String saltarText =
        _translations['tutorial_boton_saltar'] ?? 'Saltar';
    final String atrasText = _translations['tutorial_boton_atras'] ?? 'Atrás';
    final String siguienteText =
        _translations['tutorial_boton_siguiente'] ?? 'Siguiente';
    final String comenzarText =
        _translations['tutorial_boton_comenzar'] ?? 'Comenzar';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 1. TÍTULO Y DESCRIPCIÓN
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _translations[tituloKey] ?? 'Título no encontrado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _translations[descKey] ?? 'Descripción no encontrada',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // 2. ÁREA DE LA IMAGEN
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          imagenPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // 3. INDICADORES Y BOTONES
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Puntos indicadores
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            12,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentStep == index ? 12 : 8,
                              height: _currentStep == index ? 12 : 8,
                              decoration: BoxDecoration(
                                color:
                                    _currentStep == index
                                        ? Colors.white
                                        : Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Botones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Botón "Saltar" o "Atrás"
                            TextButton(
                              onPressed:
                                  _currentStep == 0
                                      ? _goToSelectCiv // Si es el primer paso, "Saltar" lleva a SelectCiv
                                      : _previousStep,
                              child: Text(
                                _currentStep == 0 ? saltarText : atrasText,
                                style: TextStyle(
                                  color:
                                      _currentStep == 0
                                          ? Colors
                                              .white // El botón "Saltar" siempre visible
                                          : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // Botón "Siguiente" o "Comenzar"
                            ElevatedButton(
                              onPressed: _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                _currentStep == 11
                                    ? comenzarText
                                    : siguienteText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
