import 'package:flutter/material.dart';
import 'package:mitic/screens/LanguageScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // <-- ESTA ES LA LÍNEA MÁGICA
      title: 'MITIC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      //home: const SelectCivScreen(), // <--- aquí va tu screen
      //home: const TableroScreen(), // <--- Solo para probar el diseño
      //home: const Mitic2Screen(),
      //home: const SelectCivScreen(),
      //home: const TutorialScreen(),
      home: const LanguageScreen(),
    );
  }
}
