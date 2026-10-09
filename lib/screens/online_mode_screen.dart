import 'package:flutter/material.dart';

class OnlineModeScreen extends StatelessWidget {
  final String selectedLanguage;

  const OnlineModeScreen({super.key, required this.selectedLanguage});

  bool get _isEnglish => selectedLanguage == 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_isEnglish ? 'Online multiplayer' : 'Multijugador online'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, color: Colors.amber, size: 72),
              const SizedBox(height: 24),
              Text(
                _isEnglish
                    ? 'Online mode is in progress'
                    : 'Estamos trabajando en el modo online',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isEnglish
                    ? 'This feature will be available soon.'
                    : 'Esta función estará disponible próximamente.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  _isEnglish ? 'Back to modes' : 'Volver a los modos',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
