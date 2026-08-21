import 'package:flutter/material.dart';
import 'package:mitic/screens/tutorialScreen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selectedLanguage;

  void _selectLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });

    // Navegar al TutorialScreen pasando el idioma seleccionado
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TutorialScreen(selectedLanguage: language),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o título principal
              const Text(
                '🌍 MITIC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Elige tu idioma / Choose your language',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 60),

              // Botón Español
              _buildLanguageButton(
                flag: '🇪🇸',
                language: 'Español',
                code: 'es',
                isSelected: _selectedLanguage == 'es',
              ),
              const SizedBox(height: 20),

              // Botón Inglés
              _buildLanguageButton(
                flag: '🇬🇧',
                language: 'English',
                code: 'en',
                isSelected: _selectedLanguage == 'en',
              ),

              const Spacer(),

              // Texto pequeño de créditos o información
              const Text(
                'Selecciona un idioma para continuar',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton({
    required String flag,
    required String language,
    required String code,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectLanguage(code),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[800]!,
            width: 2,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            // Bandera
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 20),
            // Nombre del idioma
            Text(
              language,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 22,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            // Indicador de selección
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[600]!, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
