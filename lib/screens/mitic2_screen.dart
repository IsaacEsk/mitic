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
import 'package:mitic/screens/selectCivScreen.dart';
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
  final Civilizacion civilizacionSeleccionada;
  final List<Guerrero> aliadosSeleccionados;

  const Mitic2Screen({
    super.key,
    required this.civilizacionSeleccionada,
    required this.aliadosSeleccionados,
  });

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
  int _contadorTerremoto = 0;
  int _contadorPlaga = 0;
  int _contadorEpidemia = 0;
  @override
  void initState() {
    super.initState();
    //_cargarDatos();
    _inicializarJuego();
  }

  Future<void> _inicializarJuego() async {
    print('🚀 Inicializando juego...');

    // Contadores
    _contadorTerremoto = Random().nextInt(11) + 5;
    _contadorPlaga = Random().nextInt(11) + 5;
    _contadorEpidemia = Random().nextInt(11) + 5;

    // 1. CARGAR DATOS (incluyendo traducciones)
    final datos = await Mitic2DataService.cargarTodo();
    final guerrerosBase = datos['guerreros'] as Map<String, Guerrero>;
    final civilizaciones = datos['civilizaciones'] as Map<String, Civilizacion>;
    final translations = datos['translations'] as Map<String, String>;

    _cargarDatos();

    // 👇 FUNCIÓN PARA TRADUCIR UN GUERRERO
    Guerrero traducirGuerrero(Guerrero original) {
      return Guerrero(
        id: original.id,
        nombreId: translations[original.nombreId] ?? original.nombreId,
        descripcionId:
            translations[original.descripcionId] ?? original.descripcionId,
        civilizacionId: original.civilizacionId,
        ataque: original.ataque,
        vida: original.vida,
        costoInvocacion: original.costoInvocacion,
        imagen: original.imagen,
      );
    }

    // 👇 TRADUCIR LOS GUERREROS DEL JUGADOR 1
    final misGuerrerosTraducidos =
        widget.aliadosSeleccionados.map((g) => traducirGuerrero(g)).toList();

    // 2. JUGADOR 1 (USUARIO) - CON GUERREROS TRADUCIDOS
    final miCivilizacion = widget.civilizacionSeleccionada;
    final jugador1 = Jugador2.inicial(
      civilizacion: miCivilizacion,
      guerrerosSeleccionados: misGuerrerosTraducidos,
      monumentoEnCampo: MonumentField.fromCivilizacion(miCivilizacion),
      puntosAcumulados: 0,
      turno: 0,
      esEnemigo: false,
    );

    print('👤 Jugador 1 - Civilización: ${miCivilizacion.nombre}');
    print(
      '⚔️ Guerreros del jugador 1: ${misGuerrerosTraducidos.map((g) => g.nombreId).join(', ')}',
    );

    final Map<String, List<Guerrero>> guerrerosPorCivilizacion = {};
    for (var g in guerrerosBase.values) {
      // Convertir "azteca_civ" → "azteca"
      String civKey = g.civilizacionId;
      if (civKey.endsWith('_civ')) {
        civKey = civKey.substring(0, civKey.length - 4); // quita "_civ"
      }
      if (!guerrerosPorCivilizacion.containsKey(civKey)) {
        guerrerosPorCivilizacion[civKey] = [];
      }
      guerrerosPorCivilizacion[civKey]!.add(g);
    }

    // 3. JUGADOR 2 (IA) - CIVILIZACIÓN RANDOM
    // 2. OBTENER JUGADOR 2 (IA)
    final otrasCivs =
        civilizaciones.values.where((c) => c.id != miCivilizacion.id).toList();

    final civEnemigo =
        otrasCivs.isNotEmpty
            ? otrasCivs[Random().nextInt(otrasCivs.length)]
            : civilizaciones.values.first;

    // final civEnemigo = civilizaciones['romanos']!;
    // print(
    //   '🤖 ENEMIGO FORZADO: ${civEnemigo.nombre} (para pruebas de IA China)',
    // );

    // 👇 SELECCIONAR ENEMIGO ALEATORIO ENTRE MAYAS, AZTECAS Y CHINOS
    // final List<String> civsConIA = ['maya', 'azteca', 'china'];
    // final civAleatoria = civsConIA[Random().nextInt(civsConIA.length)];
    // final civEnemigo = civilizaciones[civAleatoria]!;

    print('🤖 ENEMIGO ALEATORIO: ${civEnemigo.nombre} (IA disponible)');

    // Obtener guerreros de la civilización enemiga (4 primeros)
    // 3. OBTENER GUERREROS USANDO EL MAPA
    final guerrerosEnemigoBase = guerrerosPorCivilizacion[civEnemigo.id] ?? [];

    print(
      '🤖 Civilización enemiga: ${civEnemigo.nombre} (id: ${civEnemigo.id})',
    );
    print('⚔️ Guerreros encontrados: ${guerrerosEnemigoBase.length}');

    // // 👇 TRADUCIR LOS GUERREROS DEL ENEMIGO
    final todos = guerrerosBase.values.toList();
    final guerrerosEnemigoTraducidos =
        guerrerosEnemigoBase.map((g) => traducirGuerrero(g)).toList();
    final genericos = todos.take(4).toList();
    guerrerosEnemigoTraducidos.addAll(
      genericos.map((g) => traducirGuerrero(g)),
    );

    final jugador2 = Jugador2.inicial(
      civilizacion: civEnemigo,
      guerrerosSeleccionados: guerrerosEnemigoTraducidos,
      monumentoEnCampo: MonumentField.fromCivilizacion(civEnemigo),
      puntosAcumulados: 0,
      turno: 1,
      esEnemigo: true,
    );

    print('🤖 Civilización enemiga: ${civEnemigo.nombre}');
    print(
      '⚔️ Guerreros enemigos: ${guerrerosEnemigoTraducidos.map((g) => g.nombreId).join(', ')}',
    );

    setState(() {
      juego = Juego2(jugadores: [jugador1, jugador2], turnoActual: 0);
      _cargado = true;
    });

    print('✅ Juego inicializado correctamente');
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
        child: IgnorePointer(
          ignoring: juego.turnoActual != 0,
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
                      SizedBox(
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
                        ? Colors.red[900]?.withValues(alpha: 0.2)
                        : Colors.green[900]?.withValues(alpha: 0.2),
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
                    if (juego.turnoActual != 0) return;
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
                    if (juego.turnoActual != 0) return;
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
                resplandor: monumento.resplandor,
                onTap: () {
                  if (esEnemigo) {
                    return;
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
                    return;
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
                    return;
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
                    return;
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
                    return;
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
                    return;
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
                color: Colors.purple.withValues(alpha: 0.3),
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
    final coordenada = casillaGuerrero.coordenada;
    final indices = Tablero.coordenadaToIndices(coordenada);
    final fila = indices![0];
    final columna = indices[1];

    // 👇 VARIABLES PARA LA LÓGICA DEL BOTÓN
    final bool yaAtaco = guerrero.yaAtacoEsteTurno;
    final bool tableroVacio = _tableroEnemigoVacio();
    final bool tieneObjetivo = _tieneObjetivoFrontal(columna);

    // 👇 DECIDIR SI MOSTRAR BOTÓN DE ATAQUE
    final bool puedeAtacar = !yaAtaco && (tableroVacio || tieneObjetivo);

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
                // Botón de ataque (solo si no ha atacado)
                if (puedeAtacar)
                  _buildBotonAccion(
                    icon: '⚔️',
                    texto: 'ATACAR',
                    color: Colors.red,
                    onPressed: () {
                      if (juego.turnoActual != 0) return;
                      Navigator.pop(context);
                      _atacarJugador(guerrero, fila, columna);
                    },
                  ),

                // Espaciado solo si el botón de ataque está presente
                if (!guerrero.yaAtacoEsteTurno) const SizedBox(height: 8),

                //const SizedBox(height: 8),
                _buildBotonAccion(
                  icon: '💪',
                  texto: 'MEJORAR ATAQUE',
                  color: Colors.orange,
                  onPressed: () {
                    if (juego.turnoActual != 0) return;
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
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text('✅ +$puntos ⚔️ a ataque'),
                        //     backgroundColor: Colors.green[700],
                        //   ),
                        // );
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
                    if (juego.turnoActual != 0) return;
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
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text('✅ +$puntos ❤️ a vida'),
                        //     backgroundColor: Colors.green[700],
                        //   ),
                        // );
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
                            if (juego.turnoActual != 0) return;
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
                    color: Colors.amber[800]?.withValues(alpha: 0.2),
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
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text('✅ +$puntos 🏹 a la torre'),
                              //     backgroundColor: Colors.green[700],
                              //   ),
                              // );
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
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text('✅ +$puntos 🏰 a la torre'),
                              //     backgroundColor: Colors.green[700],
                              //   ),
                              // );
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
                    color: Colors.amber[800]?.withValues(alpha: 0.2),
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
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text('✅ +$puntos 💊 a curación'),
                              //     backgroundColor: Colors.green[700],
                              //   ),
                              // );
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
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text('✅ +$puntos 🏥 al hospital'),
                              //     backgroundColor: Colors.green[700],
                              //   ),
                              // );
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
                    color: Colors.amber[800]?.withValues(alpha: 0.2),
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
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text('✅ +$puntos 🌾 a producción'),
                              //     backgroundColor: Colors.green[700],
                              //   ),
                              // );
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
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text('✅ +$puntos 🌱 al cultivo'),
                              //     backgroundColor: Colors.green[700],
                              //   ),
                              // );
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
            width: 300,
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
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text('✅ +$puntos 🔨 a reconstrucción'),
                        //     backgroundColor: Colors.green[700],
                        //   ),
                        // );
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
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text('✅ +$puntos ❤️ al aldeano'),
                        //     backgroundColor: Colors.green[700],
                        //   ),
                        // );
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

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       '✅ ${aldeano.aldeanoBase.nombre} movido a $coordenadaDestino',
    //     ),
    //     backgroundColor: Colors.green[700],
    //   ),
    // );
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

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       '✅ ${guerrero.guerreroBase.nombreId} movido a $coordenadaDestino',
    //     ),
    //     backgroundColor: Colors.green[700],
    //   ),
    // );
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
        color: Colors.brown[700]?.withValues(alpha: 0.5),
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
        backgroundColor: color.withValues(alpha: 0.2),
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
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
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
    double valorSlider = 1;

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
                      value: valorSlider,
                      min: 1,
                      max: puntosMaximos.toDouble(),
                      divisions: puntosMaximos,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setStateDialog(() {
                          valorSlider = value;
                        });
                      },
                    ),
                    Text(
                      '${valorSlider.toInt()} ⚡',
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
                            onConfirmar(valorSlider.toInt());
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

    double valorSlider = 1;

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
                      color: Colors.black.withValues(alpha: 0.5),
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
                        color: Colors.red[900]?.withValues(alpha: 0.3),
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
                      value: valorSlider,
                      min: 1,
                      max: jugador.puntosAcumulados.toDouble(),
                      divisions: jugador.puntosAcumulados,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setStateDialog(() {
                          valorSlider = value;
                        });
                      },
                    ),

                    Text(
                      '${valorSlider.toInt()} ⚡',
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
                              monumento.vidaActual += valorSlider.toInt();
                              jugador.puntosAcumulados -= valorSlider.toInt();
                            });

                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(
                            //     content: Text(
                            //       '✅ +${_valorSlider.toInt()} ❤️ a ${monumento.nombre}',
                            //     ),
                            //     backgroundColor: Colors.green[700],
                            //   ),
                            // );
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
    _hayTerremoto(() {
      _hayPlaga(() {
        _hayEpidemia(() {
          // 👈 NUEVO
          _lanzarDados(() {
            _cosecharCultivos(() {
              _curarConHospitales(() {
                _repararConAldeanos(() {
                  _atacarConTorres(() {
                    print('🎮 Turno listo para jugar');
                  });
                });
              });
            });
          });
        });
      });
    });
  }

  void _hayTerremoto(VoidCallback onComplete) {
    if (_contadorTerremoto > 0) {
      // No hay terremoto, continuar directamente
      onComplete();
      return;
    }

    // Hay terremoto, mostrar modal
    print('🌍🌍🌍 ¡TERREMOTO! 🌍🌍🌍');
    _aplicarTerremoto();
    // Reiniciar contador para el próximo terremoto
    _contadorTerremoto = Random().nextInt(11) + 5; // 5 a 15
    print('🌍 Próximo terremoto en $_contadorTerremoto turnos');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            onComplete(); // 👈 Continuar después del modal
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 280,
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
                // Imagen del terremoto (puedes poner un emoji por ahora)
                const Text('🌍', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                const Text(
                  '🌍 TERREMOTO 🌍',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La tierra tiembla...',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⏳ Cerrando en 2 segundos...',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _aplicarTerremoto() {
    final jugador = juego.jugadorActual;

    // Obtener min y max de edificios (torres, hospitales, monumento)
    final edificios = _getMinMaxVidaPorTipo(TipoCasilla.torre);
    final hospitales = _getMinMaxVidaPorTipo(TipoCasilla.hospital);
    //final monumento = _getMinMaxVidaPorTipo(TipoCasilla.monumento);

    // Combinar todos los valores
    int minGlobal = 999999;
    int maxGlobal = -1;

    if (edificios['min']! > 0) minGlobal = min(minGlobal, edificios['min']!);
    if (hospitales['min']! > 0) minGlobal = min(minGlobal, hospitales['min']!);
    //if (monumento['min']! > 0) minGlobal = min(minGlobal, monumento['min']!);

    if (edificios['max']! > 0) maxGlobal = max(maxGlobal, edificios['max']!);
    if (hospitales['max']! > 0) maxGlobal = max(maxGlobal, hospitales['max']!);
    //if (monumento['max']! > 0) maxGlobal = max(maxGlobal, monumento['max']!);

    if (minGlobal == 999999) return; // No hay edificios

    // Daño aleatorio entre min y max
    final dano = Random().nextInt(maxGlobal - minGlobal + 1) + minGlobal;
    print('🌍 Daño del terremoto: $dano (entre $minGlobal y $maxGlobal)');

    // Aplicar daño a TODOS los edificios
    _aplicarDanoATodos(TipoCasilla.torre, dano);
    _aplicarDanoATodos(TipoCasilla.hospital, dano);
    _aplicarDanoATodos(TipoCasilla.monumento, dano);
  }

  void _aplicarDanoATodos(TipoCasilla tipo, int dano) {
    final jugador = juego.jugadorActual;

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == tipo) {
          _aplicarDano(casilla, dano);

          // Si murió, eliminar la casilla
          if (_getVidaDeCasilla(casilla) <= 0) {
            jugador.tablero.eliminarCasilla(fila, col);
          }
        }
      }
    }
  }

  void _hayPlaga(VoidCallback onComplete) {
    if (_contadorPlaga > 0) {
      // No hay plaga, continuar directamente
      onComplete();
      return;
    }

    // Hay plaga, mostrar modal
    print('🌾🌾🌾 ¡PLAGA! 🌾🌾🌾');

    // Reiniciar contador para la próxima plaga
    _contadorPlaga = Random().nextInt(11) + 5; // 5 a 15
    print('🌾 Próxima plaga en $_contadorPlaga turnos');

    // Aplicar daño a los cultivos
    _aplicarPlaga();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            onComplete();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 280,
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
                const Text('🌾', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                const Text(
                  '🌾 PLAGA EN CULTIVOS 🌾',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Las plagas devoran tus cultivos...',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⏳ Cerrando en 2 segundos...',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _aplicarPlaga() {
    final jugador = juego.jugadorActual;

    // Obtener min y max de cultivos
    final cultivos = _getMinMaxVidaPorTipo(TipoCasilla.cultivo);

    if (cultivos['min'] == 0 && cultivos['max'] == 0) {
      print('🌾 No hay cultivos para dañar');
      return;
    }

    // Daño aleatorio entre min y max
    final dano =
        Random().nextInt(cultivos['max']! - cultivos['min']! + 1) +
        cultivos['min']!;
    print(
      '🌾 Daño de la plaga: $dano (entre ${cultivos['min']} y ${cultivos['max']})',
    );

    // Aplicar daño a TODOS los cultivos
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.cultivo) {
          _aplicarDano(casilla, dano);

          // Si murió, eliminar la casilla
          if (_getVidaDeCasilla(casilla) <= 0) {
            jugador.tablero.eliminarCasilla(fila, col);
            print('🌾 Un cultivo ha sido destruido');
          }
        }
      }
    }
  }

  void _hayEpidemia(VoidCallback onComplete) {
    if (_contadorEpidemia > 0) {
      // No hay epidemia, continuar directamente
      onComplete();
      return;
    }

    // Hay epidemia, mostrar modal
    print('🦠🦠🦠 ¡EPIDEMIA! 🦠🦠🦠');

    // Reiniciar contador para la próxima epidemia
    _contadorEpidemia = Random().nextInt(11) + 5; // 5 a 15
    print('🦠 Próxima epidemia en $_contadorEpidemia turnos');

    // Aplicar daño a guerreros y aldeanos
    _aplicarEpidemia();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            onComplete();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple[900]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🦠', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                const Text(
                  '🦠 EPIDEMIA 🦠',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Una enfermedad azota a tus unidades...',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⏳ Cerrando en 2 segundos...',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _aplicarEpidemia() {
    final jugador = juego.jugadorActual;

    // Obtener min y max de guerreros
    final guerreros = _getMinMaxVidaPorTipo(TipoCasilla.guerrero);
    // Obtener min y max de aldeanos
    final aldeanos = _getMinMaxVidaPorTipo(TipoCasilla.aldeano);

    // Combinar valores para obtener el mínimo global y máximo global
    List<int> mins = [];
    List<int> maxs = [];

    if (guerreros['min']! > 0) {
      mins.add(guerreros['min']!);
      maxs.add(guerreros['max']!);
    }
    if (aldeanos['min']! > 0) {
      mins.add(aldeanos['min']!);
      maxs.add(aldeanos['max']!);
    }

    if (mins.isEmpty) {
      print('🦠 No hay unidades (guerreros o aldeanos) para dañar');
      return;
    }

    // Mínimo global = el más bajo de los mínimos
    // Máximo global = el más alto de los máximos
    final int minGlobal = mins.reduce((a, b) => a < b ? a : b);
    final int maxGlobal = maxs.reduce((a, b) => a > b ? a : b);

    // Daño aleatorio entre minGlobal y maxGlobal
    final dano = Random().nextInt(maxGlobal - minGlobal + 1) + minGlobal;
    print('🦠 Daño de la epidemia: $dano (entre $minGlobal y $maxGlobal)');

    // Aplicar daño a TODOS los guerreros y aldeanos
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero ||
            casilla.tipo == TipoCasilla.aldeano) {
          _aplicarDano(casilla, dano);

          // Si murió, eliminar la casilla
          if (_getVidaDeCasilla(casilla) <= 0) {
            jugador.tablero.eliminarCasilla(fila, col);
            print('🦠 Una unidad ha muerto por la epidemia');
          }
        }
      }
    }
  }

  Map<String, int> _getMinMaxVidaPorTipo(TipoCasilla tipo) {
    final jugador = juego.jugadorActual;
    int minVida = 999999;
    int maxVida = -1;
    bool encontrado = false;

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == tipo) {
          encontrado = true;
          final vida = _getVidaDeCasilla(casilla);
          if (vida < minVida) minVida = vida;
          if (vida > maxVida) maxVida = vida;
        }
      }
    }

    if (!encontrado) {
      return {'min': 0, 'max': 0};
    }

    return {'min': minVida, 'max': maxVida};
  }

  int _getVidaDeCasilla(Casilla casilla) {
    switch (casilla.tipo) {
      case TipoCasilla.monumento:
        return (casilla as CasillaMonumento).vidaActual;
      case TipoCasilla.guerrero:
        return (casilla as CasillaGuerrero).guerrero.vidaActual;
      case TipoCasilla.torre:
        return (casilla as CasillaTorre).torre.vidaActual;
      case TipoCasilla.hospital:
        return (casilla as CasillaHospital).hospital.vidaActual;
      case TipoCasilla.cultivo:
        return (casilla as CasillaCultivo).cultivo.vidaActual;
      case TipoCasilla.aldeano:
        return (casilla as CasillaAldeano).aldeano.vidaActual;
      default:
        return 0;
    }
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
                  'assets/images/dados/${dadoIzq}x$dadoDer.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.brown[600],
                      child: Center(
                        child: Text(
                          '${dadoIzq}x$dadoDer',
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
                  'assets/images/dados/${dadoIzq}x$dadoDer.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.brown[600],
                      child: Center(
                        child: Text(
                          '${dadoIzq}x$dadoDer',
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
    final List<CasillaCultivo> cultivosEnCampo = [];

    // Buscar cultivos
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.cultivo) {
          cultivosEnCampo.add(casilla as CasillaCultivo);
        }
      }
    }

    if (cultivosEnCampo.isEmpty) {
      onComplete();
      return;
    }

    // Calcular puntos totales y animar cada cultivo
    int puntosTotales = 0;
    for (var cultivo in cultivosEnCampo) {
      final puntos = cultivo.cultivo.puntosPorTurnoActual;
      puntosTotales += puntos;

      // 👇 ACTIVAR ANIMACIÓN (SOLO LA IMAGEN)
      setState(() {
        cultivo.cultivo.animar = true;
      });

      // Desactivar animación después de 300ms
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          cultivo.cultivo.animar = false;
        });
      });
    }

    setState(() {
      jugador.puntosAcumulados += puntosTotales;
    });

    // Mostrar número flotante central
    _mostrarNumeroFlotanteCentral(context, puntosTotales);

    // Pequeño delay para que se vea la animación
    Future.delayed(const Duration(milliseconds: 800), onComplete);
  }

  void _mostrarNumeroFlotanteCentral(BuildContext context, int puntos) {
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: MediaQuery.of(context).size.width / 2 - 50,
            top: MediaQuery.of(context).size.height / 2 - 60,
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 10000),
              tween: Tween<double>(begin: 0, end: -100),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(
                    opacity: 1 - (value / -2000).clamp(0, 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: Colors.brown,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$puntos',
                            style: const TextStyle(
                              color: Colors.brown,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  void _curarConHospitales(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final List<CasillaHospital> hospitalesEnCampo = [];

    // 1. BUSCAR TODOS LOS HOSPITALES
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.hospital) {
          hospitalesEnCampo.add(casilla as CasillaHospital);
        }
      }
    }

    if (hospitalesEnCampo.isEmpty) {
      onComplete();
      return;
    }

    // 2. ANIMAR CADA HOSPITAL Y APLICAR CURACIÓN
    final List<Map<String, dynamic>> unidadesCuradas = [];

    for (var hospital in hospitalesEnCampo) {
      // 👇 ACTIVAR ANIMACIÓN DEL HOSPITAL
      setState(() {
        hospital.hospital.animar = true;
      });

      final coordenadas = _getCoordenadasDeCasilla(jugador, hospital);
      final fila = coordenadas['fila']!;
      final columna = coordenadas['columna']!;
      int poderCuracion = hospital.hospital.poderCuracionActual;

      // Habilidad Maya
      if (jugador.civilizacion.id == 'maya') {
        poderCuracion *= 2;
      }

      // Aplicar curación
      _aplicarCuracionEnFilaColumna(
        jugador,
        fila,
        columna,
        poderCuracion,
        unidadesCuradas,
      );

      // 👇 DESACTIVAR ANIMACIÓN DESPUÉS
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          hospital.hospital.animar = false;
        });
      });
    }

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

    // Pequeño delay para que se vean las animaciones
    Future.delayed(const Duration(milliseconds: 500), onComplete);
  }

  // Función auxiliar para contar unidades en fila y columna
  int _contarUnidadesEnFilaColumna(Jugador2 jugador, int fila, int columna) {
    int contador = 0;

    // Contar en la fila
    for (int c = 0; c < 5; c++) {
      final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, c);
      if (casilla.tipo == TipoCasilla.guerrero ||
          casilla.tipo == TipoCasilla.aldeano) {
        contador++;
      }
    }

    // Contar en la columna (sin duplicar la intersección)
    for (int f = 0; f < 4; f++) {
      if (f == fila) continue;
      final casilla = jugador.tablero.obtenerCasillaPorIndices(f, columna);
      if (casilla.tipo == TipoCasilla.guerrero ||
          casilla.tipo == TipoCasilla.aldeano) {
        contador++;
      }
    }

    return contador;
  }

  // Función auxiliar para aplicar curación
  void _aplicarCuracionEnFilaColumna(
    Jugador2 jugador,
    int fila,
    int columna,
    int curacion,
    List<Map<String, dynamic>> lista,
  ) {
    // Aplicar en la fila
    for (int c = 0; c < 5; c++) {
      final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, c);
      if (casilla.tipo == TipoCasilla.guerrero) {
        final guerrero = (casilla as CasillaGuerrero).guerrero;
        lista.add({
          'tipo': 'guerrero',
          'curacion': curacion,
          'objeto': guerrero,
        });
      } else if (casilla.tipo == TipoCasilla.aldeano) {
        final aldeano = (casilla as CasillaAldeano).aldeano;
        lista.add({'tipo': 'aldeano', 'curacion': curacion, 'objeto': aldeano});
      }
    }

    // Aplicar en la columna
    for (int f = 0; f < 4; f++) {
      if (f == fila) continue;
      final casilla = jugador.tablero.obtenerCasillaPorIndices(f, columna);
      if (casilla.tipo == TipoCasilla.guerrero) {
        final guerrero = (casilla as CasillaGuerrero).guerrero;
        lista.add({
          'tipo': 'guerrero',
          'curacion': curacion,
          'objeto': guerrero,
        });
      } else if (casilla.tipo == TipoCasilla.aldeano) {
        final aldeano = (casilla as CasillaAldeano).aldeano;
        lista.add({'tipo': 'aldeano', 'curacion': curacion, 'objeto': aldeano});
      }
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

  void _repararConAldeanos(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final List<CasillaAldeano> aldeanosEnCampo = [];

    // 1. BUSCAR TODOS LOS ALDEANOS
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.aldeano) {
          aldeanosEnCampo.add(casilla as CasillaAldeano);
        }
      }
    }

    if (aldeanosEnCampo.isEmpty) {
      onComplete();
      return;
    }

    // 2. APLICAR REPARACIÓN Y ANIMAR CADA ALDEANO (3 VECES)
    final tiposEdificios = [
      TipoCasilla.monumento,
      TipoCasilla.torre,
      TipoCasilla.hospital,
      TipoCasilla.cultivo,
    ];

    int aldeanosCompletados = 0;

    for (var aldeano in aldeanosEnCampo) {
      final coordenadas = _getCoordenadasDeCasilla(jugador, aldeano);
      final fila = coordenadas['fila']!;
      final columna = coordenadas['columna']!;
      final poderReparacion = aldeano.aldeano.puntosReconstruccionActual;

      // Aplicar reparación
      for (int c = 0; c < 5; c++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, c);
        if (tiposEdificios.contains(casilla.tipo)) {
          _aplicarReparacion(casilla, poderReparacion);
        }
      }

      for (int f = 0; f < 4; f++) {
        if (f == fila) continue;
        final casilla = jugador.tablero.obtenerCasillaPorIndices(f, columna);
        if (tiposEdificios.contains(casilla.tipo)) {
          _aplicarReparacion(casilla, poderReparacion);
        }
      }

      // 👇 ANIMAR 3 VECES (MARTILLAZO)
      _animarMartillazo(aldeano.aldeano, () {
        aldeanosCompletados++;
        if (aldeanosCompletados == aldeanosEnCampo.length) {
          setState(() {});
          Future.delayed(const Duration(milliseconds: 300), onComplete);
        }
      });
    }
  }

  void _animarMartillazo(AldeanoCampo aldeano, VoidCallback onComplete) {
    int repeticiones = 0;

    void animar() {
      setState(() {
        aldeano.animar = true;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          aldeano.animar = false;
        });

        repeticiones++;
        if (repeticiones < 3) {
          Future.delayed(const Duration(milliseconds: 80), animar);
        } else {
          onComplete();
        }
      });
    }

    animar();
  }

  // Función auxiliar para aplicar reparación a un edificio
  void _aplicarReparacion(Casilla casilla, int reparacion) {
    switch (casilla.tipo) {
      case TipoCasilla.monumento:
        (casilla as CasillaMonumento).vidaActual += reparacion;
        break;
      case TipoCasilla.torre:
        (casilla as CasillaTorre).torre.vidaActual += reparacion;
        break;
      case TipoCasilla.hospital:
        (casilla as CasillaHospital).hospital.vidaActual += reparacion;
        break;
      case TipoCasilla.cultivo:
        (casilla as CasillaCultivo).cultivo.vidaActual += reparacion;
        break;
      default:
        break;
    }
  }

  void _atacarConTorres(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final oponente = juego.oponente;
    final List<CasillaTorre> torres = [];

    // 1. BUSCAR TODAS LAS TORRES DEL JUGADOR
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

    // ORDEN DE COLUMNAS: A, B, D, E, C
    final ordenColumnas = [0, 1, 3, 4, 2];

    // Crear lista ordenada de torres según la prioridad de columnas
    final List<CasillaTorre> torresOrdenadas = [];
    for (int columna in ordenColumnas) {
      final torresEnColumna =
          torres.where((t) {
            final coords = _getCoordenadasDeCasilla(jugador, t);
            return coords['columna'] == columna;
          }).toList();
      torresOrdenadas.addAll(torresEnColumna);
    }

    _atacarSiguienteTorre(torresOrdenadas, 0, onComplete);
  }

  void _atacarSiguienteTorre(
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
    final coords = _getCoordenadasDeCasilla(jugador, torre);
    final columna = coords['columna']!;
    final esJugador = jugador == juego.jugadores[0];

    // 👇 PRIMERO BUSCAR OBJETIVO (SIN ANIMAR LA TORRE AÚN)
    dynamic objetivo;
    int filaObjetivo = -1;
    String tipoObjetivo = '';

    if (esJugador) {
      for (int fila = 3; fila >= 0; fila--) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(
          fila,
          columna,
        );
        if (casilla.tipo != TipoCasilla.vacia) {
          objetivo = casilla;
          filaObjetivo = fila;
          tipoObjetivo = _getTipoObjetivo(objetivo);
          break;
        }
      }
    } else {
      for (int fila = 0; fila < 4; fila++) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(
          fila,
          columna,
        );
        if (casilla.tipo != TipoCasilla.vacia) {
          objetivo = casilla;
          filaObjetivo = fila;
          tipoObjetivo = _getTipoObjetivo(objetivo);
          break;
        }
      }
    }

    // Verificar si puede atacar monumento (solo columna C)
    if (objetivo == null) {
      if (_puedeAtacarMonumento() && columna == 2) {
        final monumento =
            oponente.tablero.obtenerCasillaPorIndices(3, 2) as CasillaMonumento;
        objetivo = monumento;
        filaObjetivo = 3;
        tipoObjetivo = 'monumento';
      }
    }

    // 👇 SI NO HAY OBJETIVO VÁLIDO, PASAR A LA SIGUIENTE TORRE SIN ANIMAR
    if (objetivo == null ||
        (tipoObjetivo == 'monumento' && !_puedeAtacarMonumento())) {
      print('🗼 Torre en columna $columna sin objetivo, saltando...');
      _atacarSiguienteTorre(torres, index + 1, onComplete);
      return;
    }

    // 👇 AQUÍ SÍ HAY OBJETIVO, ANIMAR LA TORRE
    setState(() {
      torre.torre.animar = true;
    });

    // Activar resplandor en el objetivo
    _activarResplandor(objetivo);

    // Aplicar daño
    final dano = torre.torre.ataqueActual;
    _aplicarDano(objetivo, dano);

    // Verificar si el objetivo murió
    final bool murio = _getVidaObjetivo(objetivo) <= 0;
    if (murio && objetivo is! CasillaMonumento) {
      oponente.tablero.eliminarCasilla(filaObjetivo, columna);
    }

    // Esperar a que termine la animación
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        torre.torre.animar = false;
        _desactivarResplandor(objetivo);
      });

      // Siguiente torre
      _atacarSiguienteTorre(torres, index + 1, onComplete);
    });
  }

  void _ataqueTacticoIA(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final oponente = juego.oponente;

    // 1. OBTENER SOLO OBJETIVOS FRONTALES
    final objetivos = _getObjetivosFrontales();

    if (objetivos.isEmpty) {
      print('🤖 No hay objetivos frontales disponibles');
      _atacarMonumentoIA(() {
        _resetearBanderasAtaque();
        onComplete();
      });
      return;
    }

    // 2. BUSCAR GUERREROS DISPONIBLES
    final List<Map<String, dynamic>> guerrerosDisponibles = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          final guerrero = (casilla as CasillaGuerrero).guerrero;
          if (!guerrero.yaAtacoEsteTurno) {
            guerrerosDisponibles.add({
              'fila': fila,
              'columna': col,
              'guerrero': guerrero,
              'casilla': casilla,
            });
          }
        }
      }
    }

    if (guerrerosDisponibles.isEmpty) {
      print('🤖 No hay guerreros disponibles para atacar');
      _resetearBanderasAtaque();
      onComplete();
      return;
    }

    // 3. IMPRIMIR OBJETIVO MÁS DÉBIL
    final objetivoPrincipal = objetivos.first;
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎯 OBJETIVO MÁS DÉBIL:');
    print('   📍 Columna: ${objetivoPrincipal['columna']}');
    print('   💔 Vida: ${objetivoPrincipal['vida']}');
    print('   🏷️ Tipo: ${_getTipoObjetivo(objetivoPrincipal['casilla'])}');

    // 4. PROCESAR ATAQUE TÁCTICO (enfocado al objetivo más débil)
    _procesarAtaqueTactico(objetivoPrincipal, () {
      // 5. DESPUÉS DEL ATAQUE TÁCTICO, VOLVER A VERIFICAR OBJETIVOS
      _ataqueSecundario(onComplete);
    });
  }

  void _ataqueSecundario(VoidCallback onComplete) {
    final objetivos = _getObjetivosFrontales();

    if (objetivos.isEmpty) {
      print('🤖 No quedan objetivos frontales. Atacando monumento.');
      _atacarMonumentoIA(() {
        _resetearBanderasAtaque();
        onComplete();
      });
    } else {
      print('🤖 Aún quedan objetivos frontales. Ataque general.');
      _ataqueGeneralIA(() {
        _resetearBanderasAtaque();
        onComplete();
      });
    }
  }

  void _atacarMonumentoIA(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final oponente = juego.oponente;

    // Buscar el monumento enemigo
    CasillaMonumento? monumento;
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.monumento) {
          monumento = casilla as CasillaMonumento;
          break;
        }
      }
    }

    if (monumento == null) {
      print('🏛️ No se encontró el monumento enemigo');
      onComplete();
      return;
    }

    // Buscar guerreros disponibles
    final List<Map<String, dynamic>> guerrerosDisponibles = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          final guerrero = (casilla as CasillaGuerrero).guerrero;
          if (!guerrero.yaAtacoEsteTurno) {
            guerrerosDisponibles.add({
              'fila': fila,
              'columna': col,
              'guerrero': guerrero,
              'casilla': casilla,
            });
          }
        }
      }
    }

    if (guerrerosDisponibles.isEmpty) {
      print('🏛️ No hay guerreros para atacar el monumento');
      onComplete();
      return;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏛️ ATACANDO MONUMENTO ENEMIGO');
    print('🏛️ Vida del monumento: ${monumento.vidaActual}');
    print('⚔️ Guerreros disponibles: ${guerrerosDisponibles.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Atacar con todos los guerreros en orden
    _atacarEnOrdenContraMonumento(guerrerosDisponibles, monumento, onComplete);
  }

  void _atacarEnOrdenContraMonumento(
    List<Map<String, dynamic>> guerreros,
    CasillaMonumento monumento,
    VoidCallback onComplete,
  ) {
    if (guerreros.isEmpty) {
      onComplete();
      return;
    }

    int index = 0;

    void atacarSiguiente() {
      if (index >= guerreros.length) {
        print('🏛️ Ataque al monumento completado');
        onComplete();
        return;
      }

      final guerreroData = guerreros[index];
      final guerrero = guerreroData['guerrero'] as GuerreroCampo;
      final dano = guerrero.ataqueActual;

      print(
        '⚔️ ${guerrero.guerreroBase.nombreId} ataca al monumento (daño $dano)',
      );

      _ejecutarAtaqueGuerrero(
        guerrero: guerrero,
        objetivo: monumento,
        dano: dano,
        onComplete: (murio) {
          if (murio) {
            print('🏆 ¡MONUMENTO DESTRUIDO! Victoria de la IA');

            // 👈 MOSTRAR MODAL DE VICTORIA ANTES DE TERMINAR
            final ganador = juego.jugadorActual; // El que atacó es el ganador
            _mostrarModalVictoria(ganador);

            // No seguir atacando
            onComplete();
          } else {
            index++;
            atacarSiguiente();
          }
        },
      );
    }

    atacarSiguiente();
  }

  void _ataqueGeneralIA(VoidCallback onComplete) {
    final jugador = juego.jugadorActual;
    final oponente = juego.oponente;

    // 1. BUSCAR GUERREROS QUE AÚN NO HAN ATACADO
    final List<Map<String, dynamic>> guerrerosPendientes = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          final guerrero = (casilla as CasillaGuerrero).guerrero;
          if (!guerrero.yaAtacoEsteTurno) {
            guerrerosPendientes.add({
              'fila': fila,
              'columna': col,
              'guerrero': guerrero,
              'casilla': casilla,
            });
          }
        }
      }
    }

    if (guerrerosPendientes.isEmpty) {
      print('🤖 No quedan guerreros por atacar');
      onComplete();
      return;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print(
      '⚔️ ATAQUE GENERAL: ${guerrerosPendientes.length} guerreros pendientes',
    );
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 2. ATACAR EN ORDEN (CADA UNO CONTRA SU OBJETIVO FRONTAL)
    _atacarCadaGuerreroContraSuFrontal(guerrerosPendientes, onComplete);
  }

  void _atacarCadaGuerreroContraSuFrontal(
    List<Map<String, dynamic>> guerreros,
    VoidCallback onComplete,
  ) {
    if (guerreros.isEmpty) {
      onComplete();
      return;
    }

    int index = 0;

    void atacarSiguiente() {
      if (index >= guerreros.length) {
        print('🏁 Ataque general completado');
        onComplete();
        return;
      }

      final guerreroData = guerreros[index];
      final guerrero = guerreroData['guerrero'] as GuerreroCampo;
      final columnaGuerrero = guerreroData['columna'] as int;
      final dano = guerrero.ataqueActual;

      // Buscar el objetivo frontal en su columna
      final objetivoFrontal = _getObjetivoFrontalEnColumna(columnaGuerrero);

      if (objetivoFrontal == null) {
        //print(`⚠️ ${guerrero.guerreroBase.nombreId} no tiene objetivo frontal en columna $columnaGuerrero`);
        index++;
        atacarSiguiente();
        return;
      }

      print(
        '⚔️ ${guerrero.guerreroBase.nombreId} ataca a ${_getTipoObjetivo(objetivoFrontal)} en columna $columnaGuerrero',
      );

      _ejecutarAtaqueGuerrero(
        guerrero: guerrero,
        objetivo: objetivoFrontal,
        dano: dano,
        onComplete: (murio) {
          if (murio) {
            print('💀 ${_getTipoObjetivo(objetivoFrontal)} destruido');
          }
          index++;
          atacarSiguiente();
        },
      );
    }

    atacarSiguiente();
  }

  dynamic _getObjetivoFrontalEnColumna(int columna) {
    final oponente = juego.oponente;
    final jugador = juego.jugadorActual;

    print('🔍 Buscando objetivo frontal en columna $columna');

    if (jugador == juego.jugadores[0]) {
      for (int fila = 3; fila >= 0; fila--) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(
          fila,
          columna,
        );
        print('   Casilla en ($fila,$columna): ${casilla.tipo}');
        if (casilla.tipo != TipoCasilla.vacia &&
            casilla.tipo != TipoCasilla.monumento) {
          print('   ✅ Objetivo encontrado: ${casilla.tipo}');
          return casilla;
        }
      }
    } else {
      for (int fila = 0; fila < 4; fila++) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(
          fila,
          columna,
        );
        print('   Casilla en ($fila,$columna): ${casilla.tipo}');
        if (casilla.tipo != TipoCasilla.vacia &&
            casilla.tipo != TipoCasilla.monumento) {
          print('   ✅ Objetivo encontrado: ${casilla.tipo}');
          return casilla;
        }
      }
    }

    print('   ❌ No hay objetivo frontal en columna $columna');
    return null;
  }

  void _atacarEnOrden(
    List<Map<String, dynamic>> guerreros,
    VoidCallback onComplete,
  ) {
    if (guerreros.isEmpty) {
      onComplete();
      return;
    }

    int index = 0;

    void atacarSiguiente() {
      if (index >= guerreros.length) {
        print('🏁 Se acabaron los guerreros.');
        onComplete();
        return;
      }

      // 🔁 1. Obtener el objetivo MÁS DÉBIL del momento (puede haber cambiado)
      final objetivosActuales = _getObjetivosFrontales();
      if (objetivosActuales.isEmpty) {
        print('🏁 No hay más objetivos frontales. Terminando ataques.');
        onComplete();
        return;
      }

      final objetivoActual = objetivosActuales.first; // El más débil
      final objetivoCasilla = objetivoActual['casilla'];

      final guerreroData = guerreros[index];
      final guerrero = guerreroData['guerrero'] as GuerreroCampo;
      final dano = guerrero.ataqueActual;

      print('⚔️ Atacando con ${guerrero.guerreroBase.nombreId} (daño $dano)');
      print(
        '🎯 Objetivo: columna ${objetivoActual['columna']} con vida ${objetivoActual['vida']}',
      );

      _ejecutarAtaqueGuerrero(
        guerrero: guerrero,
        objetivo: objetivoCasilla,
        dano: dano,
        onComplete: (murio) {
          if (murio) {
            print('💀 Objetivo destruido. Buscando siguiente objetivo...');
            // No aumentamos el índice, usamos el MISMO índice pero con nuevo objetivo
            index++;
            atacarSiguiente(); // Vuelve a evaluar objetivos
          } else {
            index++; // Pasa al siguiente guerrero
            atacarSiguiente();
          }
        },
      );
    }

    atacarSiguiente();
  }

  void _procesarAtaqueTactico(
    Map<String, dynamic> objetivoPrincipal,
    VoidCallback onComplete,
  ) {
    // En lugar de usar solo guerreros en la columna del objetivo, usamos TODOS los guerreros disponibles
    final jugador = juego.jugadorActual;
    final List<Map<String, dynamic>> guerrerosDisponibles = [];

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          final guerrero = (casilla as CasillaGuerrero).guerrero;
          if (!guerrero.yaAtacoEsteTurno) {
            guerrerosDisponibles.add({
              'fila': fila,
              'columna': col,
              'guerrero': guerrero,
              'casilla': casilla,
            });
          }
        }
      }
    }

    if (guerrerosDisponibles.isEmpty) {
      onComplete();
      return;
    }

    _atacarConGuerrerosTacticos(
      guerrerosDisponibles,
      objetivoPrincipal,
      onComplete,
    );
  }

  void _atacarConGuerrerosTacticos(
    List<Map<String, dynamic>> guerreros,
    Map<String, dynamic> objetivoActual,
    VoidCallback onComplete,
  ) {
    if (guerreros.isEmpty) {
      onComplete();
      return;
    }

    final jugador = juego.jugadorActual;
    final oponente = juego.oponente;
    int index = 0;

    void atacarSiguiente() {
      if (index >= guerreros.length) {
        onComplete();
        return;
      }

      // 👇 VOLVER A EVALUAR EL OBJETIVO MÁS DÉBIL EN CADA ITERACIÓN
      final nuevosObjetivos = _getObjetivosFrontales();
      if (nuevosObjetivos.isEmpty) {
        // No hay más objetivos frontales, terminamos
        onComplete();
        return;
      }

      final objetivoPrincipal = nuevosObjetivos.first;
      final columnaObjetivo = objetivoPrincipal['columna'] as int;
      final objetivoCasilla = objetivoPrincipal['casilla'];

      final guerreroData = guerreros[index];
      final guerrero = guerreroData['guerrero'] as GuerreroCampo;
      final columnaOriginal = guerreroData['columna'] as int;

      // Bandera para saber si atacó o no
      bool ataco = false;

      // Si no está en la columna correcta, intentar moverlo
      if (columnaOriginal != columnaObjetivo) {
        // Buscar una casilla vacía en la columna objetivo
        int nuevaFila = -1;
        for (int fila = 0; fila < 4; fila++) {
          if (jugador.tablero.estaVacia(fila, columnaObjetivo)) {
            nuevaFila = fila;
            break;
          }
        }

        if (nuevaFila != -1) {
          // Mover guerrero
          _moverGuerreroIA(
            jugador,
            guerreroData['casilla'] as CasillaGuerrero,
            nuevaFila,
            columnaObjetivo,
          );

          // Actualizar coordenadas en los datos
          guerreroData['fila'] = nuevaFila;
          guerreroData['columna'] = columnaObjetivo;
          print(
            '🚶 IA mueve a ${guerrero.guerreroBase.nombreId} a columna $columnaObjetivo',
          );

          // AHORA SÍ ESTÁ EN LA COLUMNA CORRECTA, PUEDE ATACAR
          ataco = true;
        } else {
          print(
            '⚠️ No hay espacio en columna $columnaObjetivo, ${guerrero.guerreroBase.nombreId} NO PUEDE ATACAR',
          );
          // No se puede mover, NO ATACA
          ataco = false;
        }
      } else {
        // Ya está en la columna correcta, puede atacar
        ataco = true;
      }

      // SOLO ATACAR SI ESTÁ EN LA COLUMNA CORRECTA
      if (ataco) {
        final dano = guerrero.ataqueActual;
        print('⚔️ ${guerrero.guerreroBase.nombreId} ataca con $dano de daño');

        _ejecutarAtaqueGuerrero(
          guerrero: guerrero,
          objetivo: objetivoCasilla,
          dano: dano,
          onComplete: (murio) {
            if (murio) {
              print('💀 Objetivo destruido');
            }
            index++;
            atacarSiguiente();
          },
        );
      } else {
        // No atacó, pasar al siguiente guerrero
        index++;
        atacarSiguiente();
      }
    }

    atacarSiguiente();
  }

  void _resetearBanderasAtaque() {
    final jugador = juego.jugadorActual;
    int contador = 0;

    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.guerrero) {
          final guerrero = (casilla as CasillaGuerrero).guerrero;
          if (guerrero.yaAtacoEsteTurno) {
            guerrero.yaAtacoEsteTurno = false;
            contador++;
          }
        }
      }
    }

    print('🔄 IA: $contador guerreros reseteados para el próximo turno');
  }

  void _moverGuerreroIA(
    Jugador2 jugador, // 👈 RECIBIR JUGADOR
    CasillaGuerrero casillaGuerrero,
    int nuevaFila,
    int nuevaColumna,
  ) {
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
      final coords = Tablero.coordenadaToIndices(coordenadaOrigen)!;
      jugador.tablero.eliminarCasilla(coords[0], coords[1]);
    });
  }

  List<Map<String, dynamic>> _getObjetivosFrontales() {
    final oponente = juego.oponente;
    final jugador = juego.jugadorActual;
    final List<Map<String, dynamic>> objetivosFrontales = [];

    // Por cada columna (0 a 4)
    for (int col = 0; col < 5; col++) {
      dynamic objetivo;
      int filaObjetivo = -1;

      if (jugador == juego.jugadores[0]) {
        // TÚ: buscas desde tu fila 3 hacia abajo
        for (int fila = 3; fila >= 0; fila--) {
          final casilla = oponente.tablero.obtenerCasillaPorIndices(fila, col);
          // 👈 IGNORAR MONUMENTO
          if (casilla.tipo != TipoCasilla.vacia &&
              casilla.tipo != TipoCasilla.monumento) {
            objetivo = casilla;
            filaObjetivo = fila;
            break;
          }
        }
      } else {
        // IA: busca desde su fila 3 hacia abajo (desde su perspectiva)
        for (int fila = 0; fila < 4; fila++) {
          final casilla = oponente.tablero.obtenerCasillaPorIndices(fila, col);
          // 👈 IGNORAR MONUMENTO
          if (casilla.tipo != TipoCasilla.vacia &&
              casilla.tipo != TipoCasilla.monumento) {
            objetivo = casilla;
            filaObjetivo = fila;
            break;
          }
        }
      }

      if (objetivo != null) {
        objetivosFrontales.add({
          'fila': filaObjetivo,
          'columna': col,
          'casilla': objetivo,
          'vida': _getVidaObjetivo(objetivo),
        });
      }
    }

    // Ordenar por vida (menor primero)
    objetivosFrontales.sort(
      (a, b) => (a['vida'] as int).compareTo(b['vida'] as int),
    );

    return objetivosFrontales;
  }

  void _ejecutarAtaqueGuerrero({
    required GuerreroCampo guerrero,
    required dynamic objetivo,
    required int dano,
    required void Function(bool murio) onComplete,
  }) {
    // Animar al atacante
    setState(() {
      guerrero.animar = true;
    });

    // Activar resplandor en el objetivo
    _activarResplandor(objetivo);

    // Aplicar daño
    final bool murio = _aplicarDano(objetivo, dano);

    if (murio && objetivo is! CasillaMonumento) {
      // Eliminar la casilla del tablero correspondiente
      _eliminarCasillaDelTablero(objetivo);
    }

    // Marcar guerrero como atacado
    guerrero.yaAtacoEsteTurno = true;

    // Desanimar atacante y desactivar resplandor después del impacto
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        guerrero.animar = false;
        _desactivarResplandor(objetivo);
      });

      onComplete(murio);
    });
  }

  void _activarResplandor(dynamic objetivo) {
    setState(() {
      switch (objetivo.tipo) {
        case TipoCasilla.guerrero:
          (objetivo as CasillaGuerrero).guerrero.resplandor = true;
          break;
        case TipoCasilla.torre:
          (objetivo as CasillaTorre).torre.resplandor = true;
          break;
        case TipoCasilla.hospital:
          (objetivo as CasillaHospital).hospital.resplandor = true;
          break;
        case TipoCasilla.cultivo:
          (objetivo as CasillaCultivo).cultivo.resplandor = true;
          break;
        case TipoCasilla.aldeano:
          (objetivo as CasillaAldeano).aldeano.resplandor = true;
          break;
        case TipoCasilla.monumento:
          (objetivo as CasillaMonumento).resplandor = true;
          break;
      }
    });
  }

  void _desactivarResplandor(dynamic objetivo) {
    setState(() {
      switch (objetivo.tipo) {
        case TipoCasilla.guerrero:
          (objetivo as CasillaGuerrero).guerrero.resplandor = false;
          break;
        case TipoCasilla.torre:
          (objetivo as CasillaTorre).torre.resplandor = false;
          break;
        case TipoCasilla.hospital:
          (objetivo as CasillaHospital).hospital.resplandor = false;
          break;
        case TipoCasilla.cultivo:
          (objetivo as CasillaCultivo).cultivo.resplandor = false;
          break;
        case TipoCasilla.aldeano:
          (objetivo as CasillaAldeano).aldeano.resplandor = false;
          break;
        case TipoCasilla.monumento:
          (objetivo as CasillaMonumento).resplandor = false;
          break;
      }
    });
  }

  void _mostrarModalAtaqueTorres({
    required int totalDano,
    required int objetivosAtacados,
    required VoidCallback onComplete,
  }) {
    final jugador = juego.jugadorActual;
    final esJugador = jugador == juego.jugadores[0];

    // Obtener imagen de la torre de la civilización
    String imagenTorre = '';
    if (torres != null && jugador.civilizacion.id.isNotEmpty) {
      final torreCiv = torres!.values.firstWhere(
        (t) => t.civilizacionId == jugador.civilizacion.id,
        //orElse: () => null,
      );
      imagenTorre = torreCiv.imagen;
    }

    if (imagenTorre.isEmpty) {
      imagenTorre = 'assets/images/torres/torre_generica.png';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            Navigator.of(context).pop();
            onComplete();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 280,
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
                // Imagen de la torre
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.brown[600],
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(imagenTorre),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Título
                const Text(
                  '🗼 TORRES ATACANDO',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Resultado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[800]?.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$objetivosAtacados OBJETIVOS ATACADOS',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '-$totalDano ❤️',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

  void _mostrarModalAtaqueGuerrero({
    required GuerreroCampo guerrero,
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
                colors: [Colors.red[900]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Atacante
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.brown[600],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(guerrero.guerreroBase.imagen),
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
                            guerrero.guerreroBase.nombreId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '🗡️ $dano',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Icon(Icons.arrow_forward, color: Colors.amber, size: 30),
                const SizedBox(height: 16),

                // Defensor
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[900]?.withValues(alpha: 0.3),
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

  // void _aplicarDano(dynamic objetivo, int dano) {
  //   switch (objetivo.tipo) {
  //     case TipoCasilla.monumento:
  //       //(objetivo as CasillaMonumento).vidaActual -= dano;
  //       final monumento = objetivo as CasillaMonumento;
  //       monumento.vidaActual -= dano;
  //       if (monumento.vidaActual <= 0) {
  //         print('🏆 MONUMENTO DESTRUIDO');
  //         _mostrarModalVictoria(juego.jugadorActual);
  //       }
  //       break;
  //     case TipoCasilla.guerrero:
  //       (objetivo as CasillaGuerrero).guerrero.vidaActual -= dano;
  //       break;
  //     case TipoCasilla.torre:
  //       (objetivo as CasillaTorre).torre.vidaActual -= dano;
  //       break;
  //     case TipoCasilla.hospital:
  //       (objetivo as CasillaHospital).hospital.vidaActual -= dano;
  //       break;
  //     case TipoCasilla.cultivo:
  //       (objetivo as CasillaCultivo).cultivo.vidaActual -= dano;
  //       break;
  //     case TipoCasilla.aldeano:
  //       (objetivo as CasillaAldeano).aldeano.vidaActual -= dano;
  //       break;
  //   }
  // }

  bool _aplicarDano(dynamic objetivo, int dano) {
    switch (objetivo.tipo) {
      case TipoCasilla.monumento:
        final monumento = objetivo as CasillaMonumento;
        monumento.vidaActual -= dano;
        if (monumento.vidaActual <= 0) {
          print('🏆 MONUMENTO DESTRUIDO');
          _mostrarModalVictoria(juego.jugadorActual);
          return true;
        }
        break;

      case TipoCasilla.guerrero:
        final guerrero = (objetivo as CasillaGuerrero).guerrero;
        guerrero.vidaActual -= dano;
        if (guerrero.vidaActual <= 0) return true;
        break;

      case TipoCasilla.torre:
        final torre = (objetivo as CasillaTorre).torre;
        torre.vidaActual -= dano;
        if (torre.vidaActual <= 0) return true;
        break;

      case TipoCasilla.hospital:
        final hospital = (objetivo as CasillaHospital).hospital;
        hospital.vidaActual -= dano;
        if (hospital.vidaActual <= 0) return true;
        break;

      case TipoCasilla.cultivo:
        final cultivo = (objetivo as CasillaCultivo).cultivo;
        cultivo.vidaActual -= dano;
        if (cultivo.vidaActual <= 0) return true;
        break;

      case TipoCasilla.aldeano:
        final aldeano = (objetivo as CasillaAldeano).aldeano;
        aldeano.vidaActual -= dano;
        if (aldeano.vidaActual <= 0) return true;
        break;
    }

    return false; // No murió
  }

  bool _puedeAtacarMonumento() {
    final oponente = juego.oponente;

    // Recorrer todo el tablero enemigo
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(fila, col);

        // Si hay ALGO que no sea vacío y no sea el monumento, NO se puede atacar el monumento
        if (casilla.tipo != TipoCasilla.vacia &&
            casilla.tipo != TipoCasilla.monumento) {
          print(
            '🔍 Hay unidad enemiga en ($fila,$col), no se puede atacar monumento',
          );
          return false;
        }
      }
    }

    print('✅ Campo enemigo vacío, se puede atacar monumento');
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
                    color: Colors.red[900]?.withValues(alpha: 0.3),
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

  void _mostrarModalVictoria(Jugador2 ganador) {
    _juegoTerminado = true; // 👈 MARCA QUE EL JUEGO TERMINÓ

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber[800]!, Colors.brown[900]!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trofeo
                const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
                const SizedBox(height: 16),

                // Texto de victoria
                const Text(
                  '🏆 ¡VICTORIA! 🏆',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Civilización ganadora
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.brown[800],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Text(
                    ganador.civilizacion.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Guerrero principal y monumento
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Guerrero principal
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.brown[300],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber, width: 2),
                            image: DecorationImage(
                              image: AssetImage(
                                ganador.guerrerosSeleccionados.first.imagen,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ganador.guerrerosSeleccionados.first.nombreId,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    // VS
                    const Text(
                      '⚡',
                      style: TextStyle(color: Colors.amber, fontSize: 30),
                    ),

                    // Monumento
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.brown[300],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber, width: 2),
                            image: DecorationImage(
                              image: AssetImage(
                                ganador.monumentoEnCampo.imagenPath,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ganador.monumentoEnCampo.nombre,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botón para reiniciar
                // Botón para reiniciar
                ElevatedButton(
                  onPressed: () {
                    // 1. Cerrar el modal de victoria
                    Navigator.pop(context);

                    // 2. Reemplazar la pantalla actual con una nueva instancia de Mitic2Screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectCivScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.brown[900],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'REINICIAR PARTIDA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
      _resetearBanderasAtaque();
    });

    _mostrarCambioTurno();

    // 👇 DECREMENTAR CONTADORES
    _contadorTerremoto--;
    _contadorPlaga--;
    _contadorEpidemia--;
    print('🌍 Terremoto en $_contadorTerremoto turnos');
    print('🌾 Plaga en $_contadorPlaga turnos');
    print('🦠 Epidemia en $_contadorEpidemia turnos');
  }

  void _mostrarCambioTurno() {
    final jugadorSiguiente = juego.jugadores[juego.turnoActual == 0 ? 0 : 1];

    // 👇 DETERMINAR EL DELAY SEGÚN QUIÉN SEA EL PRÓXIMO JUGADOR
    final esHumano = juego.turnoActual == 0; // El que viene es humano
    final delaySegundos =
        esHumano ? 1 : 0; // Humano: 0 segundos, IA: 2 segundos

    Future.delayed(Duration(seconds: delaySegundos), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // Cerrar automáticamente después de 2 segundos
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              Navigator.of(context).pop();

              // Después de mostrar el cambio, continuar con el turno
              if (juego.turnoActual == 0) {
                _iniciarTurno();
              } else {
                _ejecutarIA();
              }
            }
          });

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
                    color: Colors.black.withValues(alpha: 0.5),
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
    });
  }

  void _ejecutarIA() {
    Future.delayed(const Duration(seconds: 1), () {
      _hayTerremoto(() {
        _hayPlaga(() {
          _hayEpidemia(() {
            // 👈 NUEVO
            _lanzarDadosIA(() {
              _cosecharCultivos(() {
                _curarConHospitales(() {
                  _repararConAldeanos(() {
                    _atacarConTorres(() {
                      _tomarDecisionIA(() {
                        _ataqueTacticoIA(() {
                          print('🤖 IA terminó su turno');
                          _cambiarTurno();
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
  }

  void _tomarDecisionIA(VoidCallback onComplete) {
    final ia = IAFactory.crearIA(
      juego: juego,
      onPasarTurno: () {
        // Cuando la IA termina de invocar/mejorar, llamamos al callback
        onComplete();
      },
      aldeanos: aldeanos,
      cultivos: cultivos,
      torres: torres,
      hospitales: hospitales,
      onInvocar: _invocarIA,
      onMejorar: _mejorarIA,
    );
    ia.tomarDecision();
  }

  void _mejorarIA(String tipo, int fila, int columna, int puntos) {
    print('🎮 MEJORAR IA: $tipo en ($fila,$columna) con $puntos puntos');

    final jugador = juego.jugadorActual;
    final casilla = jugador.tablero.obtenerCasillaPorIndices(fila, columna);

    setState(() {
      switch (tipo) {
        case 'hospital':
          if (casilla.tipo == TipoCasilla.hospital) {
            final hospital = (casilla as CasillaHospital).hospital;
            hospital.poderCuracionActual += puntos;
            jugador.puntosAcumulados -= puntos;
            print('   ✅ Hospital mejorado: +$puntos curacion');
          }
          break;

        case 'cultivo':
          if (casilla.tipo == TipoCasilla.cultivo) {
            final cultivo = (casilla as CasillaCultivo).cultivo;
            cultivo.puntosPorTurnoActual += puntos;
            jugador.puntosAcumulados -= puntos;
            print('   ✅ Cultivo mejorado: +$puntos producción');
          }
          break;

        case 'torre':
          if (casilla.tipo == TipoCasilla.torre) {
            final torre = (casilla as CasillaTorre).torre;
            torre.ataqueActual += puntos;
            jugador.puntosAcumulados -= puntos;
            print('   ✅ Torre mejorada: +$puntos ataque');
          }
          break;

        case 'guerrero':
          if (casilla.tipo == TipoCasilla.guerrero) {
            final guerrero = (casilla as CasillaGuerrero).guerrero;
            guerrero.ataqueActual += puntos;
            jugador.puntosAcumulados -= puntos;
            print('   ✅ Guerrero mejorado: +$puntos ataque');
          }
          break;

        case 'aldeano':
          if (casilla.tipo == TipoCasilla.aldeano) {
            final aldeano = (casilla as CasillaAldeano).aldeano;
            aldeano.puntosReconstruccionActual += puntos;
            jugador.puntosAcumulados -= puntos;
            print('   ✅ Aldeano mejorado: +$puntos reconstrucción');
          }
          break;
      }
    });
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
      case 'guerrero':
        final guerreroBase = guerreros![id];
        if (guerreroBase == null) {
          print('❌ Error: no se encontró guerrero con id $id');
          return;
        }
        final guerreroCampo = GuerreroCampo.desdeGuerrero(
          guerrero: guerreroBase, // 👈 AHORA ES SEGURO
          coordenada: coordenada,
        );
        nuevaCasilla = CasillaGuerrero(
          coordenada: coordenada,
          guerrero: guerreroCampo,
        );
        break;

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

  void _atacarJugador(GuerreroCampo guerrero, int fila, int columna) {
    final oponente = juego.oponente;

    // 1. Buscar el objetivo frontal en la misma columna
    dynamic objetivo = _getObjetivoFrontalEnColumna(columna);

    // 2. Si no hay objetivo frontal, atacar al monumento
    if (objetivo == null) {
      print('🏛️ No hay objetivos frontales, atacando al monumento');
      objetivo = _getMonumentoEnemigo();
      if (objetivo == null) {
        print('❌ No se encontró el monumento enemigo');
        return;
      }
    }

    // 3. Ejecutar el ataque
    final dano = guerrero.ataqueActual;
    print(
      '⚔️ ${guerrero.guerreroBase.nombreId} ataca a ${_getTipoObjetivo(objetivo)} (daño $dano)',
    );

    _ejecutarAtaqueGuerrero(
      guerrero: guerrero,
      objetivo: objetivo,
      dano: dano,
      onComplete: (murio) {
        if (murio) {
          print('💀 Objetivo destruido');

          // Si el objetivo era un edificio, eliminarlo del tablero
          if (objetivo is! CasillaMonumento) {
            _eliminarCasillaDelTablero(objetivo);
          }
        }

        // Actualizar la UI
        setState(() {});
      },
    );
  }

  CasillaMonumento? _getMonumentoEnemigo() {
    final oponente = juego.oponente;
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo == TipoCasilla.monumento) {
          return casilla as CasillaMonumento;
        }
      }
    }
    return null;
  }

  void _eliminarCasillaDelTablero(dynamic objetivo) {
    final oponente = juego.oponente;
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        if (oponente.tablero.obtenerCasillaPorIndices(fila, col) == objetivo) {
          setState(() {
            oponente.tablero.eliminarCasilla(fila, col);
          });
          return;
        }
      }
    }
  }

  // Verifica si el tablero enemigo solo tiene el monumento
  bool _tableroEnemigoVacio() {
    final oponente = juego.oponente;
    for (int fila = 0; fila < 4; fila++) {
      for (int col = 0; col < 5; col++) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(fila, col);
        if (casilla.tipo != TipoCasilla.vacia &&
            casilla.tipo != TipoCasilla.monumento) {
          return false;
        }
      }
    }
    return true;
  }

  // Verifica si el guerrero tiene un objetivo frontal en su columna
  bool _tieneObjetivoFrontal(int columna) {
    final oponente = juego.oponente;
    final jugador = juego.jugadorActual;

    if (jugador == juego.jugadores[0]) {
      for (int fila = 3; fila >= 0; fila--) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(
          fila,
          columna,
        );
        if (casilla.tipo != TipoCasilla.vacia &&
            casilla.tipo != TipoCasilla.monumento) {
          return true;
        }
      }
    } else {
      for (int fila = 0; fila < 4; fila++) {
        final casilla = oponente.tablero.obtenerCasillaPorIndices(
          fila,
          columna,
        );
        if (casilla.tipo != TipoCasilla.vacia &&
            casilla.tipo != TipoCasilla.monumento) {
          return true;
        }
      }
    }
    return false;
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
