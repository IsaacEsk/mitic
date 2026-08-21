import 'package:flutter/material.dart';
import '../services/guerrero_service.dart';
import '../models/guerrero_model.dart';
import '../models/civilizacion_model.dart';
import 'mitic2_screen.dart';

class SelectAliadosScreen extends StatefulWidget {
  final Civilizacion civilizacionSeleccionada;

  const SelectAliadosScreen({
    super.key,
    required this.civilizacionSeleccionada,
  });

  @override
  State<SelectAliadosScreen> createState() => _SelectAliadosScreenState();
}

class _SelectAliadosScreenState extends State<SelectAliadosScreen> {
  late Future<List<Guerrero>> _guerrerosFuture;
  late Future<Map<String, String>> _translationsFuture;

  List<Guerrero> _todosLosGuerreros = [];
  List<Guerrero> _guerrerosDisponibles = [];
  final List<Guerrero> _seleccionados = [];
  Map<String, String> _translations = {};
  bool _initialized = false;

  int get _maxAliados => 3;
  bool get _completo => _seleccionados.length == _maxAliados;

  @override
  void initState() {
    super.initState();
    _guerrerosFuture = GuerreroService.loadGuerreros();
    _translationsFuture = GuerreroService.loadTranslations('es');
  }

  void _seleccionarGuerrero(Guerrero guerrero) {
    if (_seleccionados.length >= _maxAliados) return;
    if (_seleccionados.contains(guerrero)) return;

    setState(() {
      _seleccionados.add(guerrero);
      _guerrerosDisponibles.remove(guerrero);
    });
  }

  void _deseleccionarGuerrero(Guerrero guerrero) {
    setState(() {
      _seleccionados.remove(guerrero);
      _guerrerosDisponibles.add(guerrero);
      _guerrerosDisponibles.sort(
        (a, b) => a.nombre(_translations).compareTo(b.nombre(_translations)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'SELECCIONA TUS ALIADOS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: FutureBuilder(
        future: Future.wait([_guerrerosFuture, _translationsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!_initialized) {
            _initialized = true;
            final guerreros = snapshot.data![0] as List<Guerrero>;
            final translations = snapshot.data![1] as Map<String, String>;

            final guerreroPrincipalId =
                '${widget.civilizacionSeleccionada.id}_001';

            // 👇 SEPARAR GUERRERO PRINCIPAL DEL RESTO
            final guerreroPrincipal = guerreros.firstWhere(
              (g) => g.id == guerreroPrincipalId,
              //orElse: () => null,
            );

            // 👇 TODOS LOS GUERREROS (INCLUYENDO PRINCIPAL) PARA USARLO EN EL BOTÓN
            _todosLosGuerreros = List.from(guerreros);

            // 👇 GUERREROS DISPONIBLES PARA SELECCIONAR (EXCLUYENDO PRINCIPAL)
            _guerrerosDisponibles =
                guerreros.where((g) => g.id != guerreroPrincipalId).toList();

            _translations = translations;

            print('🎯 Guerrero principal: ${guerreroPrincipal.nombreId}');
            print('📋 Disponibles: ${_guerrerosDisponibles.length}');
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[900]!, Colors.grey[600]!],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double ancho = constraints.maxWidth;

                // SI ES MÓVIL (ancho < 800), USAR LAYOUT VERTICAL
                if (ancho < 800) {
                  return _buildMobileLayout();
                } else {
                  return _buildDesktopLayout();
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // LAYOUT PARA ESCRITORIO (ancho >= 800)
  // ============================================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LADO IZQUIERDO: Grid de guerreros disponibles (70%)
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contador
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     vertical: 8,
                //     horizontal: 16,
                //   ),
                //   decoration: BoxDecoration(
                //     color: Colors.grey[800],
                //     borderRadius: BorderRadius.circular(30),
                //   ),
                //   child: Text(
                //     '${_seleccionados.length}/$_maxAliados seleccionados',
                //     style: const TextStyle(
                //       color: Colors.white,
                //       fontWeight: FontWeight.bold,
                //       fontSize: 16,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 16),
                // Grid de guerreros
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _guerrerosDisponibles.length,
                    itemBuilder: (context, index) {
                      final guerrero = _guerrerosDisponibles[index];
                      return _buildGuerreroCard(
                        guerrero,
                        onTap: () => _seleccionarGuerrero(guerrero),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // LADO DERECHO: Seleccionados y botón
        Container(
          width: 300,
          color: Colors.grey[200]?.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECCIONADOS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  _maxAliados,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSelectedSlot(index),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _completo
                            ? () {
                              final guerreroPrincipalId =
                                  '${widget.civilizacionSeleccionada.id}_001';

                              // 👇 BUSCAR EN LA LISTA COMPLETA (_todosLosGuerreros)
                              final guerreroPrincipal = _todosLosGuerreros
                                  .firstWhere(
                                    (g) => g.id == guerreroPrincipalId,
                                  );

                              final todosLosGuerreros = [
                                guerreroPrincipal,
                                ..._seleccionados,
                              ];

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => Mitic2Screen(
                                        civilizacionSeleccionada:
                                            widget.civilizacionSeleccionada,
                                        aliadosSeleccionados: todosLosGuerreros,
                                      ),
                                ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'SIGUIENTE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // LAYOUT PARA MÓVIL (ancho < 800)
  // ============================================
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Contador
        Padding(
          padding: const EdgeInsets.all(16),
          // child: Container(
          //   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[800],
          //     borderRadius: BorderRadius.circular(30),
          //   ),
          //   child: Text(
          //     '${_seleccionados.length}/$_maxAliados seleccionados',
          //     style: const TextStyle(
          //       color: Colors.white,
          //       fontWeight: FontWeight.bold,
          //       fontSize: 16,
          //     ),
          //   ),
          // ),
        ),
        // Grid de guerreros disponibles
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _guerrerosDisponibles.length,
              itemBuilder: (context, index) {
                final guerrero = _guerrerosDisponibles[index];
                return _buildGuerreroCard(
                  guerrero,
                  onTap: () => _seleccionarGuerrero(guerrero),
                );
              },
            ),
          ),
        ),
        // Área de seleccionados (scroll horizontal)
        Container(
          height: 130,
          color: Colors.grey[200]?.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECCIONADOS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        _maxAliados,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildMobileSelectedSlot(index),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Botón siguiente
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _completo
                      ? () {
                        final guerreroPrincipalId =
                            '${widget.civilizacionSeleccionada.id}_001';

                        // 👇 BUSCAR EN LA LISTA COMPLETA (_todosLosGuerreros)
                        final guerreroPrincipal = _todosLosGuerreros.firstWhere(
                          (g) => g.id == guerreroPrincipalId,
                        );

                        final todosLosGuerreros = [
                          guerreroPrincipal,
                          ..._seleccionados,
                        ];

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => Mitic2Screen(
                                  civilizacionSeleccionada:
                                      widget.civilizacionSeleccionada,
                                  aliadosSeleccionados: todosLosGuerreros,
                                ),
                          ),
                        );
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'SIGUIENTE',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Tarjeta para guerreros disponibles
  Widget _buildGuerreroCard(Guerrero guerrero, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            children: [
              // Imagen
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Container(
                    color: Colors.grey[200],
                    child: Image.asset(
                      guerrero.imagen,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stack) => Center(
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey[700],
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              // Nombre
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                color: Colors.grey[800]?.withValues(alpha: 0.8),
                child: Text(
                  guerrero.nombre(_translations),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Stats
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('❤️', guerrero.vida),
                    _buildStat('🗡️', guerrero.ataque),
                    _buildStat('⚡', guerrero.costoInvocacion),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Slot de seleccionado (escritorio)
  Widget _buildSelectedSlot(int index) {
    if (index < _seleccionados.length) {
      final guerrero = _seleccionados[index];
      return GestureDetector(
        onTap: () => _deseleccionarGuerrero(guerrero),
        child: Container(
          width: double.infinity,
          height: 100,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[600]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                  child: Image.asset(
                    guerrero.imagen,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stack) => Center(
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[700],
                          ),
                        ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guerrero.nombre(_translations),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildMiniStat('❤️', guerrero.vida, large: true),
                          const SizedBox(width: 8),
                          _buildMiniStat('🗡️', guerrero.ataque, large: true),
                          const SizedBox(width: 8),
                          _buildMiniStat(
                            '⚡',
                            guerrero.costoInvocacion,
                            large: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 100,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300]?.withValues(alpha: 0.2),
          border: Border.all(color: Colors.grey[400]!, width: 2),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.grey, size: 40),
              SizedBox(height: 4),
              Text('Vacío', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
  }

  // Slot de seleccionado (móvil)
  // Slot de seleccionado (móvil) - SIN STATS
  Widget _buildMobileSelectedSlot(int index) {
    if (index < _seleccionados.length) {
      final guerrero = _seleccionados[index];
      return GestureDetector(
        onTap: () => _deseleccionarGuerrero(guerrero),
        child: Container(
          width: 80,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[600]!, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    guerrero.imagen,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stack) => Center(
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey[700],
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Nombre abreviado (sin stats)
              Text(
                guerrero.nombre(_translations).length > 10
                    ? '${guerrero.nombre(_translations).substring(0, 10)}...'
                    : guerrero.nombre(_translations),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    } else {
      // Slot vacío
      return Container(
        width: 80,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300]?.withValues(alpha: 0.2),
          border: Border.all(color: Colors.grey[400]!, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.grey, size: 30),
        ),
      );
    }
  }

  Widget _buildMiniStat(String icon, int value, {bool large = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: large ? 12 : 10)),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: large ? 11 : 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String icon, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
