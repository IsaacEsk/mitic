import 'package:mitic/models/aldeano_campo.dart';
import 'package:mitic/models/cultivo_campo.dart';
import 'package:mitic/models/guerrero_field_model_2.0.dart';
import 'package:mitic/models/hospital_campo.dart';
import 'package:mitic/models/torre_campo.dart';

// ============================================
// ENUM PARA IDENTIFICAR EL TIPO DE CASILLA
// ============================================
enum TipoCasilla {
  vacia,
  monumento,
  guerrero,
  torre,
  hospital,
  cultivo,
  aldeano,
}

// ============================================
// CLASE BASE ABSTRACT
// ============================================
abstract class Casilla {
  final String coordenada;
  final TipoCasilla tipo;

  Casilla({required this.coordenada, required this.tipo});
}

// ============================================
// CASILLA VACÍA
// ============================================
class CasillaVacia extends Casilla {
  CasillaVacia({required super.coordenada}) : super(tipo: TipoCasilla.vacia);
}

// ============================================
// CASILLA MONUMENTO
// ============================================
class CasillaMonumento extends Casilla {
  final String civilizacionId;
  final String nombre;
  int vidaActual;
  final String imagenPath;
  bool resplandor = false;

  CasillaMonumento({
    required super.coordenada,
    required this.civilizacionId,
    required this.nombre,
    required this.vidaActual,
    required this.imagenPath,
    this.resplandor = false,
  }) : super(tipo: TipoCasilla.monumento);
}

// ============================================
// CASILLA GUERRERO
// ============================================
class CasillaGuerrero extends Casilla {
  final GuerreroCampo guerrero;

  CasillaGuerrero({required super.coordenada, required this.guerrero})
    : super(tipo: TipoCasilla.guerrero);
}

// ============================================
// CASILLA TORRE
// ============================================
class CasillaTorre extends Casilla {
  final TorreCampo torre;

  CasillaTorre({required super.coordenada, required this.torre})
    : super(tipo: TipoCasilla.torre);
}

// ============================================
// CASILLA HOSPITAL
// ============================================
class CasillaHospital extends Casilla {
  final HospitalCampo hospital;

  CasillaHospital({required super.coordenada, required this.hospital})
    : super(tipo: TipoCasilla.hospital);
}

// ============================================
// CASILLA CULTIVO
// ============================================
class CasillaCultivo extends Casilla {
  final CultivoCampo cultivo;

  CasillaCultivo({required super.coordenada, required this.cultivo})
    : super(tipo: TipoCasilla.cultivo);
}

// ============================================
// CASILLA ALDEANO
// ============================================
class CasillaAldeano extends Casilla {
  final AldeanoCampo aldeano;

  CasillaAldeano({required super.coordenada, required this.aldeano})
    : super(tipo: TipoCasilla.aldeano);
}
