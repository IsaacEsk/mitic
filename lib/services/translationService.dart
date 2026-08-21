import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TranslationService {
  static Future<Map<String, String>> loadTranslations(String locale) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/$locale.json',
      );
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Error loading translations: $e');
      return {};
    }
  }
}
