import 'package:flutter/material.dart';
import 'package:mitic/screens/tablero_screen.dart';
import 'screens/select_civ.dart'; // <--- importas tu screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MITIC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      //home: const SelectCivScreen(), // <--- aquí va tu screen
      //home: const TableroScreen(), // <--- Solo para probar el diseño
    );
  }
}
