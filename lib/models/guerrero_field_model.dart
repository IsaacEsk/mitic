import 'guerrero_model.dart';

class GuerreroField {
  Guerrero guerreroBase; // Los datos originales del JSON
  int vidaActual;
  int ataqueActual;
  bool yaAtacoEsteTurno;
  int posicion; // 0,1,2 (o 3 si china)

  GuerreroField({
    required this.guerreroBase,
    required this.vidaActual,
    required this.ataqueActual,
    this.yaAtacoEsteTurno = false,
    required this.posicion,
  });

  // Constructor desde un Guerrero
  factory GuerreroField.vacio({required int posicion}) {
    return GuerreroField(
      guerreroBase: Guerrero(
        id: '',
        nombreId: '',
        descripcionId: '',
        civilizacionId: '',
        ataque: 0,
        vida: 0,
        costoInvocacion: 0,
        imagen: '',
      ),
      vidaActual: 0,
      ataqueActual: 0,
      posicion: posicion,
    );
  }
}
