import 'package:flutter/material.dart';
import '../models/civilizacion_model.dart';
import '../models/guerrero_model.dart';
import '../services/guerrero_service.dart';

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
  List<Guerrero> _seleccionados = [];
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
      appBar: AppBar(
        title: const Text(
          'SELECCIONA TUS ALIADOS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.brown[800],
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
            _todosLosGuerreros =
                guerreros.where((g) => g.id != guerreroPrincipalId).toList();
            _guerrerosDisponibles = List.from(_todosLosGuerreros);
            _translations = translations;
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.brown[100]!, Colors.amber[50]!],
              ),
            ),
            // 🔥 SOLUCIÓN B: LayoutBuilder + Scroll automático
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minWidth = 1000.0;
                const minHeight = 700.0;

                final needsHorizontalScroll = constraints.maxWidth < minWidth;
                final needsVerticalScroll = constraints.maxHeight < minHeight;

                Widget content = Container(
                  constraints: const BoxConstraints(
                    minWidth: minWidth,
                    minHeight: minHeight,
                  ),
                  child: Row(
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
                              // Contador en la parte superior izquierda
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.brown[800],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  '${_seleccionados.length}/$_maxAliados seleccionados',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                    final guerrero =
                                        _guerrerosDisponibles[index];
                                    return _buildGuerreroCard(
                                      guerrero,
                                      onTap:
                                          () => _seleccionarGuerrero(guerrero),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // LADO DERECHO: Seleccionados y botón (fijo 300px)
                      Container(
                        width: 300,
                        color: Colors.brown[200]?.withOpacity(0.5),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SELECCIONADOS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Slots de seleccionados verticales
                              ...List.generate(
                                _maxAliados,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildSelectedSlot(index),
                                ),
                              ),
                              const Spacer(),
                              // Botón siguiente
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _completo
                                          ? () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '¡Equipo completo! ${_seleccionados.length} aliados',
                                                ),
                                                backgroundColor:
                                                    Colors.green[700],
                                              ),
                                            );
                                          }
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown[800],
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[400],
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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
                  ),
                );

                // Aplicar scroll si es necesario
                if (needsHorizontalScroll || needsVerticalScroll) {
                  return Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: content,
                      ),
                    ),
                  );
                }

                return Center(child: content);
              },
            ),
          );
        },
      ),
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
              colors: [Colors.white, Colors.brown[50]!],
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
                    color: Colors.brown[200],
                    child: Image.asset(
                      guerrero.imagen,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stack) => Center(
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.brown[700],
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
                color: Colors.brown[800]?.withOpacity(0.8),
                child: Text(
                  guerrero.nombre(_translations),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Stats
              Padding(
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('❤️', guerrero.vida.toString()),
                    _buildStat('🗡️', guerrero.ataque.toString()),
                    _buildStat('⚡', guerrero.costoInvocacion.toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Slot de seleccionado (vertical)
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
            color: Colors.brown[100],
            border: Border.all(color: Colors.brown[600]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Mini imagen
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                  color: Colors.brown[300],
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
                            color: Colors.brown[700],
                          ),
                        ),
                  ),
                ),
              ),
              // Nombre y stats
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
                          _buildMiniStat(
                            '❤️',
                            guerrero.vida.toString(),
                            large: true,
                          ),
                          const SizedBox(width: 8),
                          _buildMiniStat(
                            '🗡️',
                            guerrero.ataque.toString(),
                            large: true,
                          ),
                          const SizedBox(width: 8),
                          _buildMiniStat(
                            '⚡',
                            guerrero.costoInvocacion.toString(),
                            large: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.brown[200],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.7,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.brown[600],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
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
      // Slot vacío
      return Container(
        width: double.infinity,
        height: 100,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.brown[300]?.withOpacity(0.2),
          border: Border.all(
            color: Colors.brown[400]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.brown, size: 40),
              const SizedBox(height: 4),
              Text(
                'Vacío',
                style: TextStyle(fontSize: 12, color: Colors.brown[600]),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMiniStat(String icon, String value, {bool large = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.brown[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: large ? 14 : 10)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 13 : 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 1),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
