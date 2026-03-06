import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async'; // Necesario para el Timer
import '../widgets/cartas.dart';
import '../enums/modoaccion.dart';
import '../models/juego_model.dart';
import '../models/jugador_model.dart';
import '../models/guerrero_model.dart';
import '../models/civilizacion_model.dart';
import '../models/monument_model.dart';
import '../models/guerrero_field_model.dart';
import '../ia/ia_controller.dart';
import '../services/guerrero_service.dart';
import '../services/civilizacion_service.dart';

class TableroScreen extends StatefulWidget {
  const TableroScreen({super.key});

  @override
  State<TableroScreen> createState() => _TableroScreenState();
}

ModoAccion _modoActual = ModoAccion.normal;

// Guerrero seleccionado temporalmente
Map<String, dynamic>? _guerreroSeleccionado;

class _TableroScreenState extends State<TableroScreen> {
  // Índice seleccionado en el BottomNavigationBar
  int _selectedIndex = -1;
  late Juego juego;
  GuerreroField? _atacanteSeleccionado;
  List<GuerreroField> _objetivosPosibles = [];
  bool _dadosLanzadosEsteTurno = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarJuegoDePrueba();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ============================================
                // ÁREA DE ENEMIGOS (ARRIBA) - JUGADOR 2
                // ============================================
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.brown[100]!, Colors.amber[50]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.brown[400]!, width: 2),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // PUNTOS DEL ENEMIGO (al inicio)
                                buildPuntosCounter(
                                  juego.jugadores[1].puntosAcumulados,
                                  esEnemigo: true,
                                ),

                                const SizedBox(width: 12),

                                // GUERREROS EN CAMPO DEL ENEMIGO (SIEMPRE 3 O 4 ESPACIOS)
                                ...List.generate(
                                  juego.jugadores[1].guerrerosEnCampo.length,
                                  (index) {
                                    final gf =
                                        juego
                                            .jugadores[1]
                                            .guerrerosEnCampo[index];
                                    final bool disponible =
                                        gf.guerreroBase.id.isEmpty;

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: buildGuerreroCardYUopponet(
                                        nombre:
                                            disponible
                                                ? 'Vacío'
                                                : gf.guerreroBase.nombreId,
                                        vida: gf.vidaActual,
                                        ataque: gf.ataqueActual,
                                        costo: gf.guerreroBase.costoInvocacion,
                                        imagenPath: gf.guerreroBase.imagen,
                                        disponible: disponible,
                                        // ============================================
                                        // NUEVO PARÁMETRO: ¿Es objetivo?
                                        // ============================================
                                        esObjetivo:
                                            _modoActual ==
                                                ModoAccion
                                                    .atacarSeleccionando &&
                                            _objetivosPosibles.contains(gf),
                                        // ============================================
                                        // onTap para atacar
                                        // ============================================
                                        onTap:
                                            _modoActual ==
                                                        ModoAccion
                                                            .atacarSeleccionando &&
                                                    _objetivosPosibles.contains(
                                                      gf,
                                                    )
                                                ? () => _ejecutarAtaque(gf)
                                                : null,
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(width: 8),

                                // MONUMENTO DEL ENEMIGO (al final)
                                buildMonumentoCardYUopponent(
                                  nombre:
                                      juego
                                          .jugadores[1]
                                          .monumentoEnCampo
                                          .nombre,
                                  vida:
                                      juego
                                          .jugadores[1]
                                          .monumentoEnCampo
                                          .vidaActual,
                                  imagenPath:
                                      juego
                                          .jugadores[1]
                                          .monumentoEnCampo
                                          .imagenPath,
                                  esObjetivo:
                                      _modoActual ==
                                          ModoAccion.atacarSeleccionando &&
                                      _objetivosPosibles
                                          .isEmpty, // Si no hay guerreros
                                  onTap:
                                      _modoActual ==
                                                  ModoAccion
                                                      .atacarSeleccionando &&
                                              _objetivosPosibles.isEmpty
                                          ? () => _ejecutarAtaque(
                                            null,
                                          ) // null indica que es monumento
                                          : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ============================================
                // TU ÁREA (ABAJO) - AHORA DINÁMICA
                // ============================================
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.brown[100]!, Colors.amber[50]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.brown[400]!, width: 2),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // MONUMENTO DEL JUGADOR 1
                                buildMonumentoCardYU(
                                  nombre:
                                      juego
                                          .jugadores[0]
                                          .monumentoEnCampo
                                          .nombre,
                                  vida:
                                      juego
                                          .jugadores[0]
                                          .monumentoEnCampo
                                          .vidaActual,
                                  imagenPath:
                                      juego
                                          .jugadores[0]
                                          .monumentoEnCampo
                                          .imagenPath,
                                ),
                                const SizedBox(width: 12),

                                // GUERREROS EN CAMPO DEL JUGADOR 1 (SIEMPRE 3 O 4 ESPACIOS)
                                ...List.generate(juego.jugadores[0].guerrerosEnCampo.length, (
                                  index,
                                ) {
                                  final gf =
                                      juego
                                          .jugadores[0]
                                          .guerrerosEnCampo[index];
                                  final bool disponible =
                                      gf.guerreroBase.id.isEmpty;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: buildGuerreroCardYU(
                                      nombre:
                                          disponible
                                              ? 'Vacío'
                                              : gf.guerreroBase.nombreId,
                                      vida: gf.vidaActual,
                                      ataque: gf.ataqueActual,
                                      costo: gf.guerreroBase.costoInvocacion,
                                      imagenPath: gf.guerreroBase.imagen,
                                      disponible: disponible,
                                      modoActual: _modoActual,
                                      isSelected:
                                          !disponible &&
                                          _guerreroSeleccionado?['nombre'] ==
                                              gf.guerreroBase.nombreId,

                                      // ============================================
                                      // NUEVOS PARÁMETROS PARA MODO ATAQUE
                                      // ============================================
                                      puedeAtacar:
                                          _modoActual == ModoAccion.atacar &&
                                          !gf.yaAtacoEsteTurno &&
                                          !disponible,

                                      esObjetivo:
                                          _modoActual ==
                                              ModoAccion.atacarSeleccionando &&
                                          _objetivosPosibles.contains(gf),

                                      yaAtaco: gf.yaAtacoEsteTurno,

                                      // ============================================
                                      // onTap AHORA MANEJA TANTO CURAR/MEJORAR COMO ATAQUE
                                      // ============================================
                                      onTap:
                                          disponible
                                              ? null
                                              : () {
                                                if (_modoActual ==
                                                        ModoAccion.atacar &&
                                                    !gf.yaAtacoEsteTurno) {
                                                  // MODO ATAQUE: seleccionar atacante
                                                  _seleccionarAtacante(gf);
                                                } else if (_modoActual ==
                                                        ModoAccion.curar ||
                                                    _modoActual ==
                                                        ModoAccion.mejorar) {
                                                  // MODO CURAR/MEJORAR: seleccionar guerrero para curar/mejorar
                                                  setState(() {
                                                    _guerreroSeleccionado = {
                                                      'nombre':
                                                          gf
                                                              .guerreroBase
                                                              .nombreId,
                                                      'vida': gf.vidaActual,
                                                      'ataque': gf.ataqueActual,
                                                      'costo':
                                                          gf
                                                              .guerreroBase
                                                              .costoInvocacion,
                                                    };
                                                  });
                                                  _mostrarModalPuntos(
                                                    context: context,
                                                    guerrero:
                                                        _guerreroSeleccionado!,
                                                    puntosDisponibles:
                                                        juego
                                                            .jugadores[0]
                                                            .puntosAcumulados,
                                                    modo: _modoActual,
                                                  );
                                                }
                                              },
                                    ),
                                  );
                                }),

                                // ESPACIO EXTRA PARA CHINA (si aplica)
                                if (juego.jugadores[0].civilizacion.id ==
                                        'china' &&
                                    juego
                                            .jugadores[0]
                                            .guerrerosEnCampo
                                            .length ==
                                        3)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Container(
                                      width: 170,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.brown[200]?.withOpacity(
                                          0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.brown[400]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.add_circle,
                                            color: Colors.brown,
                                            size: 30,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Extra China',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                const SizedBox(width: 8),

                                // CONTADOR DE PUNTOS
                                buildPuntosCounter(
                                  juego.jugadores[0].puntosAcumulados,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Espacio extra abajo para que no quede pegado al borde
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // ============================================
      // BOTTOM NAVIGATION BAR CON LAS 6 ACCIONES
      // ============================================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.brown[800],
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.brown[300],
        currentIndex: _selectedIndex == -1 ? 0 : _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) {
              if (juego.jugadores[0].puntosAcumulados <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ No tenés puntos para reconstruir'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                _mostrarModalPuntos(
                  context: context,
                  puntosDisponibles: juego.jugadores[0].puntosAcumulados,
                  modo: ModoAccion.reconstruir,
                );
              }
            }
            // Activar modos según la opción
            else if (index == 2) {
              // Curar
              _modoActual = ModoAccion.curar;
              _guerreroSeleccionado = null;
            } else if (index == 3) {
              // Mejorar
              _modoActual = ModoAccion.mejorar;
              _guerreroSeleccionado = null;
            } else {
              _modoActual = ModoAccion.normal;
              _guerreroSeleccionado = null;
            }

            // Las otras acciones (invocar, atacar, pasar) por ahora solo snackbar
            if (index == 1) {
              mostrarModalInvocacion(context);
            } else if (index == 4) {
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(
              //     content: Text('⚔️ Seleccione un guerrero para atacar'),
              //   ),
              // );
              _activarModoAtaque();
            } else if (index == 5) {
              _cambiarTurno();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Reconstruir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Invocar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Curar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Mejorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cut), // Usamos cut en lugar de swords
            label: 'Atacar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.skip_next), label: 'Pasar'),
        ],
      ),
    );
  }

  Future<void> _inicializarJuegoDePrueba() async {
    try {
      // ============================================
      // 1. CARGAR DATOS DE LOS JSON
      // ============================================
      final guerreros = await GuerreroService.loadGuerreros();
      final civilizaciones = await CivilizacionService.loadCivilizaciones();
      final translations = await GuerreroService.loadTranslations('es');

      // ============================================
      // 2. BUSCAR GUERREROS POR ID
      // ============================================
      final huitzilopochtli = guerreros.firstWhere((g) => g.id == 'azteca_001');
      final kukulkan = guerreros.firstWhere((g) => g.id == 'maya_001');
      final terracota = guerreros.firstWhere((g) => g.id == 'china_001');
      final gladiador = guerreros.firstWhere((g) => g.id == 'romanos_001');
      final juana = guerreros.firstWhere((g) => g.id == 'francia_001');
      final templario = guerreros.firstWhere((g) => g.id == 'jerusalen_001');

      // ============================================
      // 3. BUSCAR CIVILIZACIONES
      // ============================================
      final azteca = civilizaciones.firstWhere((c) => c.id == 'azteca');
      final maya = civilizaciones.firstWhere((c) => c.id == 'maya');

      // ============================================
      // 4. CREAR JUGADOR 1 (TÚ)
      // ============================================
      final int espacios = (azteca.id == 'china') ? 4 : 3;
      final jugador1 = Jugador(
        civilizacion: azteca,
        guerrerosSeleccionados: [
          huitzilopochtli,
          kukulkan,
          terracota,
          gladiador,
        ],
        monumentoEnCampo: MonumentField.fromCivilizacion(azteca),
        guerrerosEnCampo: List.generate(
          espacios,
          (index) => GuerreroField.vacio(posicion: index),
        ),
        puntosAcumulados: 0,
        turno: 0,
        yaAtacoEsteTurno: false,
        guerrerosEnMano: [terracota, gladiador, huitzilopochtli, kukulkan],
      );

      // ============================================
      // 5. CREAR JUGADOR 2 (ENEMIGO)
      // ============================================
      final int espacios2 = (maya.id == 'china') ? 4 : 3;

      // Crear campo con 2 guerreros
      final List<GuerreroField> campoEnemigo = List.generate(espacios2, (
        index,
      ) {
        return GuerreroField.vacio(posicion: index);
      });

      final jugador2 = Jugador(
        civilizacion: maya,
        guerrerosSeleccionados: [kukulkan, templario, juana, terracota],
        monumentoEnCampo: MonumentField.fromCivilizacion(maya),
        guerrerosEnCampo: campoEnemigo, // <-- AHORA CON 2 GUERREROS
        puntosAcumulados: 0,
        turno: 1,
        yaAtacoEsteTurno: false,
        guerrerosEnMano: [
          juana,
          terracota,
          kukulkan,
          templario,
        ], // Los que no están en campo
      );

      // ============================================
      // 6. CREAR EL JUEGO
      // ============================================
      setState(() {
        juego = Juego(jugadores: [jugador1, jugador2], turnoActual: 0, fase: 0);
      });

      print('✅ Juego inicializado con datos del JSON');
    } catch (e) {
      print('❌ Error cargando datos: $e');
    }
  }

  void _mostrarModalPuntos({
    required BuildContext context,
    Map<String, dynamic>? guerrero, // Ahora es opcional
    required int puntosDisponibles,
    required ModoAccion modo,
  }) {
    // ============================================
    // VALIDACIÓN: ¿Hay puntos disponibles?
    // ============================================
    if (puntosDisponibles <= 0) {
      String mensaje;
      if (modo == ModoAccion.reconstruir) {
        mensaje = '❌ No tenés puntos para reconstruir';
      } else {
        mensaje =
            '❌ No tenés puntos para ${modo == ModoAccion.curar ? 'curar' : 'mejorar'}';
      }

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(mensaje),
      //     backgroundColor: Colors.red[700],
      //     duration: const Duration(seconds: 2),
      //   ),
      // );
      return;
    }

    // ============================================
    // VALIDACIÓN PARA RECONSTRUIR: No necesita guerrero
    // ============================================
    if (modo != ModoAccion.reconstruir && guerrero == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: no se seleccionó un guerrero'),
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
            // Determinar título y color según el modo
            String titulo;
            Color color;
            if (modo == ModoAccion.reconstruir) {
              titulo = '🏛️ RECONSTRUIR';
              color = Colors.blue;
            } else if (modo == ModoAccion.curar) {
              titulo = '❤️ CURAR';
              color = Colors.green;
            } else {
              titulo = '🗡️ MEJORAR';
              color = Colors.orange;
            }

            return AlertDialog(
              backgroundColor: Colors.brown[800],
              title: Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mostrar nombre solo si no es reconstruir
                  if (modo != ModoAccion.reconstruir)
                    Text(
                      guerrero!['nombre'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  if (modo != ModoAccion.reconstruir)
                    const SizedBox(height: 16),

                  Text(
                    'Puntos disponibles: $puntosDisponibles ⚡',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _valorSlider,
                    min: 1,
                    max: puntosDisponibles.toDouble(),
                    divisions: puntosDisponibles,
                    activeColor: color,
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cierra modal
                    setState(() {
                      final jugador = juego.jugadores[0];

                      if (modo == ModoAccion.reconstruir) {
                        // Reconstruir monumento
                        jugador.monumentoEnCampo.vidaActual +=
                            _valorSlider.toInt();
                      } else {
                        // Curar o mejorar guerrero
                        final gf = jugador.guerrerosEnCampo.firstWhere(
                          (g) => g.guerreroBase.nombreId == guerrero!['nombre'],
                        );

                        if (modo == ModoAccion.curar) {
                          gf.vidaActual += _valorSlider.toInt();
                        } else {
                          gf.ataqueActual += _valorSlider.toInt();
                        }
                      }

                      jugador.puntosAcumulados -= _valorSlider.toInt();
                      _modoActual = ModoAccion.normal;
                      _guerreroSeleccionado = null;
                    });
                    //_cambiarTurno();
                    // Mensaje de éxito
                    String mensaje;
                    if (modo == ModoAccion.reconstruir) {
                      mensaje = '✅ ${_valorSlider.toInt()} ⚡ reconstruidos';
                    } else {
                      mensaje =
                          '✅ ${_valorSlider.toInt()} ⚡ ${modo == ModoAccion.curar ? 'curados' : 'mejorados'} a ${guerrero!['nombre']}';
                    }

                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(content: Text(mensaje), backgroundColor: color),
                    // );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  child: Text(
                    modo == ModoAccion.reconstruir
                        ? 'RECONSTRUIR'
                        : modo == ModoAccion.curar
                        ? 'CURAR'
                        : 'MEJORAR',
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: color, width: 2),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================
  // FUNCIÓN PARA LANZAR DADOS (SOLO VISUAL)
  // ============================================
  void _lanzarDados() {
    // Evitar lanzar si ya se lanzaron este turno
    if (_dadosLanzadosEsteTurno) return;

    _dadosLanzadosEsteTurno = true;

    // ============================================
    // 1. Guardar QUIÉN es el jugador actual AHORA
    // ============================================
    final int turnoActual = juego.turnoActual; // <-- CAPTURAMOS EL TURNO

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
          // ============================================
          // 2. Usar el turno que guardamos, NO el actual
          // ============================================
          final jugadorQueTiro =
              juego.jugadores[turnoActual]; // <-- USAMOS EL CAPTURADO
          jugadorQueTiro.puntosAcumulados += suma;

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(
          //       '🎲 +$suma ⚡ para ${jugadorQueTiro.civilizacion.nombre}',
          //     ),
          //     backgroundColor: Colors.green[700],
          //     duration: const Duration(seconds: 1),
          //   ),
          // );
        });
      }
    });
  }

  void _lanzarDadosIA() {
    // Evitar lanzar si ya se lanzaron este turno
    if (_dadosLanzadosEsteTurno) return;

    _dadosLanzadosEsteTurno = true;

    // Guardar el turno actual (que es el de la IA)
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
          // Sumar puntos al jugador de la IA
          final jugadorIA = juego.jugadores[turnoActual];
          jugadorIA.puntosAcumulados += suma;

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('🤖 IA +$suma ⚡'),
          //     backgroundColor: Colors.purple[700],
          //     duration: const Duration(seconds: 1),
          //   ),
          // );
        });

        // ============================================
        // 2. DESPUÉS DE LOS DADOS, LA IA TOMA DECISIONES
        // ============================================
        Future.delayed(const Duration(milliseconds: 500), () {
          _tomarDecisionIA();
        });
      }
    });
  }

  // ============================================
  // MODAL DE INVOCACIÓN (SIN PARÁMETROS)
  // ============================================
  void mostrarModalInvocacion(BuildContext context) {
    // ============================================
    // OBTENER DATOS DEL JUGADOR ACTUAL (TÚ)
    // ============================================
    final jugador = juego.jugadores[0];

    // ============================================
    // VALIDACIÓN 1: ¿Hay puntos suficientes?
    // ============================================
    if (jugador.puntosAcumulados <= 0) {
      _mostrarMensajeInvocacionFallida(
        context,
        '❌ No tenés puntos para invocar',
        Colors.red,
      );
      return;
    }

    // ============================================
    // VALIDACIÓN 2: ¿Hay espacio en el campo?
    // ============================================
    final bool tieneEspacio = jugador.guerrerosEnCampo.any(
      (gf) => gf.guerreroBase.id.isEmpty,
    );

    if (!tieneEspacio) {
      _mostrarMensajeInvocacionFallida(
        context,
        '❌ No hay espacio en el campo',
        Colors.red,
      );
      return;
    }

    // ============================================
    // IDENTIFICAR GUERREROS INVOCABLES
    // ============================================
    final Set<String> idsEnCampo =
        jugador.guerrerosEnCampo
            .where((gf) => gf.guerreroBase.id.isNotEmpty)
            .map((gf) => gf.guerreroBase.id)
            .toSet();

    final idPrincipal = '${jugador.civilizacion.id}_001';
    final principalEnCampo = idsEnCampo.contains(idPrincipal);

    // ============================================
    // FILTRAR GUERREROS INVOCABLES
    // ============================================
    final List<Map<String, dynamic>> guerrerosInvocables = [];

    for (var guerrero in jugador.guerrerosEnMano) {
      // Regla: No debe estar en campo
      if (idsEnCampo.contains(guerrero.id)) continue;

      // Regla: Si el principal no está en campo, solo él puede ser invocado
      if (!principalEnCampo && guerrero.id != idPrincipal) continue;

      // Regla: Debe tener puntos suficientes
      if (jugador.puntosAcumulados < guerrero.costoInvocacion) continue;

      // Si pasa todos los filtros, es invocable
      guerrerosInvocables.add({
        'id': guerrero.id,
        'nombre': guerrero.nombreId,
        'vida': guerrero.vida,
        'ataque': guerrero.ataque,
        'costo': guerrero.costoInvocacion,
        'imagenPath': guerrero.imagen,
      });
    }

    // ============================================
    // VALIDACIÓN 3: ¿Hay guerreros invocables?
    // ============================================
    if (guerrerosInvocables.isEmpty) {
      String mensaje;
      if (!principalEnCampo && jugador.puntosAcumulados > 0) {
        mensaje =
            '❌ No tenés suficientes puntos para invocar a tu guerrero principal';
      } else {
        mensaje = '❌ No tenés guerreros disponibles para invocar';
      }

      _mostrarMensajeInvocacionFallida(context, mensaje, Colors.red);
      return;
    }

    // ============================================
    // MOSTRAR MODAL CON LOS GUERREROS INVOCABLES
    // ============================================
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
              color: Colors.brown[800],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera con puntos
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
                        '⚡ INVOCAR GUERRERO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ],
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

                // Grid de guerreros invocables
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children:
                            guerrerosInvocables.map((guerrero) {
                              return GestureDetector(
                                onTap: () {
                                  _confirmarInvocacion(context, guerrero);
                                },
                                child: buildGuerreroCardYU(
                                  nombre: guerrero['nombre'],
                                  vida: guerrero['vida'],
                                  ataque: guerrero['ataque'],
                                  costo: guerrero['costo'],
                                  imagenPath: guerrero['imagenPath'],
                                  modoActual: _modoActual,
                                  isSelected: false,
                                  onTap: null,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),

                // Botón cancelar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // FUNCIÓN AUXILIAR PARA MENSAJES DE ERROR
  // ============================================
  void _mostrarMensajeInvocacionFallida(
    BuildContext context,
    String mensaje,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================
  // DIÁLOGO DE CONFIRMACIÓN (IGUAL QUE ANTES)
  // ============================================
  void _confirmarInvocacion(
    BuildContext context,
    Map<String, dynamic> guerrero,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.brown[800],
          title: const Text(
            '⚔️ ¿INVOCAR?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Estás seguro de invocar a ${guerrero['nombre']} por ${guerrero['costo']} ⚡?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed:
                  () => Navigator.pop(context), // Solo cierra confirmación
              child: const Text('NO', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                // ============================================
                // 1. Cerrar los diálogos
                // ============================================
                Navigator.pop(context); // Cierra confirmación
                Navigator.pop(context); // Cierra modal de invocación

                // ============================================
                // 2. Buscar el guerrero en la mano del jugador
                // ============================================
                final jugador = juego.jugadores[0]; // Vos
                final guerreroEnMano = jugador.guerrerosEnMano.firstWhere(
                  (g) => g.id == guerrero['id'],
                );

                // ============================================
                // 3. Buscar primer espacio disponible en campo
                // ============================================
                int posicionLibre = -1;
                for (int i = 0; i < jugador.guerrerosEnCampo.length; i++) {
                  if (jugador.guerrerosEnCampo[i].guerreroBase.id.isEmpty) {
                    posicionLibre = i;
                    break;
                  }
                }

                // Si no hay espacio (no debería pasar porque controlamos antes)
                if (posicionLibre == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ No hay espacio en el campo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // ============================================
                // 4. Crear el GuerreroField y agregarlo al campo
                // ============================================
                final nuevoGuerreroField = GuerreroField(
                  guerreroBase: guerreroEnMano,
                  vidaActual: guerreroEnMano.vida,
                  ataqueActual: guerreroEnMano.ataque,
                  posicion: posicionLibre,
                );

                // Reemplazar el espacio vacío
                jugador.guerrerosEnCampo[posicionLibre] = nuevoGuerreroField;

                // ============================================
                // 5. Quitar de la mano
                // ============================================
                jugador.guerrerosEnMano.removeWhere(
                  (g) => g.id == guerrero['id'],
                );

                // ============================================
                // 6. Restar puntos
                // ============================================
                jugador.puntosAcumulados -= int.parse(
                  guerrero['costo'].toString(),
                );

                // ============================================
                // 7. Actualizar UI
                // ============================================
                setState(() {});

                // ============================================
                // 8. Feedback visual
                // ============================================
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('✅ ${guerrero['nombre']} invocado!'),
                //     backgroundColor: Colors.green[700],
                //   ),
                // );
                _cambiarTurno();
              },
              child: const Text('SÍ', style: TextStyle(color: Colors.green)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.amber, width: 2),
          ),
        );
      },
    );
  }

  void _activarModoAtaque() {
    final jugador = juego.jugadores[0]; // TÚ

    // Verificar si hay guerreros que no hayan atacado
    final disponibles =
        jugador.guerrerosEnCampo
            .where((g) => !g.yaAtacoEsteTurno && g.guerreroBase.id.isNotEmpty)
            .toList();

    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No tenés guerreros disponibles para atacar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _modoActual = ModoAccion.atacar;
      _atacanteSeleccionado = null;
      _objetivosPosibles = [];
    });
  }

  void _seleccionarAtacante(GuerreroField atacante) {
    final oponente = juego.jugadores[1]; // ENEMIGO

    // Determinar objetivos posibles (guerreros enemigos vivos)
    final objetivos =
        oponente.guerrerosEnCampo
            .where((g) => g.guerreroBase.id.isNotEmpty)
            .toList();

    setState(() {
      _atacanteSeleccionado = atacante;
      _objetivosPosibles = objetivos;
      _modoActual = ModoAccion.atacarSeleccionando;
    });
  }

  void _ejecutarAtaque(dynamic objetivo) {
    final atacante = _atacanteSeleccionado!;
    final oponente = juego.jugadores[1]; // La IA es el jugador 1

    _mostrarAtaqueJugadorModal(
      atacante: atacante,
      defensor: objetivo,
      dano: atacante.ataqueActual,
      onComplete: () {
        setState(() {
          // ============================================
          // 1. EJECUTAR EL ATAQUE
          // ============================================
          if (objetivo is GuerreroField) {
            objetivo.vidaActual -= atacante.ataqueActual;

            if (objetivo.vidaActual <= 0) {
              final guerreroMuerto = objetivo.guerreroBase;
              oponente.guerrerosEnMano.add(guerreroMuerto);

              final indice = oponente.guerrerosEnCampo.indexOf(objetivo);
              oponente.guerrerosEnCampo[indice] = GuerreroField.vacio(
                posicion: indice,
              );
            }
          } else {
            oponente.monumentoEnCampo.vidaActual -= atacante.ataqueActual;
          }

          // Marcar atacante como usado
          atacante.yaAtacoEsteTurno = true;
        });

        // ============================================
        // 2. VERIFICAR SI QUEDAN ATAcANTES
        // ============================================
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            final quedanAtacantes = juego.jugadores[0].guerrerosEnCampo.any(
              (g) => !g.yaAtacoEsteTurno && g.guerreroBase.id.isNotEmpty,
            );

            if (!quedanAtacantes) {
              // ============================================
              // 3. SI NO QUEDAN, TERMINAR EL TURNO
              // ============================================
              print('🎯 No quedan atacantes - Cambiando turno');
              _modoActual = ModoAccion.normal;
              _atacanteSeleccionado = null;
              _objetivosPosibles = [];

              // Mostrar cartel de cambio de turno
              _cambiarTurno();
            } else {
              // Si quedan, seguir en modo ataque
              _modoActual = ModoAccion.atacar;
              _atacanteSeleccionado = null;
              _objetivosPosibles = [];

              // Opcional: mensaje recordatorio
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚔️ Podés seguir atacando con otro guerrero'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          });
        });
      },
    );
  }

  void _mostrarAtaqueJugadorModal({
    required GuerreroField atacante,
    required dynamic defensor,
    required int dano,
    required VoidCallback onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                colors: [Colors.blue[900]!, Colors.blue[700]!],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyan, width: 3),
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
                const Text(
                  '⚔️ TU ATAQUE ⚔️',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),

                // Atacante vs Defensor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Atacante (tú)
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.brown[300],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green, width: 2),
                            image: DecorationImage(
                              image: AssetImage(atacante.guerreroBase.imagen),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          atacante.guerreroBase.nombreId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '🗡️ ${atacante.ataqueActual}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // VS
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Defensor (enemigo)
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.brown[300],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  defensor is GuerreroField
                                      ? Colors.red
                                      : Colors.amber,
                              width: 2,
                            ),
                            image:
                                defensor is GuerreroField
                                    ? DecorationImage(
                                      image: AssetImage(
                                        defensor.guerreroBase.imagen,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              defensor is! GuerreroField
                                  ? const Center(
                                    child: Icon(
                                      Icons.account_balance,
                                      color: Colors.amber,
                                      size: 50,
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          defensor is GuerreroField
                              ? defensor.guerreroBase.nombreId
                              : 'MONUMENTO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '❤️ ${defensor is GuerreroField ? defensor.vidaActual : juego.jugadores[1].monumentoEnCampo.vidaActual}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Daño
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[900]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Text(
                    '-$dano ❤️',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Cerrar el modal después de 2 segundos y continuar
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        onComplete();
      }
    });
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
          _lanzarDados();
        } else {
          _ejecutarIA();
        }
      }
    });
  }

  void _cambiarTurno() {
    setState(() {
      juego.turnoActual = juego.turnoActual == 0 ? 1 : 0;

      // Resetear guerreros que atacaron
      juego.jugadores[juego.turnoActual].guerrerosEnCampo.forEach((gf) {
        gf.yaAtacoEsteTurno = false;
      });

      // Limpiar modos
      _modoActual = ModoAccion.normal;
      _atacanteSeleccionado = null;
      _objetivosPosibles = [];
      _guerreroSeleccionado = null;
      _dadosLanzadosEsteTurno = false;
    });

    // Mostrar cartel de cambio de turno (NO lanzar dados todavía)
    _mostrarCambioTurno();
  }

  // ============================================
  // FUNCIONES PARA EJECUTAR ACCIONES DE LA IA
  // ============================================
  void _mostrarAtaqueModal({
    required GuerreroField atacante,
    required dynamic defensor, // Puede ser GuerreroField o null (monumento)
    required int dano,
    required VoidCallback onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red[700]!, width: 3),
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
                const Text(
                  '⚔️ ATAQUE ⚔️',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),

                // Atacante vs Defensor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Atacante
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.brown[300],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green, width: 2),
                            image: DecorationImage(
                              image: AssetImage(atacante.guerreroBase.imagen),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          atacante.guerreroBase.nombreId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '🗡️ ${atacante.ataqueActual}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // VS
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Defensor
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.brown[300],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  defensor is GuerreroField
                                      ? Colors.red
                                      : Colors.amber,
                              width: 2,
                            ),
                            image:
                                defensor is GuerreroField
                                    ? DecorationImage(
                                      image: AssetImage(
                                        defensor.guerreroBase.imagen,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              defensor is! GuerreroField
                                  ? const Center(
                                    child: Icon(
                                      Icons.account_balance,
                                      color: Colors.amber,
                                      size: 50,
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          defensor is GuerreroField
                              ? defensor.guerreroBase.nombreId
                              : 'MONUMENTO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '❤️ ${defensor is GuerreroField ? defensor.vidaActual + dano : juego.jugadores[0].monumentoEnCampo.vidaActual + dano} → ❤️ ${defensor is GuerreroField ? defensor.vidaActual : juego.jugadores[0].monumentoEnCampo.vidaActual}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Daño
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[900]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Text(
                    '-$dano ❤️',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Resultado si murió
                if (defensor is GuerreroField && defensor.vidaActual <= 0)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '💀 GUERRERO ELIMINADO 💀',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    // Cerrar el modal después de 2 segundos y continuar
    Future.delayed(const Duration(seconds: 4), () {
      if (context.mounted) {
        Navigator.of(context).pop();
        onComplete();
      }
    });
  }

  void _tomarDecisionIA() {
    final ia = IAController(
      yo: juego.jugadores[1],
      enemigo: juego.jugadores[0],
      onInvocar: (guerrero) => _invocarIA(guerrero),
      onAtacar: (atacante, objetivo) => _atacarIA(atacante, objetivo),
      onAtacarMultiple:
          (atacantes) => _ejecutarAtaqueMultipleIA(atacantes, 0), // NUEVO
      onReconstruir: (puntos) => _reconstruirIA(puntos),
      onCurar: (guerrero, puntos) => _curarIA(guerrero, puntos),
      onMejorar: (guerrero, puntos) => _mejorarIA(guerrero, puntos),
      onPasarTurno: () => _cambiarTurno(),
    );

    ia.tomarDecision();
  }

  void _ejecutarAtaqueMultipleIA(List<GuerreroField> atacantes, int index) {
    if (index >= atacantes.length) {
      print('🤖 IA terminó de atacar con todos sus guerreros');
      _cambiarTurno();
      return;
    }

    final atacante = atacantes[index];
    final oponente = juego.jugadores[0];

    final enemigosVivos =
        oponente.guerrerosEnCampo
            .where((g) => g.guerreroBase.id.isNotEmpty)
            .toList();

    // Elegir objetivo
    dynamic objetivo;
    if (enemigosVivos.isNotEmpty) {
      enemigosVivos.sort((a, b) => a.vidaActual.compareTo(b.vidaActual));
      objetivo = enemigosVivos.first;
    } else {
      objetivo = null; // Monumento
    }

    // Guardar vida antes del ataque para mostrar en modal
    int vidaAntes =
        objetivo is GuerreroField
            ? objetivo.vidaActual
            : oponente.monumentoEnCampo.vidaActual;

    // Ejecutar ataque REAL
    setState(() {
      if (objetivo is GuerreroField) {
        objetivo.vidaActual -= atacante.ataqueActual;
      } else {
        oponente.monumentoEnCampo.vidaActual -= atacante.ataqueActual;
      }
      atacante.yaAtacoEsteTurno = true;
    });

    // Mostrar modal con el ataque
    _mostrarAtaqueModal(
      atacante: atacante,
      defensor: objetivo,
      dano: atacante.ataqueActual,
      onComplete: () {
        // Verificar si el defensor murió (solo si es guerrero)
        if (objetivo is GuerreroField && objetivo.vidaActual <= 0) {
          setState(() {
            final guerreroMuerto = objetivo.guerreroBase;
            oponente.guerrerosEnMano.add(guerreroMuerto);

            final indice = oponente.guerrerosEnCampo.indexOf(objetivo);
            oponente.guerrerosEnCampo[indice] = GuerreroField.vacio(
              posicion: indice,
            );
          });
        }

        // Siguiente atacante
        Future.delayed(const Duration(milliseconds: 500), () {
          _ejecutarAtaqueMultipleIA(atacantes, index + 1);
        });
      },
    );
  }

  void _invocarIA(Guerrero guerrero) {
    // Similar a la invocación manual pero sin modales
    setState(() {
      final jugadorIA = juego.jugadores[1]; // La IA es el jugador 1

      // Buscar espacio libre
      int posicionLibre = -1;
      for (int i = 0; i < jugadorIA.guerrerosEnCampo.length; i++) {
        if (jugadorIA.guerrerosEnCampo[i].guerreroBase.id.isEmpty) {
          posicionLibre = i;
          break;
        }
      }

      if (posicionLibre != -1) {
        // Crear el GuerreroField y colocarlo
        final nuevoGuerrero = GuerreroField(
          guerreroBase: guerrero,
          vidaActual: guerrero.vida,
          ataqueActual: guerrero.ataque,
          posicion: posicionLibre,
        );

        jugadorIA.guerrerosEnCampo[posicionLibre] = nuevoGuerrero;
        jugadorIA.guerrerosEnMano.removeWhere((g) => g.id == guerrero.id);
        jugadorIA.puntosAcumulados -= guerrero.costoInvocacion;

        print('🤖 IA invocó a ${guerrero.nombreId}');
      }
    });

    // Después de invocar, cambiar turno
    _cambiarTurno();
  }

  void _atacarIA(GuerreroField atacante, dynamic objetivo) {
    setState(() {
      final oponente = juego.jugadores[0]; // El humano

      if (objetivo is GuerreroField) {
        // Atacar guerrero
        objetivo.vidaActual -= atacante.ataqueActual;

        if (objetivo.vidaActual <= 0) {
          // El guerrero muere
          final guerreroMuerto = objetivo.guerreroBase;
          oponente.guerrerosEnMano.add(guerreroMuerto);

          final indice = oponente.guerrerosEnCampo.indexOf(objetivo);
          oponente.guerrerosEnCampo[indice] = GuerreroField.vacio(
            posicion: indice,
          );
        }
      } else {
        // Atacar monumento
        oponente.monumentoEnCampo.vidaActual -= atacante.ataqueActual;
      }

      atacante.yaAtacoEsteTurno = true;
    });

    // Verificar si quedan atacantes en la IA
    final quedanAtacantes = juego.jugadores[1].guerrerosEnCampo.any(
      (g) => !g.yaAtacoEsteTurno && g.guerreroBase.id.isNotEmpty,
    );

    if (!quedanAtacantes) {
      _cambiarTurno();
    }
    // Si quedan, la IA podría seguir atacando, pero por ahora cambiamos turno
  }

  void _reconstruirIA(int puntos) {
    setState(() {
      final jugadorIA = juego.jugadores[1];
      jugadorIA.monumentoEnCampo.vidaActual += puntos;
      jugadorIA.puntosAcumulados -= puntos;
    });
    //_cambiarTurno();
  }

  void _curarIA(GuerreroField guerrero, int puntos) {
    setState(() {
      guerrero.vidaActual += puntos;
      juego.jugadores[1].puntosAcumulados -= puntos;
    });
    //_cambiarTurno();
  }

  void _mejorarIA(GuerreroField guerrero, int puntos) {
    setState(() {
      guerrero.ataqueActual += puntos;
      juego.jugadores[1].puntosAcumulados -= puntos;
    });
    //_cambiarTurno();
  }

  void _ejecutarIA() {
    // Pequeño delay para que se sienta natural
    Future.delayed(const Duration(seconds: 1), () {
      print('🤖 Turno de la IA - Lanzando dados...');

      // ============================================
      // 1. LA IA TIRA DADOS (usa la misma función visual)
      // ============================================
      _lanzarDadosIA();
    });
  }
}
