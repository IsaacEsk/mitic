import 'package:flutter/material.dart';
import '../models/civilizacion_model.dart';
import '../models/guerrero_model.dart';
import '../services/civilizacion_service.dart';
import '../services/guerrero_service.dart';
import '../screens/select_aliados_screen.dart';

class SelectCivScreen extends StatefulWidget {
  const SelectCivScreen({super.key});

  @override
  State<SelectCivScreen> createState() => _SelectCivScreenState();
}

class _SelectCivScreenState extends State<SelectCivScreen> {
  late Future<List<Civilizacion>> _civilizacionesFuture;
  late Future<Map<String, String>> _translationsFuture;
  late Future<List<Guerrero>> _guerrerosFuture;

  Civilizacion? _selectedCiv;
  Guerrero? _selectedGuerrero;
  Map<String, String> _translations = {};
  bool _initialized = false; // Flag para evitar ciclo de reconstrucciones

  @override
  void initState() {
    super.initState();
    _civilizacionesFuture = CivilizacionService.loadCivilizaciones();
    _translationsFuture = CivilizacionService.loadTranslations('es');
    _guerrerosFuture = GuerreroService.loadGuerreros();
  }

  void _onCivSelected(Civilizacion civ, List<Guerrero> guerreros) {
    // Buscar el guerrero principal (asumimos que el id termina en '_001')
    final guerrero = guerreros.firstWhere(
      (g) => g.id.startsWith(civ.id),
      orElse: () => guerreros.first,
    );

    setState(() {
      _selectedCiv = civ;
      _selectedGuerrero = guerrero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SELECCIONA TU CIVILIZACIÓN',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: FutureBuilder(
        future: Future.wait([
          _civilizacionesFuture,
          _translationsFuture,
          _guerrerosFuture,
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final civilizaciones = snapshot.data![0] as List<Civilizacion>;
          final translations = snapshot.data![1] as Map<String, String>;
          final guerreros = snapshot.data![2] as List<Guerrero>;

          // Inicializar solo una vez
          if (!_initialized) {
            _initialized = true;
            _translations = translations;

            // Si no hay selección, seleccionar la primera por defecto
            if (_selectedCiv == null && civilizaciones.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onCivSelected(civilizaciones.first, guerreros);
              });
            }
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.brown[100]!, Colors.amber[50]!],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Si el ancho es menor a 600, apilamos verticalmente
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      // Lista horizontal superior
                      Container(
                        height: 100,
                        color: Colors.brown[200],
                        child: _buildHorizontalList(civilizaciones, guerreros),
                      ),
                      // Panel detalle abajo
                      Expanded(child: _buildDetailPanel()),
                    ],
                  );
                } else {
                  // Vista normal: lista izquierda + detalle derecho
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lista vertical izquierda (30%)
                      Container(
                        width: constraints.maxWidth * 0.3,
                        child: _buildVerticalList(civilizaciones, guerreros),
                      ),
                      // Panel detalle derecho (70%)
                      Expanded(child: _buildDetailPanel()),
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Lista vertical para desktop/tablet
  Widget _buildVerticalList(
    List<Civilizacion> civilizaciones,
    List<Guerrero> guerreros,
  ) {
    return Container(
      color: Colors.brown[800]?.withOpacity(0.1),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: civilizaciones.length,
        itemBuilder: (context, index) {
          final civ = civilizaciones[index];
          final isSelected = _selectedCiv?.id == civ.id;

          return Card(
            elevation: isSelected ? 8 : 2,
            color: isSelected ? Colors.brown[200] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? Colors.brown[800]! : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              title: Text(
                civ.nombre,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              onTap: () => _onCivSelected(civ, guerreros),
            ),
          );
        },
      ),
    );
  }

  // Lista horizontal para móvil
  Widget _buildHorizontalList(
    List<Civilizacion> civilizaciones,
    List<Guerrero> guerreros,
  ) {
    return Container(
      color: Colors.brown[800]?.withValues(alpha: 0.1),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: civilizaciones.length,
        itemBuilder: (context, index) {
          final civ = civilizaciones[index];
          final isSelected = _selectedCiv?.id == civ.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Card(
              elevation: isSelected ? 8 : 2,
              color: isSelected ? Colors.brown[200] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.brown[800]! : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => _onCivSelected(civ, guerreros),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Text(
                    civ.nombre,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Panel de detalle derecho/inferior
  Widget _buildDetailPanel() {
    if (_selectedCiv == null || _selectedGuerrero == null) {
      return const Center(child: Text('Selecciona una civilización'));
    }

    final civ = _selectedCiv!;
    final guerrero = _selectedGuerrero!;
    final muralla = civ.muralla;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la civilización seleccionada
          // Center(
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          //     decoration: BoxDecoration(
          //       color: Colors.brown[800],
          //       borderRadius: BorderRadius.circular(30),
          //     ),
          //     child: Text(
          //       civ.nombre.toUpperCase(),
          //       style: const TextStyle(
          //         fontSize: 24,
          //         fontWeight: FontWeight.bold,
          //         color: Colors.white,
          //         letterSpacing: 2,
          //       ),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 2),

          // MONUMENTO: Foto + Info lado a lado
          // MONUMENTO: Foto con ancho fijo y texto adaptativo
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del monumento con ANCHO FIJO (120px)
                  Container(
                    width: 320,
                    height: 360,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.brown[200],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          muralla.imagen.isEmpty
                              ? Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.brown[700],
                                ),
                              )
                              : Image.asset(
                                'assets/${muralla.imagen}',
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                        color: Colors.brown[700],
                                      ),
                                    ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info del monumento - EXPANDIDA al resto del espacio
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          muralla.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Vida
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('❤️', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text(
                                muralla.vida.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Descripción
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.brown[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DESC',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _translations[muralla.descripcionId] ??
                                    muralla.descripcionId,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Habilidad
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber[300]!),
                          ),
                          child: Row(
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _translations[civ.habilidadEspecialId] ??
                                      civ.habilidadEspecialId,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // GUERRERO: Foto + Info lado a lado
          // GUERRERO: Foto con ancho fijo y texto adaptativo
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.brown[50]!, Colors.amber[50]!],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del guerrero con ANCHO FIJO (120px)
                    Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.brown[200],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            guerrero.imagen.isEmpty
                                ? Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.brown[700],
                                  ),
                                )
                                : Image.asset(
                                  guerrero.imagen,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Center(
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.brown[700],
                                        ),
                                      ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info del guerrero - EXPANDIDA al resto del espacio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guerrero.nombre(_translations),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Stats en fila
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildStatChip('❤️', guerrero.vida.toString()),
                              _buildStatChip('🗡️', guerrero.ataque.toString()),
                              _buildStatChip(
                                '⚡',
                                guerrero.costoInvocacion.toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Descripción
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.brown[200]!),
                            ),
                            child: Text(
                              guerrero.descripcion(_translations),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Botón de seleccionar
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Aquí navegas a la pantalla de selección de aliados o tablero
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${civ.nombre} seleccionada'),
                    backgroundColor: Colors.brown[800],
                  ),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SelectAliadosScreen(civilizacionSeleccionada: civ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'SELECCIONAR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
