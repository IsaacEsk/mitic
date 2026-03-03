import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/civilizacion_model.dart';

/// Loads civilization data and translations from assets.
///
/// This mirrors the behaviour of [GuerreroService] so that the UI code can
/// remain symmetrical when switching between warriors and monuments.
class CivilizacionService {
  CivilizacionService._(); // prevent instantiation

  /// Returns the list of civilizaciones parsed from the JSON file.
  static Future<List<Civilizacion>> loadCivilizaciones() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/civilizaciones.json',
    );
    final list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => Civilizacion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Translation loader is identical to GuerreroService; keep a copy here
  /// so callers don't have to import the other service.
  static Future<Map<String, String>> loadTranslations(String locale) async {
    final jsonString = await rootBundle.loadString('assets/data/$locale.json');
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }
}
