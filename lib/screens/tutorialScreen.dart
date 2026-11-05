import 'package:flutter/material.dart';
import 'package:mitic/screens/game_mode_screen.dart';
import 'package:mitic/screens/tutorial_board_screen.dart';
import 'package:mitic/services/translationService.dart';

class TutorialScreen extends StatefulWidget {
  final String selectedLanguage;

  const TutorialScreen({super.key, required this.selectedLanguage});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  Map<String, String> _translations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    final translations = await TranslationService.loadTranslations(
      widget.selectedLanguage,
    );
    if (!mounted) return;
    setState(() {
      _translations = translations;
      _isLoading = false;
    });
  }

  void _skipTutorial() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                GameModeScreen(selectedLanguage: widget.selectedLanguage),
      ),
      (route) => false,
    );
  }

  void _openHowToPlay() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                TutorialBoardScreen(selectedLanguage: widget.selectedLanguage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 700;
            final textFontSize = isSmallScreen ? 24.0 : 28.0;
            final descFontSize = isSmallScreen ? 14.0 : 16.0;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _translations['tutorial_titulo_1'] ?? 'Bienvenida',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _translations['tutorial_desc_1'] ??
                        'Bienvenido a Mitic, un juego de estrategia por turnos.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: descFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/tutorial/tutorial_1.png',
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _skipTutorial,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _translations['tutorial_boton_saltar'] ?? 'Saltar',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _openHowToPlay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _translations['tutorial_boton_como_jugar'] ??
                                'Cómo jugar',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
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
