import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mitic/models/aldeano_model.dart';
import 'package:mitic/models/cultivo_model.dart';
import 'package:mitic/models/hospital_model.dart';
import 'package:mitic/models/torre_model.dart';
import '../models/guerrero_model.dart';
import '../models/civilizacion_model.dart';

class Mitic2DataService {
  Mitic2DataService._(); // Prevenir instanciación

  // ============================================
  // CARGAR TODOS LOS DATOS NECESARIOS
  // ============================================
  static Future<Map<String, dynamic>> cargarTodo() async {
    try {
      // 1. Cargar JSONs
      final guerrerosJson = await rootBundle.loadString(
        'assets/data/personajes.json',
      );
      final civilizacionesJson = await rootBundle.loadString(
        'assets/data/civilizaciones.json',
      );
      final translations = await cargarTraducciones('es');

      // 2. Parsear JSONs
      final List<dynamic> guerrerosList = json.decode(guerrerosJson);
      final List<dynamic> civilizacionesList = json.decode(civilizacionesJson);

      // 3. Crear mapas
      final Map<String, Guerrero> guerreros = {};
      final Map<String, Civilizacion> civilizaciones = {};

      // 4. Procesar guerreros conservando sus IDs de traducción
      for (var item in guerrerosList) {
        final guerrero = Guerrero.fromJson(item);
        guerreros[guerrero.id] = guerrero;
      }

      // 5. Procesar civilizaciones
      for (var item in civilizacionesList) {
        final civ = Civilizacion.fromJson(item);
        civilizaciones[civ.id] = civ;
      }

      return {
        'guerreros': guerreros,
        'civilizaciones': civilizaciones,
        'translations': translations,
      };
    } catch (e) {
      print('❌ Error cargando datos: $e');
      return {};
    }
  }

  // ============================================
  // CARGAR TRADUCCIONES
  // ============================================
  static Future<Map<String, String>> cargarTraducciones(String locale) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/$locale.json',
      );
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      print('❌ Error cargando traducciones: $e');
      return {};
    }
  }

  static Future<Map<String, Torre>> cargarTorres() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/torres.json');
      final List<dynamic> lista = json.decode(jsonString);

      final Map<String, Torre> torres = {};
      for (var item in lista) {
        final torre = Torre.fromJson(item);
        torres[torre.id] = torre;
      }
      return torres;
    } catch (e) {
      print('❌ Error cargando torres: $e');
      return {};
    }
  }

  static Future<Map<String, Hospital>> cargarHospitales() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/hospitales.json',
      );
      final List<dynamic> lista = json.decode(jsonString);

      final Map<String, Hospital> hospitales = {};
      for (var item in lista) {
        final hospital = Hospital.fromJson(item);
        hospitales[hospital.id] = hospital;
      }
      return hospitales;
    } catch (e) {
      print('❌ Error cargando hospitales: $e');
      return {};
    }
  }

  static Future<Map<String, Cultivo>> cargarCultivos() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/cultivos.json',
      );
      final List<dynamic> lista = json.decode(jsonString);

      final Map<String, Cultivo> cultivos = {};
      for (var item in lista) {
        final cultivo = Cultivo.fromJson(item);
        cultivos[cultivo.id] = cultivo;
      }
      return cultivos;
    } catch (e) {
      print('❌ Error cargando cultivos: $e');
      return {};
    }
  }

  static Future<Map<String, Aldeano>> cargarAldeanos() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/aldeanos.json',
      );
      final List<dynamic> lista = json.decode(jsonString);

      final Map<String, Aldeano> aldeanos = {};
      for (var item in lista) {
        final aldeano = Aldeano.fromJson(item);
        aldeanos[aldeano.id] = aldeano;
      }
      return aldeanos;
    } catch (e) {
      print('❌ Error cargando aldeanos: $e');
      return {};
    }
  }
}
