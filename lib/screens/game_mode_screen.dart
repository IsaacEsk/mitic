import 'package:flutter/material.dart';
import 'package:mitic/screens/online_rooms_screen.dart';
import 'package:mitic/screens/selectCivScreen.dart';

class GameModeScreen extends StatelessWidget {
  final String selectedLanguage;

  const GameModeScreen({super.key, required this.selectedLanguage});

  bool get _isEnglish => selectedLanguage == 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 20),
                  Text(
                    _isEnglish ? 'Choose a game mode' : 'Elige un modo de juego',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _ModeButton(
                    icon: Icons.computer,
                    title: _isEnglish ? 'Play vs. machine' : 'Jugar contra la máquina',
                    subtitle:
                        _isEnglish
                            ? 'Play a local game against the AI'
                            : 'Juega una partida local contra la máquina',
                    color: Colors.amber,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SelectCivScreen(
                                selectedLanguage: selectedLanguage,
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ModeButton(
                    icon: Icons.public,
                    title: _isEnglish ? 'Online multiplayer' : 'Multijugador online',
                    subtitle:
                        _isEnglish
                            ? 'Play with another person'
                            : 'Juega con otra persona',
                    color: Colors.lightBlueAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => OnlineRoomsScreen(
                                selectedLanguage: selectedLanguage,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
