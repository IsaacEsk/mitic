import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/guerrero_model.dart';

/// Helper methods to load data from assets.
///
/// This keeps JSON processing out of widgets so the UI code stays
/// cleaner and easier to maintain.
class GuerreroService {
  GuerreroService._(); // prevent instantiation

  /// Load the list of warriors from `assets/data/personajes.json`.
  static Future<List<Guerrero>> loadGuerreros() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/personajes.json',
    );
    final list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => Guerrero.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Load a translation map for the given [locale] (e.g. 'es', 'en').
  static Future<Map<String, String>> loadTranslations(String locale) async {
    final jsonString = await rootBundle.loadString('assets/data/$locale.json');
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }
}
