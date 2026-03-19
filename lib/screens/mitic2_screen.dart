import 'package:flutter/material.dart';
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
            double ladoPorAlto = alto / 11;
            double ladoCelda =
                ladoPorAncho < ladoPorAlto ? ladoPorAncho : ladoPorAlto;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ladoCelda * 5,
                  maxHeight: ladoCelda * 11,
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
                      height: ladoCelda,
                      child: Center(
                        child: Text(
                          '⚔️ MITIC 2.0 ⚔️',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: ladoCelda * 0.3,
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
      height: ladoCelda,
      child: Row(
        children: List.generate(5, (columna) {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: Colors.amber,
                        size: ladoCelda * 0.2,
                      ),
                      Text(
                        '${jugador.puntosAcumulados}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ladoCelda * 0.2,
                        ),
                      ),
                    ],
                  ),
                  if (!esEnemigo)
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      child: ElevatedButton(
                        onPressed: () {
                          print('🎮 Botón PASAR presionado');
                          // Aquí irá la lógica de pasar turno
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          minimumSize: Size(ladoCelda * 0.6, ladoCelda * 0.25),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'PASAR',
                          style: TextStyle(fontSize: 8),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

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
                    print('📍 Clic en casilla vacía $coordenada');
                    _mostrarModalInvocacion(
                      fila: filaIndex,
                      columna: columna,
                      coordenada: coordenada,
                    );
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
                  print('📍 Clic en monumento ${monumento.nombre}');
                },
              );

            case TipoCasilla.guerrero:
              final casillaGuerrero = casilla as CasillaGuerrero;
              return GuerreroTablero(
                ladoCelda: ladoCelda,
                guerrero: casillaGuerrero.guerrero,
                onTap: () {
                  print('📍 Clic en guerrero en $coordenada');
                },
              );

            case TipoCasilla.torre:
              final casillaTorre = casilla as CasillaTorre;
              return TorreTablero(
                ladoCelda: ladoCelda,
                torre: casillaTorre.torre,
                onTap: () => print('📍 Torre en $coordenada'),
              );

            case TipoCasilla.hospital:
              final casillaHospital = casilla as CasillaHospital;
              return HospitalTablero(
                ladoCelda: ladoCelda,
                hospital: casillaHospital.hospital,
                onTap: () => print('📍 Hospital en $coordenada'),
              );

            case TipoCasilla.cultivo:
              final casillaCultivo = casilla as CasillaCultivo;
              return CultivoTablero(
                ladoCelda: ladoCelda,
                cultivo: casillaCultivo.cultivo,
                onTap: () => print('📍 Cultivo en $coordenada'),
              );

            case TipoCasilla.aldeano:
              final casillaAldeano = casilla as CasillaAldeano;
              return AldeanoTablero(
                ladoCelda: ladoCelda,
                aldeano: casillaAldeano.aldeano,
                onTap: () => print('📍 Aldeano en $coordenada'),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${item.nombre} invocado en $coordenada'),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  void _limpiarSeleccion() {
    _filaSeleccionada = null;
    _columnaSeleccionada = null;
    _coordenadaSeleccionada = null;
    _itemPendiente = null;
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
