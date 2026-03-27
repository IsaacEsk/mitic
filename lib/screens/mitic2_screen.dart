import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mitic/ia/ia_factory.dart';
import 'package:mitic/models/aldeano_campo.dart';
import 'package:mitic/models/aldeano_model.dart';
import 'package:mitic/models/casilla.dart';
import 'package:mitic/models/civilizacion_model.dart';
import 'package:mitic/models/cultivo_campo.dart';
import 'package:mitic/models/cultivo_model.dart';
import 'package:mitic/models/guerrero_field_model_2.0.dart';
import 'package:mitic/models/guerrero_model.dart';
import 'package:mitic/models/hospital_campo.dart';
import 'package:mitic/models/hospital_model.dart';
import 'package:mitic/models/juego2.dart';
import 'package:mitic/models/jugador2.dart';
import 'package:mitic/models/monument_model.dart';
import 'package:mitic/models/tablero.dart';
import 'package:mitic/models/torre_campo.dart';
import 'package:mitic/models/torre_model.dart';
import 'package:mitic/services/mitic2_data_service.dart';
import 'package:mitic/widgets/aldeano_tablero.dart';
import 'package:mitic/widgets/cultivo_tablero.dart';
import 'package:mitic/widgets/guerrero_tablero.dart';
import 'package:mitic/widgets/hospital_tablero.dart';
import 'package:mitic/widgets/monumento_tablero.dart';
import 'package:mitic/widgets/torre_tablero.dart';
import '../widgets/casilla_vacia.dart';
import '../widgets/casilla_vacia_enemiga.dart';

class Mitic2Screen extends StatefulWidget {
  const Mitic2Screen({super.key});

  @override
  State<Mitic2Screen> createState() => _Mitic2ScreenState();
}

class _Mitic2ScreenState extends State<Mitic2Screen> {
  int puntosAcumulados = 25;

  // En tu State
  Map<String, Guerrero>? guerreros;
  Map<String, Civilizacion>? civilizaciones;
  Map<String, Torre>? torres;
  Map<String, Hospital>? hospitales; // 👈 NUEVO
  Map<String, Cultivo>? cultivos;
  Map<String, Aldeano>? aldeanos;
  late Juego2 juego;
  bool _cargado = false;
  int? _filaSeleccionada;
  int? _columnaSeleccionada;
  String? _coordenadaSeleccionada;
  InvocableItem? _itemPendiente;
  bool _modoMover = false;
  CasillaAldeano? _aldeanoParaMover;
  bool _modoMoverGuerrero = false;
  CasillaGuerrero? _guerreroParaMover;
  bool _dadosLanzadosEsteTurno = false;
  bool _juegoTerminado = false;

  @override
  void initState() {
    super.initState();
    //_cargarDatos();
    _inicializarJuego();
  }

  Future<void> _inicializarJuego() async {
    // ============================================
    // 1. CARGAR DATOS
    // ============================================
    final datos = await Mitic2DataService.cargarTodo();
    final guerreros = datos['guerreros'] as Map<String, Guerrero>;
    final civilizaciones = datos['civilizaciones'] as Map<String, Civilizacion>;

    _cargarDatos();

    // ============================================
    // 2. CREAR GUERREROS (inventamos selección)
    // ============================================
    final guerrerosAztecas = [
      guerreros['azteca_001']!,
      guerreros['maya_001']!,
      guerreros['china_001']!,
      guerreros['romanos_001']!,
    ];

    final guerrerosMayas = [
      guerreros['maya_001']!,
      guerreros['azteca_001']!,
      guerreros['japon_001']!,
      guerreros['egipcios_001']!,
    ];

    // ============================================
    // 3. CREAR CIVILIZACIONES
    // ============================================
    final azteca = civilizaciones['azteca']!;
    final maya = civilizaciones['maya']!;

    // ============================================
    // 4. CREAR JUGADORES CON TABLEROS VACÍOS
    // ============================================
    final jugador1 = Jugador2.inicial(
      civilizacion: azteca,
      guerrerosSeleccionados: guerrerosAztecas,
      monumentoEnCampo: MonumentField.fromCivilizacion(azteca),
      puntosAcumulados: 100,
      turno: 0,
      esEnemigo: false, // 👈 Tú no eres enemigo
    );

    final jugador2 = Jugador2.inicial(
      civilizacion: maya,
      guerrerosSeleccionados: guerrerosMayas,
      monumentoEnCampo: MonumentField.fromCivilizacion(maya),
      puntosAcumulados: 0,
      turno: 1,
      esEnemigo: true, // 👈 Enemigo sí
    );

    // ============================================
    // 5. CREAR JUEGO
    // ============================================
    setState(() {
      juego = Juego2(jugadores: [jugador1, jugador2], turnoActual: 0);
      _cargado = true;
    });
  }

  Future<void> _cargarDatos() async {
    final datos = await Mitic2DataService.cargarTodo();
    final torresData = await Mitic2DataService.cargarTorres();
    final hospitalesData = await Mitic2DataService.cargarHospitales();
    final cultivosData = await Mitic2DataService.cargarCultivos();
    final aldeanosData = await Mitic2DataService.cargarAldeanos();

    setState(() {
      guerreros = datos['guerreros'] as Map<String, Guerrero>?;
      civilizaciones = datos['civilizaciones'] as Map<String, Civilizacion>?;
      torres = torresData;
      hospitales = hospitalesData;
      cultivos = cultivosData;
      aldeanos = aldeanosData;
      _cargado = true;
    });

    print('✅ Datos cargados:');
    print('   - ${guerreros?.length} guerreros');
    print('   - ${civilizaciones?.length} civilizaciones');
    print('   - ${torres?.length} torres');
    print('   - ${hospitales?.length} hospitales');
    print('   - ${cultivos?.length} cultivos');
    print('   - ${aldeanos?.length} aldeanos');
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (!_cargado) {
      return const Scaffold(
        backgroundColor: Colors.grey,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double ancho = constraints.maxWidth;
            final double alto = constraints.maxHeight;

            // Calcular tamaño de celda (inteligente)
            double ladoPorAncho = ancho / 5;
            //double ladoPorAlto = alto / 11;
            double ladoPorAlto = alto / 9.2;
            double ladoCelda =
                ladoPorAncho < ladoPorAlto ? ladoPorAncho : ladoPorAlto;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ladoCelda * 5,
                  maxHeight: ladoCelda * 9.2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stats enemigo (Jugador 2)
                    _buildStatsFila(
                      ladoCelda: ladoCelda,
                      jugador: juego.jugadores[1],
                      esEnemigo: true,
                    ),

                    // Tablero enemigo (filaIndex 0 a 3)
                    ...List.generate(4, (filaIndex) {
                      return _buildTableroFila(
                        filaIndex: filaIndex,
                        ladoCelda: ladoCelda,
                        jugador: juego.jugadores[1],
                        esEnemigo: true,
                      );
                    }),

                    // Línea divisoria
                    Container(
                      height: ladoCelda * .2,
                      child: Center(
                        child: Text(
                          '⚔️ MITIC 2.0 ⚔️',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: ladoCelda * 0.1,
                          ),
                        ),
                      ),
                    ),

                    // Tablero propio (Jugador 1)
                    ...List.generate(4, (filaIndex) {
                      return _buildTableroFila(
                        filaIndex: filaIndex,
                        ladoCelda: ladoCelda,
                        jugador: juego.jugadores[0],
                        esEnemigo: false,
                      );
                    }),

                    // Stats propios (Jugador 1)
                    _buildStatsFila(
                      ladoCelda: ladoCelda,
                      jugador: juego.jugadores[0],
                      esEnemigo: false,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsFila({
    required double ladoCelda,
    required Jugador2 jugador,
    required bool esEnemigo,
  }) {
    return SizedBox(
      height: ladoCelda * 0.5,
      child: Row(
        children: List.generate(5, (columna) {
          // Casilla de puntos (columna 2)
          if (columna == 2) {
            return Container(
              width: ladoCelda,
              decoration: BoxDecoration(
                color:
                    esEnemigo
                        ? Colors.red[900]?.withOpacity(0.2)
                        : Colors.green[900]?.withOpacity(0.2),
                border: Border.all(
                  color: esEnemigo ? Colors.red : Colors.green,
                  width: 1,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: Colors.amber,
                      size: ladoCelda * 0.2,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${jugador.puntosAcumulados}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ladoCelda * 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Casilla del botón de pasar (columna 4)
          if (columna == 4 && !esEnemigo) {
            return Container(
              width: ladoCelda,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    print('🎮 Botón PASAR presionado');
                    _cambiarTurno();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: Size(ladoCelda * 0.8, ladoCelda * 0.3),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'PASAR',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }

          // Casillas vacías
          return Container(
            width: ladoCelda,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTableroFila({
    required int filaIndex, // 0 a 3 (índice real de la fila en el tablero)
    required double ladoCelda,
    required Jugador2 jugador,
    required bool esEnemigo,
  }) {
    return SizedBox(
      height: ladoCelda,
      child: Row(
        children: List.generate(5, (columna) {
          // Obtener la casilla del tablero usando el índice real
          final casilla = jugador.tablero.obtenerCasillaPorIndices(
            filaIndex,
            columna,
          );

          // Determinar la coordenada para mostrar (solo debug)
          String coordenada;
          if (esEnemigo) {
            // Para enemigo: mostramos la fila como está (0 arriba, 3 abajo)
            coordenada = '${String.fromCharCode(65 + columna)}$filaIndex';
          } else {
            // Para ti: invertimos para que 0 sea abajo
            int filaInvertida = 3 - filaIndex;
            coordenada = '${String.fromCharCode(65 + columna)}$filaInvertida';
          }

          // Determinar si es monumento (NO por coordenada, por tipo de casilla)
          final bool esMonumento = casilla.tipo == TipoCasilla.monumento;

          switch (casilla.tipo) {
            case TipoCasilla.vacia:
              if (esEnemigo) {
                return CasillaVaciaEnemiga(
                  ladoCelda: ladoCelda,
                  coordenada: coordenada,
                );
              } else {
                return CasillaVaciaw(
                  ladoCelda: ladoCelda,
                  coordenada: coordenada,
                  onPressed: () {
                    print(
                      '🎯 Debug: _modoMover = $_modoMover, _modoMoverGuerrero = $_modoMoverGuerrero',
                    );
                    print(
                      '🎯 Debug: _aldeanoParaMover = $_aldeanoParaMover, _guerreroParaMover = $_guerreroParaMover',
                    );

                    // Prioridad: mover aldeano
                    if (_modoMover && _aldeanoParaMover != null) {
                      print('👉 Entrando a mover aldeano');
                      _moverAldeano(_aldeanoParaMover!, filaIndex, columna);
                    }
                    // Prioridad: mover guerrero
                    else if (_modoMoverGuerrero && _guerreroParaMover != null) {
                      print('👉 Entrando a mover guerrero');
                      _moverGuerrero(_guerreroParaMover!, filaIndex, columna);
                    }
                    // Si no, invocar
                    else {
                      print('👉 Entrando a invocar');
                      _mostrarModalInvocacion(
                        fila: filaIndex,
                        columna: columna,
                        coordenada: coordenada,
                      );
                    }
                  },
                );
              }

            case TipoCasilla.monumento:
              final monumento = casilla as CasillaMonumento;
              return MonumentoTablero(
                ladoCelda: ladoCelda,
                imagenPath: monumento.imagenPath,
                vida: monumento.vidaActual,
                onTap: () {
                  if (esEnemigo) {
                    return null;
                  }
                  // ============================================
                  // VALIDACIÓN PARA MODO MOVER
                  // ============================================
                  if (_modoMover || _modoMoverGuerrero) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Solo puedes mover a casillas vacías'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  print('📍 Clic en monumento ${monumento.nombre}');
                  _mostrarModalReconstruir(monumento);
                },
              );

            case TipoCasilla.guerrero:
              final casillaGuerrero = casilla as CasillaGuerrero;
              return GuerreroTablero(
                ladoCelda: ladoCelda,
                guerrero: casillaGuerrero.guerrero,
                onTap: () {
                  if (esEnemigo) {
                    return null;
                  }
                  // ============================================
                  // VALIDACIÓN PARA MODO MOVER
                  // ============================================
                  if (_modoMover || _modoMoverGuerrero) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Solo puedes mover a casillas vacías'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  print('📍 Clic en guerrero en $coordenada');
                  _mostrarModalGuerrero(casillaGuerrero);
                },
              );

            case TipoCasilla.torre:
              final casillaTorre = casilla as CasillaTorre;
              return TorreTablero(
                ladoCelda: ladoCelda,
                torre: casillaTorre.torre,
                onTap: () {
                  if (esEnemigo) {
                    return null;
                  }
                  // ===========
                  // =================================
                  // VALIDACIÓN PARA MODO MOVER
                  // ============================================
                  if (_modoMover || _modoMoverGuerrero) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Solo puedes mover a casillas vacías'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  _mostrarModalTorre(casillaTorre);
                  print('📍 Torre en $coordenada');
                },
              );

            case TipoCasilla.hospital:
              final casillaHospital = casilla as CasillaHospital;
              return HospitalTablero(
                ladoCelda: ladoCelda,
                hospital: casillaHospital.hospital,
                onTap: () {
                  if (esEnemigo) {
                    return null;
                  }
                  // ============================================
                  // VALIDACIÓN PARA MODO MOVER
                  // ============================================
                  if (_modoMover || _modoMoverGuerrero) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Solo puedes mover a casillas vacías'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  _mostrarModalHospital(casillaHospital);
                },
              );

            case TipoCasilla.cultivo:
              final casillaCultivo = casilla as CasillaCultivo;
              return CultivoTablero(
                ladoCelda: ladoCelda,
                cultivo: casillaCultivo.cultivo,
                onTap: () {
                  if (esEnemigo) {
                    return null;
                  }
                  // ============================================
                  // VALIDACIÓN PARA MODO MOVER
                  // ============================================
                  if (_modoMover || _modoMoverGuerrero) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Solo puedes mover a casillas vacías'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  _mostrarModalCultivo(casillaCultivo);
                },
              );

            case TipoCasilla.aldeano:
              final casillaAldeano = casilla as CasillaAldeano;
              return AldeanoTablero(
                ladoCelda: ladoCelda,
                aldeano: casillaAldeano.aldeano,
                onTap: () {
                  if (esEnemigo) {
                    return null;
                  }
                  // ============================================
                  // VALIDACIÓN PARA MODO MOVER
                  // ============================================
                  if (_modoMover || _modoMoverGuerrero) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Solo puedes mover a casillas vacías'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    return;
                  }
                  _mostrarModalAldeano(casillaAldeano);
                },
              );

            default:
              return Container(
                width: ladoCelda,
                height: ladoCelda,
                color: Colors.purple.withOpacity(0.3),
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ladoCelda * 0.3,
                    ),
                  ),
                ),
              );
          }
        }),
      ),
    );
  }

  void _mostrarModalInvocacion({
    required int fila,
    required int columna,
    required String coordenada,
  }) {
    final jugador = juego.jugadorActual;

    _filaSeleccionada = fila;
    _columnaSeleccionada = columna;
    _coordenadaSeleccionada = coordenada;
    // ============================================
    // FILTRAR GUERREROS QUE PUEDE PAGAR
    // ============================================
    final guerrerosDisponibles =
        jugador.guerrerosSeleccionados
            .where((g) => g.costoInvocacion <= jugador.puntosAcumulados)
            .toList();

    // ============================================
    // CONSTRUCCIONES DE SU CIVILIZACIÓN
    // ============================================
    final List<InvocableItem> construcciones = [];

    // ============================================
    // TORRE DE SU CIVILIZACIÓN
    // ============================================
    if (torres != null) {
      final torresCiv =
          torres!.values
              .where((t) => t.civilizacionId == jugador.civilizacion.id)
              .toList();

      if (torresCiv.isNotEmpty) {
        final torreCiv = torresCiv.first;
        if (torreCiv.costoInvocacion <= jugador.puntosAcumulados) {
          construcciones.add(
            InvocableItem(
              id: torreCiv.id,
              nombre: torreCiv.nombre,
              imagenPath: torreCiv.imagen,
              costo: torreCiv.costoInvocacion,
              tipo: 'torre',
              datos: torreCiv,
            ),
          );
        }
      }
    }

    // ============================================
    // HOSPITAL DE SU CIVILIZACIÓN
    // ============================================
    if (hospitales != null) {
      final hospitalesCiv =
          hospitales!.values
              .where((h) => h.civilizacionId == jugador.civilizacion.id)
              .toList();

      if (hospitalesCiv.isNotEmpty) {
        final hospitalCiv = hospitalesCiv.first;
        if (hospitalCiv.costoInvocacion <= jugador.puntosAcumulados) {
          construcciones.add(
            InvocableItem(
              id: hospitalCiv.id,
              nombre: hospitalCiv.nombre,
              imagenPath: hospitalCiv.imagen,
              costo: hospitalCiv.costoInvocacion,
              tipo: 'hospital',
              datos: hospitalCiv,
            ),
          );
        }
      }
    }

    // ============================================
    // CULTIVO DE SU CIVILIZACIÓN
    // ============================================
    if (cultivos != null) {
      final cultivosCiv =
          cultivos!.values
              .where((c) => c.civilizacionId == jugador.civilizacion.id)
              .toList();

      if (cultivosCiv.isNotEmpty) {
        final cultivoCiv = cultivosCiv.first;
        if (cultivoCiv.costoInvocacion <= jugador.puntosAcumulados) {
          construcciones.add(
            InvocableItem(
              id: cultivoCiv.id,
              nombre: cultivoCiv.nombre,
              imagenPath: cultivoCiv.imagen,
              costo: cultivoCiv.costoInvocacion,
              tipo: 'cultivo',
              datos: cultivoCiv,
            ),
          );
        }
      }
    }

    // ============================================
    // ALDEANO DE SU CIVILIZACIÓN
    // ============================================
    if (aldeanos != null) {
      final aldeanosCiv =
          aldeanos!.values
              .where((a) => a.civilizacionId == jugador.civilizacion.id)
              .toList();

      if (aldeanosCiv.isNotEmpty) {
        final aldeanoCiv = aldeanosCiv.first;
        if (aldeanoCiv.costoInvocacion <= jugador.puntosAcumulados) {
          construcciones.add(
            InvocableItem(
              id: aldeanoCiv.id,
              nombre: aldeanoCiv.nombre,
              imagenPath: aldeanoCiv.imagen,
              costo: aldeanoCiv.costoInvocacion,
              tipo: 'aldeano',
              datos: aldeanoCiv,
            ),
          );
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CABECERA
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[800],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.amber[700]!, Colors.amber[900]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '⚡ INVOCAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${jugador.puntosAcumulados} ⚡',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // GUERREROS DISPONIBLES
                if (guerrerosDisponibles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      '⚔️ GUERREROS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildFilaInvocacion(
                    items:
                        guerrerosDisponibles.map((g) {
                          return InvocableItem(
                            id: g.id,
                            nombre: g.nombreId,
                            imagenPath: g.imagen,
                            costo: g.costoInvocacion,
                            tipo: 'guerrero',
                            datos: g,
                          );
                        }).toList(),
                    puntos: jugador.puntosAcumulados,
                    onSeleccionar: (item) {
                      _invocar(item, jugador);
                    },
                  ),
                ],

                // CONSTRUCCIONES DE LA CIVILIZACIÓN
                if (construcciones.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      '🏗️ 🏰 🏥 🌱 🔨 👨',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildFilaInvocacion(
                    items: construcciones,
                    puntos: jugador.puntosAcumulados,
                    onSeleccionar: (item) {
                      _invocar(item, jugador);
                    },
                  ),
                ],

                // MENSAJE SI NO HAY NADA
                if (guerrerosDisponibles.isEmpty && construcciones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '❌ No tienes puntos suficientes\npara invocar nada',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),

                // BOTÓN CANCELAR
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: SizedBox(
                //     width: double.infinity,
                //     child: ElevatedButton(
                //       onPressed: () => Navigator.pop(context),
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: Colors.grey[600],
                //         padding: const EdgeInsets.symmetric(vertical: 12),
                //       ),
                //       child: const Text('CANCELAR',),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalGuerrero(CasillaGuerrero casillaGuerrero) {
    final jugador = juego.jugadorActual;
    final guerrero = casillaGuerrero.guerrero;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown[800]!, Colors.brown[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título y nombre
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⚔️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      guerrero.guerreroBase.nombreId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stats actuales
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('⚔️', guerrero.ataqueActual),
                    _buildStat('❤️', guerrero.vidaActual),
                  ],
                ),

                const SizedBox(height: 16),

                // Botones de acción
                _buildBotonAccion(
                  icon: '⚔️',
                  texto: 'ATACAR',
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Lógica de ataque (próximamente)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚔️ Ataque en desarrollo...'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                _buildBotonAccion(
                  icon: '💪',
                  texto: 'MEJORAR ATAQUE',
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarModalPuntos(
                      titulo: '💪 MEJORAR ATAQUE',
                      icono: '⚔️',
                      valorActual: guerrero.ataqueActual,
                      puntosMaximos: jugador.puntosAcumulados,
                      onConfirmar: (puntos) {
                        setState(() {
                          guerrero.ataqueActual += puntos;
                          jugador.puntosAcumulados -= puntos;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ +$puntos ⚔️ a ataque'),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                _buildBotonAccion(
                  icon: '❤️',
                  texto: 'CURAR',
                  color: Colors.green,
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarModalPuntos(
                      titulo: '❤️ CURAR',
                      icono: '❤️',
                      valorActual: guerrero.vidaActual,
                      puntosMaximos: jugador.puntosAcumulados,
                      onConfirmar: (puntos) {
                        setState(() {
                          guerrero.vidaActual += puntos;
                          jugador.puntosAcumulados -= puntos;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ +$puntos ❤️ a vida'),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                _buildBotonAccion(
                  icon: '🚶',
                  texto: 'MOVER',
                  color: Colors.blue,
                  onPressed:
                      _hayCasillasVacias(jugador)
                          ? () {
                            Navigator.pop(context);
                            _modoMoverGuerrero = true;
                            _guerreroParaMover = casillaGuerrero;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '👆 Selecciona una casilla vacía para mover',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                          : null, // 👈 Si no hay casillas vacías, no aparece el botón
                ),

                const SizedBox(height: 8),

                _buildBotonAccion(
                  icon: '❌',
                  texto: 'CANCELAR',
                  color: Colors.grey,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalTorre(CasillaTorre casillaTorre) {
    final jugador = juego.jugadorActual;
    final torre = casillaTorre.torre;

    if (jugador.puntosAcumulados <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No tienes puntos para mejorar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown[800]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🗼', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      'TORRE',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Imagen y stats actuales
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.brown[300],
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(torre.torreBase.imagen),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '🏹 Ataque:',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${torre.ataqueActual}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '🏰 Vida:',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${torre.vidaActual}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Puntos disponibles
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber[800]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${jugador.puntosAcumulados} puntos disponibles',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Dos botones grandes
                Row(
                  children: [
                    // Mejorar Ataque
                    Expanded(
                      child: _buildOpcionMejora(
                        icon: '🏹',
                        titulo: 'MEJORAR ATAQUE',
                        color: Colors.orange,
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarModalPuntos(
                            titulo: '🏹 MEJORAR ATAQUE',
                            icono: '🏹',
                            valorActual: torre.ataqueActual,
                            puntosMaximos: jugador.puntosAcumulados,
                            onConfirmar: (puntos) {
                              setState(() {
                                torre.ataqueActual += puntos;
                                jugador.puntosAcumulados -= puntos;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ +$puntos 🏹 a la torre'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reconstruir
                    Expanded(
                      child: _buildOpcionMejora(
                        icon: '🏰',
                        titulo: 'RECONSTRUIR',
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarModalPuntos(
                            titulo: '🏰 RECONSTRUIR',
                            icono: '🏰',
                            valorActual: torre.vidaActual,
                            puntosMaximos: jugador.puntosAcumulados,
                            onConfirmar: (puntos) {
                              setState(() {
                                torre.vidaActual += puntos;
                                jugador.puntosAcumulados -= puntos;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ +$puntos 🏰 a la torre'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Botón cancelar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalHospital(CasillaHospital casillaHospital) {
    final jugador = juego.jugadorActual;
    final hospital = casillaHospital.hospital;

    if (jugador.puntosAcumulados <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No tienes puntos para mejorar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown[800]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🏥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      'HOSPITAL',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Imagen y stats actuales
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.brown[300],
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(hospital.hospitalBase.imagen),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '💊 Curación:',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${hospital.poderCuracionActual}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '🏥 Vida:',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${hospital.vidaActual}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Puntos disponibles
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber[800]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${jugador.puntosAcumulados} puntos disponibles',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Dos botones grandes
                Row(
                  children: [
                    // Mejorar Curación
                    Expanded(
                      child: _buildOpcionMejora(
                        icon: '💊',
                        titulo: 'MEJORAR CURACIÓN',
                        color: Colors.green,
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarModalPuntos(
                            titulo: '💊 MEJORAR CURACIÓN',
                            icono: '💊',
                            valorActual: hospital.poderCuracionActual,
                            puntosMaximos: jugador.puntosAcumulados,
                            onConfirmar: (puntos) {
                              setState(() {
                                hospital.poderCuracionActual += puntos;
                                jugador.puntosAcumulados -= puntos;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ +$puntos 💊 a curación'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reconstruir
                    Expanded(
                      child: _buildOpcionMejora(
                        icon: '🏥',
                        titulo: 'RECONSTRUIR',
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarModalPuntos(
                            titulo: '🏥 RECONSTRUIR',
                            icono: '🏥',
                            valorActual: hospital.vidaActual,
                            puntosMaximos: jugador.puntosAcumulados,
                            onConfirmar: (puntos) {
                              setState(() {
                                hospital.vidaActual += puntos;
                                jugador.puntosAcumulados -= puntos;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ +$puntos 🏥 al hospital'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Botón cancelar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalCultivo(CasillaCultivo casillaCultivo) {
    final jugador = juego.jugadorActual;
    final cultivo = casillaCultivo.cultivo;

    if (jugador.puntosAcumulados <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No tienes puntos para mejorar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown[800]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🌾', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      'CULTIVO',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Imagen y stats actuales
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.brown[300],
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(cultivo.cultivoBase.imagen),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '🌾 Puntos/turno:',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${cultivo.puntosPorTurnoActual}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '🌱 Vida:',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${cultivo.vidaActual}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Puntos disponibles
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber[800]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${jugador.puntosAcumulados} puntos disponibles',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Dos botones grandes
                Row(
                  children: [
                    // Mejorar Producción
                    Expanded(
                      child: _buildOpcionMejora(
                        icon: '🌾',
                        titulo: 'MEJORAR PRODUCCIÓN',
                        color: Colors.green,
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarModalPuntos(
                            titulo: '🌾 MEJORAR PRODUCCIÓN',
                            icono: '🌾',
                            valorActual: cultivo.puntosPorTurnoActual,
                            puntosMaximos: jugador.puntosAcumulados,
                            onConfirmar: (puntos) {
                              setState(() {
                                cultivo.puntosPorTurnoActual += puntos;
                                jugador.puntosAcumulados -= puntos;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ +$puntos 🌾 a producción'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reconstruir
                    Expanded(
                      child: _buildOpcionMejora(
                        icon: '🌱',
                        titulo: 'RECONSTRUIR',
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarModalPuntos(
                            titulo: '🌱 RECONSTRUIR',
                            icono: '🌱',
                            valorActual: cultivo.vidaActual,
                            puntosMaximos: jugador.puntosAcumulados,
                            onConfirmar: (puntos) {
                              setState(() {
                                cultivo.vidaActual += puntos;
                                jugador.puntosAcumulados -= puntos;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ +$puntos 🌱 al cultivo'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Botón cancelar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalAldeano(CasillaAldeano casillaAldeano) {
    final jugador = juego.jugadorActual;
    final aldeano = casillaAldeano.aldeano;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown[800]!, Colors.brown[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título y nombre
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👨', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      aldeano.aldeanoBase.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stats actuales
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('🔨', aldeano.puntosReconstruccionActual),
                    _buildStat('❤️', aldeano.vidaActual),
                  ],
                ),

                const SizedBox(height: 16),

                // Botones de acción
                _buildBotonAccion(
                  icon: '🔨',
                  texto: 'MEJORAR RECONSTRUCCIÓN',
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarModalPuntos(
                      titulo: '🔨 MEJORAR RECONSTRUCCIÓN',
                      icono: '🔨',
                      valorActual: aldeano.puntosReconstruccionActual,
                      puntosMaximos: jugador.puntosAcumulados,
                      onConfirmar: (puntos) {
                        setState(() {
                          aldeano.puntosReconstruccionActual += puntos;
                          jugador.puntosAcumulados -= puntos;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ +$puntos 🔨 a reconstrucción'),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),

                _buildBotonAccion(
                  icon: '❤️',
                  texto: 'CURAR',
                  color: Colors.green,
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarModalPuntos(
                      titulo: '❤️ CURAR ALDEANO',
                      icono: '❤️',
                      valorActual: aldeano.vidaActual,
                      puntosMaximos: jugador.puntosAcumulados,
                      onConfirmar: (puntos) {
                        setState(() {
                          aldeano.vidaActual += puntos;
                          jugador.puntosAcumulados -= puntos;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ +$puntos ❤️ al aldeano'),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 8),
                _buildBotonAccion(
                  icon: '🚶',
                  texto: 'MOVER',
                  color: Colors.blue,
                  onPressed:
                      _hayCasillasVacias(jugador)
                          ? () {
                            Navigator.pop(context);
                            _modoMover = true;
                            _aldeanoParaMover = casillaAldeano;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '👆 Selecciona una casilla vacía para mover',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                          : null,
                ),

                const SizedBox(height: 8),

                _buildBotonAccion(
                  icon: '❌',
                  texto: 'CANCELAR',
                  color: Colors.grey,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _moverAldeano(
    CasillaAldeano casillaAldeano,
    int nuevaFila,
    int nuevaColumna,
  ) {
    final jugador = juego.jugadorActual;
    final aldeano = casillaAldeano.aldeano;
    final coordenadaOrigen = aldeano.coordenada;
    final coordenadaDestino = jugador.tablero.obtenerCoordenadas(
      nuevaFila,
      nuevaColumna,
    );

    setState(() {
      // Crear nueva casilla en el destino
      final nuevaCasilla = CasillaAldeano(
        coordenada: coordenadaDestino,
        aldeano: aldeano,
      );

      // Actualizar coordenada del aldeano
      aldeano.coordenada = coordenadaDestino;

      // Colocar en destino
      jugador.colocarEnTablero(nuevaFila, nuevaColumna, nuevaCasilla);

      // Dejar vacía la casilla original
      jugador.tablero.eliminarCasilla(
        Tablero.coordenadaToIndices(coordenadaOrigen)![0],
        Tablero.coordenadaToIndices(coordenadaOrigen)![1],
      );
    });

    _limpiarModoMover();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ ${aldeano.aldeanoBase.nombre} movido a $coordenadaDestino',
        ),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  void _moverGuerrero(
    CasillaGuerrero casillaGuerrero,
    int nuevaFila,
    int nuevaColumna,
  ) {
    final jugador = juego.jugadorActual;
    final guerrero = casillaGuerrero.guerrero;
    final coordenadaOrigen = guerrero.coordenada;
    final coordenadaDestino = jugador.tablero.obtenerCoordenadas(
      nuevaFila,
      nuevaColumna,
    );

    setState(() {
      // Crear nueva casilla en el destino
      final nuevaCasilla = CasillaGuerrero(
        coordenada: coordenadaDestino,
        guerrero: guerrero,
      );

      // Actualizar coordenada del guerrero
      guerrero.coordenada = coordenadaDestino;

      // Colocar en destino
      jugador.colocarEnTablero(nuevaFila, nuevaColumna, nuevaCasilla);

      // Dejar vacía la casilla original
      jugador.tablero.eliminarCasilla(
        Tablero.coordenadaToIndices(coordenadaOrigen)![0],
        Tablero.coordenadaToIndices(coordenadaOrigen)![1],
      );
    });

    _limpiarModoMoverGuerrero();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ ${guerrero.guerreroBase.nombreId} movido a $coordenadaDestino',
        ),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  void _limpiarModoMover() {
    setState(() {
      _modoMover = false;
      _aldeanoParaMover = null;
    });
  }

  void _limpiarModoMoverGuerrero() {
    setState(() {
      _modoMoverGuerrero = false;
      _guerreroParaMover = null;
    });
  }

  Widget _buildStat(String icon, int valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.brown[700]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$valor',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required String icon,
    required String texto,
    required Color color,
    VoidCallback? onPressed, // 👈 AHORA PUEDE SER NULL
  }) {
    // Si no hay función, no mostramos el botón
    if (onPressed == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionMejora({
    required String icon,
    required String titulo,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalPuntos({
    required String titulo,
    required String icono,
    required int valorActual,
    required int puntosMaximos,
    required Function(int puntos) onConfirmar,
  }) {
    double _valorSlider = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.brown[800],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$icono $titulo',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Valor actual: $valorActual',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '⚡ $puntosMaximos disponibles',
                      style: const TextStyle(color: Colors.amber),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _valorSlider,
                      min: 1,
                      max: puntosMaximos.toDouble(),
                      divisions: puntosMaximos,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setStateDialog(() {
                          _valorSlider = value;
                        });
                      },
                    ),
                    Text(
                      '${_valorSlider.toInt()} ⚡',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCELAR'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onConfirmar(_valorSlider.toInt());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('MEJORAR'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilaInvocacion({
    required List<InvocableItem> items,
    required int puntos,
    required Function(InvocableItem) onSeleccionar,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            items.map((item) {
              final puedePagar = puntos >= item.costo;
              return Padding(
                padding: const EdgeInsets.all(4),
                child: GestureDetector(
                  onTap: puedePagar ? () => onSeleccionar(item) : null,
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: puedePagar ? Colors.grey[700] : Colors.grey[700],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: Column(
                      children: [
                        // Imagen
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey[500],
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(item.imagenPath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Nombre
                        Text(
                          item.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // ============================================
                        // STATS SEGÚN EL TIPO
                        // ============================================
                        if (item.tipo == 'guerrero') ...[
                          // Stats de guerrero (ataque y vida)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                '⚔️${(item.datos as Guerrero).ataque}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '❤️${(item.datos as Guerrero).vida}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ] else if (item.tipo == 'torre') ...[
                          // Stats de torre (ataque y vida)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                '🏹 ${(item.datos as Torre).ataque}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '🏰 ${(item.datos as Torre).vida}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ] else if (item.tipo == 'hospital') ...[
                          // Stats de hospital (poder curación y vida)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                '💊 ${(item.datos as Hospital).poderCuracion}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '🏥 ${(item.datos as Hospital).vida}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ] else if (item.tipo == 'cultivo') ...[
                          // Stats de cultivo (puntos por turno y vida)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                '🌾 ${(item.datos as Cultivo).puntosPorTurno}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '🌱 ${(item.datos as Cultivo).vida}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ] else if (item.tipo == 'aldeano') ...[
                          // Stats de aldeano (reconstrucción y vida)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                '🔨 ${(item.datos as Aldeano).puntosReconstruccion}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '👨${(item.datos as Aldeano).vida}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 2),

                        // Costo (siempre igual)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⚡ ${item.costo}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  void _mostrarModalReconstruir(CasillaMonumento monumento) {
    final jugador = juego.jugadorActual;

    if (jugador.puntosAcumulados <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No tienes puntos para reconstruir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double _valorSlider = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.brown[800]!, Colors.brown[900]!],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.amber, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance,
                          color: Colors.amber,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'RECONSTRUIR',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Monumento
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.brown[300],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber, width: 2),
                        image: DecorationImage(
                          image: AssetImage(monumento.imagenPath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      monumento.nombre,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Vida actual
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[900]?.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${monumento.vidaActual}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Puntos disponibles
                    Text(
                      '⚡ ${jugador.puntosAcumulados} disponibles',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Slider
                    Slider(
                      value: _valorSlider,
                      min: 1,
                      max: jugador.puntosAcumulados.toDouble(),
                      divisions: jugador.puntosAcumulados,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setStateDialog(() {
                          _valorSlider = value;
                        });
                      },
                    ),

                    Text(
                      '${_valorSlider.toInt()} ⚡',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                          ),
                          child: const Text('CANCELAR'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              monumento.vidaActual += _valorSlider.toInt();
                              jugador.puntosAcumulados -= _valorSlider.toInt();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ +${_valorSlider.toInt()} ❤️ a ${monumento.nombre}',
                                ),
                                backgroundColor: Colors.green[700],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('RECONSTRUIR'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _invocar(InvocableItem item, Jugador2 jugador) {
    Navigator.pop(context); // Cierra el modal

    // Guardamos el item pendiente
    setState(() {
      _itemPendiente = item;
    });

    // Ya tenemos la coordenada guardada de cuando se abrió el modal
    if (_filaSeleccionada != null && _columnaSeleccionada != null) {
      _confirmarInvocacionEnCasilla(
        _filaSeleccionada!,
        _columnaSeleccionada!,
        _coordenadaSeleccionada!,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: no hay casilla seleccionada'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmarInvocacionEnCasilla(int fila, int columna, String coordenada) {
    final jugador = juego.jugadorActual;
    final item = _itemPendiente!;

    // ============================================
    // VERIFICAR QUE LA CASILLA SIGA VACÍA
    // ============================================
    if (!jugador.tablero.estaVacia(fila, columna)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ La casilla ya no está vacía'),
          backgroundColor: Colors.red,
        ),
      );
      _limpiarSeleccion();
      return;
    }

    // ============================================
    // CREAR LA INSTANCIA SEGÚN EL TIPO
    // ============================================
    Casilla nuevaCasilla;

    switch (item.tipo) {
      case 'guerrero':
        final guerreroBase = item.datos as Guerrero;
        final guerreroCampo = GuerreroCampo.desdeGuerrero(
          guerrero: guerreroBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaGuerrero(
          coordenada: coordenada,
          guerrero: guerreroCampo,
        );
        break;

      case 'torre':
        final torreBase = item.datos as Torre;
        final torreCampo = TorreCampo.desdeTorre(
          torre: torreBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaTorre(coordenada: coordenada, torre: torreCampo);
        break;

      case 'hospital':
        final hospitalBase = item.datos as Hospital;
        final hospitalCampo = HospitalCampo.desdeHospital(
          hospital: hospitalBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaHospital(
          coordenada: coordenada,
          hospital: hospitalCampo,
        );
        break;

      case 'cultivo':
        final cultivoBase = item.datos as Cultivo;
        final cultivoCampo = CultivoCampo.desdeCultivo(
          cultivo: cultivoBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaCultivo(
          coordenada: coordenada,
          cultivo: cultivoCampo,
        );
        break;

      case 'aldeano':
        final aldeanoBase = item.datos as Aldeano;
        final aldeanoCampo = AldeanoCampo.desdeAldeano(
          aldeano: aldeanoBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaAldeano(
          coordenada: coordenada,
          aldeano: aldeanoCampo,
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Tipo ${item.tipo} no implementado'),
            backgroundColor: Colors.red,
          ),
        );
        _limpiarSeleccion();
        return;
    }

    // ============================================
    // COLOCAR EN EL TABLERO Y ACTUALIZAR
    // ============================================
    setState(() {
      jugador.colocarEnTablero(fila, columna, nuevaCasilla);
      jugador.puntosAcumulados -= item.costo;
      _limpiarSeleccion();
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('✅ ${item.nombre} invocado en $coordenada'),
    //     backgroundColor: Colors.green[700],
    //   ),
    // );
  }

  void _limpiarSeleccion() {
    _filaSeleccionada = null;
    _columnaSeleccionada = null;
    _coordenadaSeleccionada = null;
    _itemPendiente = null;
  }

  bool _hayCasillasVacias(Jugador2 jugador) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        if (jugador.tablero.estaVacia(i, j)) {
          return true;
        }
      }
    }
    return false;
  }

  void _iniciarTurno() {
    _lanzarDados(() {
      _cosecharCultivos(() {
        _curarConHospitales(() {
          _repararConAldeanos(() {
            _atacarConTorres(() {
              // 👈 NUEVO
              print('🎮 Turno listo para jugar');
            });
          });
        });
      });
    });
  }

  void _lanzarDados(VoidCallback onComplete) {
    // Evitar lanzar si ya se lanzaron este turno
    if (_dadosLanzadosEsteTurno) return;
    _dadosLanzadosEsteTurno = true;

    // Guardar el turno actual
    final int turnoActual = juego.turnoActual;

    int dadoIzq = Random().nextInt(6) + 1;
    int dadoDer = Random().nextInt(6) + 1;
    int suma = dadoIzq + dadoDer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.brown[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🎲 TIRANDO DADOS...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/dados/${dadoIzq}x${dadoDer}.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.brown[600],
                      child: Center(
                        child: Text(
                          '${dadoIzq}x${dadoDer}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        Navigator.of(context).pop();

        setState(() {
          final jugadorQueTiro = juego.jugadores[turnoActual];
          jugadorQueTiro.puntosAcumulados += suma;
        });
        // 👈 LLAMAR AL CALLBACK DESPUÉS DE SUMAR PUNTOS
        onComplete();
      }
    });
    //
  }

  void _lanzarDadosIA(VoidCallback onComplete) {
    // Evitar lanzar si ya se lanzaron este turno
    if (_dadosLanzadosEsteTurno) return;
    _dadosLanzadosEsteTurno = true;

    // Guardar el turno actual
    final int turnoActual = juego.turnoActual;

    int dadoIzq = Random().nextInt(6) + 1;
    int dadoDer = Random().nextInt(6) + 1;
    int suma = dadoIzq + dadoDer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.brown[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🤖 IA TIRANDO DADOS...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/dados/${dadoIzq}x${dadoDer}.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.brown[600],
                      child: Center(
                        child: Text(
                          '${dadoIzq}x${dadoDer}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        Navigator.of(context).pop();

        setState(() {
          final jugadorIA = juego.jugadores[turnoActual];
          jugadorIA.puntosAcumulados += suma;
        });

        // 👈 LLAMAR AL CALLBACK DESPUÉS DE SUMAR PUNTOS
        onComplete();
      }
    });
  }

  void _cosecharCultivos(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final List<CasillaCultivo> cultivos = [];

    // Buscar cultivos
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.cultivo) {
          cultivos.add(casilla as CasillaCultivo);
        }
      }
    }

    if (cultivos.isEmpty) {
      print("sin cultivos");
      onComplete(); // 👈 Si no hay cultivos, seguir inmediatamente
      return;
    }

    // Calcular puntos y preparar detalles
    int puntosTotales = 0;
    final List<Map<String, dynamic>> detalles = [];

    for (var cultivo in cultivos) {
      final puntos = cultivo.cultivo.puntosPorTurnoActual;
      puntosTotales += puntos;
      detalles.add({
        'nombre': cultivo.cultivo.cultivoBase.nombre,
        'imagen': cultivo.cultivo.cultivoBase.imagen,
        'puntos': puntos,
      });
    }

    setState(() {
      jugador.puntosAcumulados += puntosTotales;
    });

    // Mostrar modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            onComplete(); // 👈 LLAMAR AL CALLBACK DESPUÉS DE CERRAR
          }
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green[900]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🌾', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 8),
                    Text(
                      'COSECHA',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lista de cultivos
                ...detalles.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.brown[800]?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Imagen
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.brown[600],
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage(item['imagen']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nombre
                          Expanded(
                            child: Text(
                              item['nombre'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Puntos
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${item['puntos']} ⚡',
                              style: const TextStyle(
                                color: Colors.brown,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const Divider(color: Colors.white24, height: 20),

                // Total
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[800]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '+$puntosTotales ⚡',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Botón cerrar
                // ElevatedButton(
                //   onPressed: () => Navigator.pop(context),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.amber,
                //     foregroundColor: Colors.brown,
                //   ),
                //   child: const Text('CONTINUAR'),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _curarConHospitales(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final List<CasillaHospital> hospitales = [];

    // ============================================
    // 1. BUSCAR TODOS LOS HOSPITALES
    // ============================================
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.hospital) {
          hospitales.add(casilla as CasillaHospital);
        }
      }
    }

    if (hospitales.isEmpty) {
      print("sin hospitales");
      onComplete(); // 👈 Si no hay hospitales, seguir
      return;
    }

    // ============================================
    // 2. PROCESAR CADA HOSPITAL CON SU MODAL
    // ============================================
    _procesarSiguienteHospital(hospitales, 0, onComplete);
  }

  void _procesarSiguienteHospital(
    List<CasillaHospital> hospitales,
    int index,
    VoidCallback onComplete,
  ) {
    if (index >= hospitales.length) {
      onComplete();
      return;
    }

    final hospital = hospitales[index];
    final jugador = juego.jugadorActual;
    final coordenadas = _getCoordenadasDeCasilla(jugador, hospital);
    final fila = coordenadas['fila']!;
    final columna = coordenadas['columna']!;
    final poderCuracion = hospital.hospital.poderCuracionActual;

    // Buscar unidades para curar
    final List<Map<String, dynamic>> unidadesCuradas = [];

    // Recorrer toda la fila
    for (int c = 0; c < 5; c++) {
      final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, c);
      if (casilla.tipo == TipoCasilla.guerrero) {
        final guerrero = (casilla as CasillaGuerrero).guerrero;
        unidadesCuradas.add({
          'tipo': 'guerrero',
          'nombre': guerrero.guerreroBase.nombreId,
          'imagen': guerrero.guerreroBase.imagen,
          'vidaActual': guerrero.vidaActual,
          'curacion': poderCuracion,
          'objeto': guerrero,
        });
      } else if (casilla.tipo == TipoCasilla.aldeano) {
        final aldeano = (casilla as CasillaAldeano).aldeano;
        unidadesCuradas.add({
          'tipo': 'aldeano',
          'nombre': aldeano.aldeanoBase.nombre,
          'imagen': aldeano.aldeanoBase.imagen,
          'vidaActual': aldeano.vidaActual,
          'curacion': poderCuracion,
          'objeto': aldeano,
        });
      }
    }

    // Recorrer toda la columna
    for (int f = 0; f < 4; f++) {
      if (f == fila) continue;
      final casilla = jugador.tablero.obtenerCasillaPorIndices(f, columna);
      if (casilla.tipo == TipoCasilla.guerrero) {
        final guerrero = (casilla as CasillaGuerrero).guerrero;
        unidadesCuradas.add({
          'tipo': 'guerrero',
          'nombre': guerrero.guerreroBase.nombreId,
          'imagen': guerrero.guerreroBase.imagen,
          'vidaActual': guerrero.vidaActual,
          'curacion': poderCuracion,
          'objeto': guerrero,
        });
      } else if (casilla.tipo == TipoCasilla.aldeano) {
        final aldeano = (casilla as CasillaAldeano).aldeano;
        unidadesCuradas.add({
          'tipo': 'aldeano',
          'nombre': aldeano.aldeanoBase.nombre,
          'imagen': aldeano.aldeanoBase.imagen,
          'vidaActual': aldeano.vidaActual,
          'curacion': poderCuracion,
          'objeto': aldeano,
        });
      }
    }

    // Aplicar curación
    setState(() {
      for (var unidad in unidadesCuradas) {
        final curacion = unidad['curacion'] as int;
        if (unidad['tipo'] == 'guerrero') {
          (unidad['objeto'] as GuerreroCampo).vidaActual += curacion;
        } else {
          (unidad['objeto'] as AldeanoCampo).vidaActual += curacion;
        }
      }
    });

    // 👈 SI HAY UNIDADES, MOSTRAR MODAL; SI NO, PASAR AL SIGUIENTE
    if (unidadesCuradas.isEmpty) {
      _procesarSiguienteHospital(hospitales, index + 1, onComplete);
    } else {
      _mostrarModalCuracionHospital(
        hospital: hospital,
        unidades: unidadesCuradas,
        onClose: () {
          _procesarSiguienteHospital(hospitales, index + 1, onComplete);
        },
      );
    }
  }

  // ============================================
  // FUNCIÓN AUXILIAR: OBTENER COORDENADAS DE UNA CASILLA
  // ============================================
  Map<String, int> _getCoordenadasDeCasilla(Jugador2 jugador, Casilla casilla) {
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (jugador.tablero.obtenerCasillaPorIndices(fila, col) == casilla) {
          return {'fila': fila, 'columna': col};
        }
      }
    }
    return {'fila': -1, 'columna': -1};
  }

  // ============================================
  // MODAL DE CURACIÓN DEL HOSPITAL
  // ============================================
  void _mostrarModalCuracionHospital({
    required CasillaHospital hospital,
    required List<Map<String, dynamic>> unidades,
    required VoidCallback onClose,
  }) {
    if (unidades.isEmpty) {
      onClose();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            onClose(); // 👈 LLAMAR AL CALLBACK DESPUÉS DE CERRAR
          }
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal[900]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título con hospital
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.brown[600],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(
                            hospital.hospital.hospitalBase.imagen,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hospital.hospital.hospitalBase.nombre,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Subtítulo
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    '💊 HA CURADO:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Lista de unidades curadas
                ...unidades.map((unidad) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.brown[800]?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Imagen
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.brown[600],
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage(unidad['imagen']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nombre
                          Expanded(
                            child: Text(
                              unidad['nombre'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Curación
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${unidad['curacion']} ❤️',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Botón continuar
                // ElevatedButton(
                //   onPressed: () {
                //     Navigator.pop(context);
                //     onClose();
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.amber,
                //     foregroundColor: Colors.brown,
                //   ),
                //   child: const Text('CONTINUAR'),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _repararConAldeanos(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final List<CasillaAldeano> aldeanos = [];

    // ============================================
    // 1. BUSCAR TODOS LOS ALDEANOS
    // ============================================
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.aldeano) {
          aldeanos.add(casilla as CasillaAldeano);
        }
      }
    }

    if (aldeanos.isEmpty) {
      print("sin cultivos");
      onComplete();
      return;
    }

    // ============================================
    // 2. PROCESAR CADA ALDEANO CON SU MODAL
    // ============================================
    _procesarSiguienteAldeano(aldeanos, 0, onComplete);
  }

  void _procesarSiguienteAldeano(
    List<CasillaAldeano> aldeanos,
    int index,
    VoidCallback onComplete,
  ) {
    if (index >= aldeanos.length) {
      onComplete(); // 👈 TERMINAR CUANDO SE ACABAN LOS ALDEANOS
      return;
    }

    final aldeano = aldeanos[index];
    final jugador = juego.jugadorActual;
    final coordenadas = _getCoordenadasDeCasilla(jugador, aldeano);
    final fila = coordenadas['fila']!;
    final columna = coordenadas['columna']!;
    final poderReparacion = aldeano.aldeano.puntosReconstruccionActual;

    // Buscar edificios para reparar
    final List<Map<String, dynamic>> edificiosReparados = [];
    final tiposEdificios = [
      TipoCasilla.monumento,
      TipoCasilla.torre,
      TipoCasilla.hospital,
      TipoCasilla.cultivo,
    ];

    // Recorrer toda la fila
    for (int c = 0; c < 5; c++) {
      final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, c);
      if (tiposEdificios.contains(casilla.tipo)) {
        _agregarEdificioAReparar(casilla, poderReparacion, edificiosReparados);
      }
    }

    // Recorrer toda la columna
    for (int f = 0; f < 4; f++) {
      if (f == fila) continue;
      final casilla = jugador.tablero.obtenerCasillaPorIndices(f, columna);
      if (tiposEdificios.contains(casilla.tipo)) {
        _agregarEdificioAReparar(casilla, poderReparacion, edificiosReparados);
      }
    }

    // Aplicar reparación (si hay)
    setState(() {
      for (var edificio in edificiosReparados) {
        final reparacion = edificio['reparacion'] as int;
        switch (edificio['tipo']) {
          case 'monumento':
            (edificio['objeto'] as CasillaMonumento).vidaActual += reparacion;
            break;
          case 'torre':
            (edificio['objeto'] as CasillaTorre).torre.vidaActual += reparacion;
            break;
          case 'hospital':
            (edificio['objeto'] as CasillaHospital).hospital.vidaActual +=
                reparacion;
            break;
          case 'cultivo':
            (edificio['objeto'] as CasillaCultivo).cultivo.vidaActual +=
                reparacion;
            break;
        }
      }
    });

    // ============================================
    // SI HAY EDIFICIOS, MOSTRAR MODAL
    // SI NO, PASAR AL SIGUIENTE DIRECTAMENTE
    // ============================================
    if (edificiosReparados.isEmpty) {
      // 👈 SIN EDIFICIOS: Pasar al siguiente aldeano
      _procesarSiguienteAldeano(aldeanos, index + 1, onComplete);
    } else {
      // 👈 CON EDIFICIOS: Mostrar modal
      _mostrarModalReparacionAldeano(
        aldeano: aldeano,
        edificios: edificiosReparados,
        onClose: () {
          _procesarSiguienteAldeano(aldeanos, index + 1, onComplete);
        },
      );
    }
  }

  void _agregarEdificioAReparar(
    Casilla casilla,
    int poderReparacion,
    List<Map<String, dynamic>> lista,
  ) {
    // Evitar duplicados (mismo edificio en fila y columna)
    for (var existente in lista) {
      if (existente['objeto'] == casilla) return;
    }

    switch (casilla.tipo) {
      case TipoCasilla.monumento:
        final monumento = casilla as CasillaMonumento;
        lista.add({
          'tipo': 'monumento',
          'nombre': monumento.nombre,
          'imagen': monumento.imagenPath,
          'vidaActual': monumento.vidaActual,
          'reparacion': poderReparacion,
          'objeto': monumento,
        });
        break;
      case TipoCasilla.torre:
        final torre = casilla as CasillaTorre;
        lista.add({
          'tipo': 'torre',
          'nombre': torre.torre.torreBase.nombre,
          'imagen': torre.torre.torreBase.imagen,
          'vidaActual': torre.torre.vidaActual,
          'reparacion': poderReparacion,
          'objeto': torre,
        });
        break;
      case TipoCasilla.hospital:
        final hospital = casilla as CasillaHospital;
        lista.add({
          'tipo': 'hospital',
          'nombre': hospital.hospital.hospitalBase.nombre,
          'imagen': hospital.hospital.hospitalBase.imagen,
          'vidaActual': hospital.hospital.vidaActual,
          'reparacion': poderReparacion,
          'objeto': hospital,
        });
        break;
      case TipoCasilla.cultivo:
        final cultivo = casilla as CasillaCultivo;
        lista.add({
          'tipo': 'cultivo',
          'nombre': cultivo.cultivo.cultivoBase.nombre,
          'imagen': cultivo.cultivo.cultivoBase.imagen,
          'vidaActual': cultivo.cultivo.vidaActual,
          'reparacion': poderReparacion,
          'objeto': cultivo,
        });
        break;
      default:
        break;
    }
  }

  void _mostrarModalReparacionAldeano({
    required CasillaAldeano aldeano,
    required List<Map<String, dynamic>> edificios,
    required VoidCallback onClose,
  }) {
    if (edificios.isEmpty) {
      onClose();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            onClose(); // 👈 LLAMAR AL CALLBACK DESPUÉS DE CERRAR
          }
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange[900]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título con aldeano
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.brown[600],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(aldeano.aldeano.aldeanoBase.imagen),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      aldeano.aldeano.aldeanoBase.nombre,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Subtítulo
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    '🔨 HA REPARADO:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Lista de edificios reparados
                ...edificios.map((edificio) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.brown[800]?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Imagen
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.brown[600],
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage(edificio['imagen']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nombre
                          Expanded(
                            child: Text(
                              edificio['nombre'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Reparación
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${edificio['reparacion']} 🏗️',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Botón continuar
                // ElevatedButton(
                //   onPressed: () {
                //     Navigator.pop(context);
                //     onClose();
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.amber,
                //     foregroundColor: Colors.brown,
                //   ),
                //   child: const Text('CONTINUAR'),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _atacarConTorres(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final oponente = juego.oponente;
    final List<CasillaTorre> torres = [];

    // ============================================
    // 1. BUSCAR TODAS LAS TORRES DEL JUGADOR
    // ============================================
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.torre) {
          torres.add(casilla as CasillaTorre);
        }
      }
    }

    if (torres.isEmpty) {
      onComplete();
      return;
    }

    // ============================================
    // 2. PROCESAR CADA TORRE
    // ============================================
    _procesarSiguienteTorre(torres, 0, onComplete);
  }

  void _procesarSiguienteTorre(
    List<CasillaTorre> torres,
    int index,
    VoidCallback onComplete,
  ) {
    if (index >= torres.length) {
      onComplete();
      return;
    }

    final torre = torres[index];
    final jugador = juego.jugadorActual;
    final oponente = juego.oponente;
    final coordenadas = _getCoordenadasDeCasilla(jugador, torre);
    final columna = coordenadas['columna']!;

    // ============================================
    // BUSCAR OBJETIVO EN LA MISMA COLUMNA DEL ENEMIGO
    // ============================================
    dynamic objetivo;
    int filaObjetivo = -1;
    String tipoObjetivo = '';
    int vidaAntes = 0;

    // Buscar desde la fila más lejana (3) hasta la más cercana (0)
    for (int fila = 3; fila >= 0; fila--) {
      final casilla = oponente.tablero.obtenerCasillaPorIndices(fila, columna);

      if (casilla.tipo != TipoCasilla.vacia) {
        objetivo = casilla;
        filaObjetivo = fila;
        vidaAntes = _getVidaObjetivo(objetivo);
        tipoObjetivo = _getTipoObjetivo(objetivo);
        break;
      }
    }

    // ============================================
    // SI NO HAY OBJETIVO, VERIFICAR SI PUEDE ATACAR MONUMENTO
    // ============================================
    if (objetivo == null) {
      // Si el campo enemigo está vacío, atacar monumento
      if (_puedeAtacarMonumento()) {
        final monumento =
            oponente.tablero.obtenerCasillaPorIndices(3, 2) as CasillaMonumento;
        objetivo = monumento;
        filaObjetivo = 3;
        vidaAntes = monumento.vidaActual;
        tipoObjetivo = 'monumento';
      } else {
        // No hay objetivo y campo no vacío, pasar a siguiente torre
        _procesarSiguienteTorre(torres, index + 1, onComplete);
        return;
      }
    }

    // ============================================
    // SI EL OBJETIVO ES MONUMENTO, VERIFICAR QUE SE PUEDA ATACAR
    // ============================================
    if (tipoObjetivo == 'monumento' && !_puedeAtacarMonumento()) {
      // No se puede atacar monumento porque hay unidades enemigas
      _procesarSiguienteTorre(torres, index + 1, onComplete);
      return;
    }

    // ============================================
    // APLICAR DAÑO Y MOSTRAR MODAL (igual que antes)
    // ============================================
    final dano = torre.torre.ataqueActual;
    setState(() {
      _aplicarDano(objetivo, dano);
    });

    final bool murio = _getVidaObjetivo(objetivo) <= 0;

    if (murio && objetivo is! CasillaMonumento) {
      setState(() {
        oponente.tablero.eliminarCasilla(filaObjetivo, columna);
      });
    }

    _mostrarModalAtaqueTorre(
      torre: torre,
      objetivo: objetivo,
      tipoObjetivo: tipoObjetivo,
      dano: dano,
      vidaAntes: vidaAntes,
      murio: murio,
      onClose: () {
        _procesarSiguienteTorre(torres, index + 1, onComplete);
      },
    );
  }

  String _getImagenObjetivo(dynamic objetivo) {
    switch (objetivo.tipo) {
      case TipoCasilla.monumento:
        return (objetivo as CasillaMonumento).imagenPath;
      case TipoCasilla.guerrero:
        return (objetivo as CasillaGuerrero).guerrero.guerreroBase.imagen;
      case TipoCasilla.torre:
        return (objetivo as CasillaTorre).torre.torreBase.imagen;
      case TipoCasilla.hospital:
        return (objetivo as CasillaHospital).hospital.hospitalBase.imagen;
      case TipoCasilla.cultivo:
        return (objetivo as CasillaCultivo).cultivo.cultivoBase.imagen;
      case TipoCasilla.aldeano:
        return (objetivo as CasillaAldeano).aldeano.aldeanoBase.imagen;
      default:
        return '';
    }
  }

  String _getNombreObjetivo(dynamic objetivo) {
    switch (objetivo.tipo) {
      case TipoCasilla.monumento:
        return (objetivo as CasillaMonumento).nombre;
      case TipoCasilla.guerrero:
        return (objetivo as CasillaGuerrero).guerrero.guerreroBase.nombreId;
      case TipoCasilla.torre:
        return (objetivo as CasillaTorre).torre.torreBase.nombre;
      case TipoCasilla.hospital:
        return (objetivo as CasillaHospital).hospital.hospitalBase.nombre;
      case TipoCasilla.cultivo:
        return (objetivo as CasillaCultivo).cultivo.cultivoBase.nombre;
      case TipoCasilla.aldeano:
        return (objetivo as CasillaAldeano).aldeano.aldeanoBase.nombre;
      default:
        return 'Desconocido';
    }
  }

  int _getVidaObjetivo(dynamic objetivo) {
    switch (objetivo.tipo) {
      case TipoCasilla.monumento:
        return (objetivo as CasillaMonumento).vidaActual;
      case TipoCasilla.guerrero:
        return (objetivo as CasillaGuerrero).guerrero.vidaActual;
      case TipoCasilla.torre:
        return (objetivo as CasillaTorre).torre.vidaActual;
      case TipoCasilla.hospital:
        return (objetivo as CasillaHospital).hospital.vidaActual;
      case TipoCasilla.cultivo:
        return (objetivo as CasillaCultivo).cultivo.vidaActual;
      case TipoCasilla.aldeano:
        return (objetivo as CasillaAldeano).aldeano.vidaActual;
      default:
        return 0;
    }
  }

  String _getTipoObjetivo(dynamic objetivo) {
    switch (objetivo.tipo) {
      case TipoCasilla.monumento:
        return 'monumento';
      case TipoCasilla.guerrero:
        return 'guerrero';
      case TipoCasilla.torre:
        return 'torre';
      case TipoCasilla.hospital:
        return 'hospital';
      case TipoCasilla.cultivo:
        return 'cultivo';
      case TipoCasilla.aldeano:
        return 'aldeano';
      default:
        return 'desconocido';
    }
  }

  void _aplicarDano(dynamic objetivo, int dano) {
    switch (objetivo.tipo) {
      case TipoCasilla.monumento:
        (objetivo as CasillaMonumento).vidaActual -= dano;
        break;
      case TipoCasilla.guerrero:
        (objetivo as CasillaGuerrero).guerrero.vidaActual -= dano;
        break;
      case TipoCasilla.torre:
        (objetivo as CasillaTorre).torre.vidaActual -= dano;
        break;
      case TipoCasilla.hospital:
        (objetivo as CasillaHospital).hospital.vidaActual -= dano;
        break;
      case TipoCasilla.cultivo:
        (objetivo as CasillaCultivo).cultivo.vidaActual -= dano;
        break;
      case TipoCasilla.aldeano:
        (objetivo as CasillaAldeano).aldeano.vidaActual -= dano;
        break;
    }
  }

  bool _puedeAtacarMonumento() {
    final oponente = juego.oponente;

    // Recorrer todo el tablero enemigo
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(fila, col);
        // Si hay ALGO que no sea vacío, no se puede atacar el monumento
        if (casilla.tipo != TipoCasilla.vacia &&
            casilla.tipo != TipoCasilla.monumento) {
          return false;
        }
      }
    }
    return true;
  }

  void _mostrarModalAtaqueTorre({
    required CasillaTorre torre,
    required dynamic objetivo,
    required String tipoObjetivo,
    required int dano,
    required int vidaAntes,
    required bool murio,
    required VoidCallback onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            onClose();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange[900]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🗼', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 8),
                    Text(
                      'ATAQUE DE TORRE',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Atacante
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.brown[600],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(torre.torre.torreBase.imagen),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            torre.torre.torreBase.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '🗡️ ${torre.torre.ataqueActual}',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Flecha
                const Icon(Icons.arrow_forward, color: Colors.amber, size: 30),

                const SizedBox(height: 16),

                // Defensor
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.brown[600],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(_getImagenObjetivo(objetivo)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNombreObjetivo(objetivo),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '❤️ $vidaAntes → ❤️ ${_getVidaObjetivo(objetivo)}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Daño
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[900]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-$dano ❤️',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (murio)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '💀 OBJETIVO DESTRUIDO 💀',
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                const Text(
                  '⏳ Cerrando en 3 segundos...',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cambiarTurno() {
    if (_juegoTerminado) return;

    setState(() {
      // Cambiar turno
      juego.turnoActual = juego.turnoActual == 0 ? 1 : 0;

      // Limpiar modos de selección
      _modoMover = false;
      _modoMoverGuerrero = false;
      _aldeanoParaMover = null;
      _guerreroParaMover = null;

      // Resetear bandera de dados
      _dadosLanzadosEsteTurno = false;

      // TODO: Resetear estados de ataque de unidades cuando implementemos combate
    });
    _mostrarCambioTurno();
  }

  void _mostrarCambioTurno() {
    final jugadorSiguiente = juego.jugadores[juego.turnoActual == 0 ? 0 : 1];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 350,
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown[700]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.swap_horiz, color: Colors.amber, size: 60),
                const SizedBox(height: 16),
                Text(
                  'TURNO FINALIZADO',
                  style: TextStyle(
                    color: Colors.amber[200],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '🔄 Cambio de turno',
                  style: TextStyle(
                    color: Colors.amber[400],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Próximo jugador: ${jugadorSiguiente.civilizacion.nombre}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '⚔️ ${jugadorSiguiente.civilizacion.nombre} ⚔️',
                  style: TextStyle(
                    color: Colors.amber[600],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Cerrar el diálogo después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();

        // Después de mostrar el cambio, lanzar los dados si es el humano
        if (juego.turnoActual == 0) {
          // Asumiendo que 0 es el humano
          _iniciarTurno();
        } else {
          _ejecutarIA();
        }
      }
    });
  }

  void _ejecutarIA() {
    // Pequeño delay para que se sienta natural
    Future.delayed(const Duration(seconds: 1), () {
      print('🤖 Turno de la IA - Lanzando dados...');

      // ============================================
      // 1. LA IA TIRA DADOS
      // ============================================
      _lanzarDadosIA(() {
        // 2. Después de dados, cosechar
        _cosecharCultivos(() {
          // 3. Después de cosechar, curar hospitales
          _curarConHospitales(() {
            // 4. Después de hospitales, reparar aldeanos
            _repararConAldeanos(() {
              // 5. Después de reparar, ATACAR CON TORRES
              _atacarConTorres(() {
                // 6. Finalmente, la IA toma decisiones
                print('🤖 IA lista para tomar decisiones');
                _tomarDecisionIA();
              });
            });
          });
        });
      });
    });
  }

  void _tomarDecisionIA() {
    final ia = IAFactory.crearIA(
      juego: juego,
      onPasarTurno: _cambiarTurno,
      aldeanos: aldeanos,
      cultivos: cultivos,
      torres: torres,
      hospitales: hospitales,
      onInvocar: _invocarIA, // 👈 NUEVO
    );
    ia.tomarDecision();
  }

  void _invocarIA(int fila, int columna, String tipo, String id) {
    print('🎮 INVOCAR IA: $tipo en ${fila}x$columna con id $id');

    final jugador = juego.jugadorActual;
    final coordenada = jugador.tablero.obtenerCoordenadas(fila, columna);

    // ============================================
    // BUSCAR EL COSTO DEL ÍTEM A INVOCAR
    // ============================================
    int costo = 0;

    switch (tipo) {
      case 'guerrero':
        final guerreroBase = guerreros![id];
        costo = guerreroBase!.costoInvocacion;
        break;
      case 'aldeano':
        final aldeanoBase = aldeanos![id];
        if (aldeanoBase == null) {
          print('❌ Error: no se encontró aldeano con id $id');
          return;
        }
        costo = aldeanoBase.costoInvocacion;
        break;
      case 'cultivo':
        final cultivoBase = cultivos![id];
        if (cultivoBase == null) {
          print('❌ Error: no se encontró cultivo con id $id');
          return;
        }
        costo = cultivoBase.costoInvocacion;
        break;
      case 'torre':
        final torreBase = torres![id];
        if (torreBase == null) {
          print('❌ Error: no se encontró torre con id $id');
          return;
        }
        costo = torreBase.costoInvocacion;
        break;
      case 'hospital':
        final hospitalBase = hospitales![id];
        if (hospitalBase == null) {
          print('❌ Error: no se encontró hospital con id $id');
          return;
        }
        costo = hospitalBase.costoInvocacion;
        break;
    }

    // ============================================
    // VERIFICAR QUE TENGA PUNTOS SUFICIENTES
    // ============================================
    if (jugador.puntosAcumulados < costo) {
      print(
        '❌ IA no tiene puntos suficientes (${jugador.puntosAcumulados} < $costo)',
      );
      return;
    }

    // ============================================
    // CREAR LA CASILLA SEGÚN EL TIPO
    // ============================================
    Casilla nuevaCasilla;

    switch (tipo) {
      // case 'guerrero':
      //   final guerreroBase = guerreros![id];
      //   final guerreroCampo = GuerreroCampo.desdeGuerrero(
      //     guerrero: guerreroBase,
      //     coordenada: coordenada,
      //   );
      //   nuevaCasilla = CasillaGuerrero(
      //     coordenada: coordenada,
      //     guerrero: guerreroCampo,
      //   );
      //   break;

      case 'aldeano':
        final aldeanoBase = aldeanos![id]!; // 👈 USAMOS ! PORQUE YA VERIFICAMOS
        final aldeanoCampo = AldeanoCampo.desdeAldeano(
          aldeano: aldeanoBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaAldeano(
          coordenada: coordenada,
          aldeano: aldeanoCampo,
        );
        break;

      case 'cultivo':
        final cultivoBase = cultivos![id]!; // 👈 USAMOS !
        final cultivoCampo = CultivoCampo.desdeCultivo(
          cultivo: cultivoBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaCultivo(
          coordenada: coordenada,
          cultivo: cultivoCampo,
        );
        break;

      case 'torre':
        final torreBase = torres![id]!; // 👈 USAMOS !
        final torreCampo = TorreCampo.desdeTorre(
          torre: torreBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaTorre(coordenada: coordenada, torre: torreCampo);
        break;

      case 'hospital':
        final hospitalBase = hospitales![id]!; // 👈 USAMOS !
        final hospitalCampo = HospitalCampo.desdeHospital(
          hospital: hospitalBase,
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaHospital(
          coordenada: coordenada,
          hospital: hospitalCampo,
        );
        break;

      default:
        print('❌ Tipo desconocido: $tipo');
        return;
    }

    // ============================================
    // COLOCAR EN EL TABLERO Y RESTAR PUNTOS
    // ============================================
    setState(() {
      jugador.colocarEnTablero(fila, columna, nuevaCasilla);
      jugador.puntosAcumulados -= costo; // 👈 AQUÍ RESTAMOS LOS PUNTOS
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('🤖 IA invocó ${tipo.toUpperCase()} en $coordenada'),
    //     backgroundColor: Colors.purple,
    //   ),
    // );
  }
}

class InvocableItem {
  final String id;
  final String nombre;
  final String imagenPath;
  final int costo;
  final String tipo;
  final dynamic datos;

  InvocableItem({
    required this.id,
    required this.nombre,
    required this.imagenPath,
    required this.costo,
    required this.tipo,
    required this.datos,
  });
}
