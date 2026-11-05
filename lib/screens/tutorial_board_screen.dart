import 'package:flutter/material.dart';
import 'package:mitic/models/aldeano_model.dart';
import 'package:mitic/models/civilizacion_model.dart';
import 'package:mitic/models/cultivo_model.dart';
import 'package:mitic/services/mitic2_data_service.dart';
import 'package:mitic/services/translationService.dart';
import 'package:mitic/widgets/monumento_tablero.dart';

class TutorialBoardScreen extends StatefulWidget {
  final String selectedLanguage;

  const TutorialBoardScreen({super.key, required this.selectedLanguage});

  @override
  State<TutorialBoardScreen> createState() => _TutorialBoardScreenState();
}

class _TutorialBoardScreenState extends State<TutorialBoardScreen> {
  static const _gold = Color(0xFFFFC857);
  static const _tutorialDieOne = 1;
  static const _tutorialDieTwo = 3;
  static const _opponentDieOne = 6;
  static const _opponentDieTwo = 6;
  static const _nextOpponentDieOne = 4;
  static const _nextOpponentDieTwo = 5;
  static const _nextPlayerDieOne = 4;
  static const _nextPlayerDieTwo = 1;
  static const _playerTurnDieOne = 6;
  static const _playerTurnDieTwo = 5;
  static const _opponentCropCount = 4;
  static const _opponentCropProductionUpgrade = 4;
  static const _opponentUpgradeDelay = Duration(milliseconds: 600);
  static const _opponentCivilizationId = 'azteca';
  static const _playerCivilizationId = 'maya';
  static const _opponentCropId = 'cultivo_azteca';
  static const _playerCropId = 'cultivo_maya';
  static const _playerVillagerId = 'aldeano_maya';

  int _playerPoints = 0;
  int _opponentPoints = 0;
  bool _diceTutorialShown = false;
  bool _cropSummoningEnabled = false;
  bool _cropUpgradeInProgress = false;
  bool _passButtonUnlocked = false;
  bool _opponentTurnComplete = false;
  bool _opponentTurnInProgress = false;
  bool _playerCropHarvestAnimating = false;
  bool _opponentCropHarvestAnimating = false;
  bool _villagerHammerAnimating = false;
  bool _cropHarvestInProgress = false;
  int? _playerMonumentHealth;
  final Set<int> _invokedPlayerCropColumns = {};
  final Map<int, int> _playerCropHealth = {};
  final Map<int, int> _playerCropProduction = {};
  final Map<int, int> _opponentCropProduction = {};
  bool _additionalCropSummoningEnabled = false;
  bool _villagerSummoningEnabled = false;
  bool _villagerSummoned = false;
  bool _villagerMoveTargetEnabled = false;
  bool _villagerMoved = false;
  bool _villagerInstructionsShown = false;

  late final Future<Map<String, String>> _translations =
      TranslationService.loadTranslations(widget.selectedLanguage);
  late final Future<_TutorialBoardData> _boardData = _loadBoardData();

  Future<_TutorialBoardData> _loadBoardData() async {
    final translations = await _translations;
    if (translations.isEmpty) {
      throw StateError('No se pudieron cargar las traducciones.');
    }

    final loadedData = await Mitic2DataService.cargarTodo(
      locale: widget.selectedLanguage,
    );
    final civilizations = loadedData['civilizaciones'];
    final crops = await Mitic2DataService.cargarCultivos();
    final villagers = await Mitic2DataService.cargarAldeanos();
    if (civilizations is! Map<String, Civilizacion>) {
      throw StateError('No se pudieron cargar los datos del tutorial.');
    }

    final opponentCivilization = civilizations[_opponentCivilizationId];
    final playerCivilization = civilizations[_playerCivilizationId];
    final opponentCrop = crops[_opponentCropId];
    final playerCrop = crops[_playerCropId];
    final playerVillager = villagers[_playerVillagerId];
    if (opponentCivilization == null ||
        playerCivilization == null ||
        opponentCrop == null ||
        playerCrop == null ||
        playerVillager == null) {
      throw StateError('Faltan datos del tablero del tutorial.');
    }

    return _TutorialBoardData(
      translations: translations,
      opponentCivilization: opponentCivilization,
      playerCivilization: playerCivilization,
      opponentCrop: opponentCrop,
      playerCrop: playerCrop,
      playerVillager: playerVillager,
    );
  }

  Future<void> _showCropUpgradeInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_crop_upgrade_title',
              'Mejora tu cultivo',
            ),
            message: _text(
              data,
              'tutorial_crop_upgrade_explanation',
              'Toca el cultivo para mejorar su producción o reconstruir su vida. Cuanta más producción tenga, más puntos acumularás en tu siguiente turno.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  String _text(_TutorialBoardData data, String key, String spanishFallback) =>
      data.translations[key] ?? spanishFallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TutorialBoardData>(
      future: _boardData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FutureBuilder<Map<String, String>>(
            future: _translations,
            builder: (context, translationsSnapshot) {
              final translations = translationsSnapshot.data ?? const {};
              final message =
                  translations['tutorial_board_load_error'] ??
                  'No se pudo cargar el tutorial: {error}';
              return Scaffold(
                backgroundColor: Colors.grey[900],
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      message.replaceAll('{error}', snapshot.error.toString()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              );
            },
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.grey,
            body: Center(child: CircularProgressIndicator(color: _gold)),
          );
        }
        return _buildBoardScreen(context, snapshot.data!);
      },
    );
  }

  Widget _buildBoardScreen(BuildContext context, _TutorialBoardData data) {
    _showDiceTutorial(data);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(_text(data, 'tutorial_board_title', 'Cómo jugar')),
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: _text(data, 'tutorial_boton_atras', 'Atrás'),
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              Text(
                _text(
                  data,
                  'tutorial_board_intro',
                  'El tablero se divide entre dos jugadores. Cada uno protege su monumento y ocupa las casillas para crear su estrategia.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _text(
                  data,
                  'tutorial_board_goal',
                  'Tu objetivo es destruir el monumento rival mientras defiendes el tuyo.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSide = [
                      constraints.maxWidth / 5,
                      constraints.maxHeight / 9.2,
                    ].reduce((a, b) => a < b ? a : b);

                    return Center(
                      child: SizedBox(
                        width: cellSide * 5,
                        height: cellSide * 9.2,
                        child: Column(
                          children: [
                            _buildStatsRow(
                              cellSide,
                              _text(data, 'tutorial_player_2', 'Jugador 2'),
                              data.opponentCivilization,
                              data,
                              points: _opponentPoints,
                              showPassButton: false,
                              pointsKey: const ValueKey(
                                'tutorial-opponent-points',
                              ),
                            ),
                            ...List.generate(
                              4,
                              (row) => _buildBoardRow(
                                cellSide,
                                row: row,
                                isTop: true,
                                civilization: data.opponentCivilization,
                                data: data,
                              ),
                            ),
                            SizedBox(
                              height: cellSide * 0.2,
                              child: Center(
                                child: Text(
                                  '${_text(data, 'tutorial_board_turn', 'TURNO')} 1',
                                  style: TextStyle(
                                    color: _gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: cellSide * 0.1,
                                  ),
                                ),
                              ),
                            ),
                            ...List.generate(
                              4,
                              (row) => _buildBoardRow(
                                cellSide,
                                row: row,
                                isTop: false,
                                civilization: data.playerCivilization,
                                data: data,
                              ),
                            ),
                            _buildStatsRow(
                              cellSide,
                              _text(data, 'tutorial_player_1', 'Jugador 1'),
                              data.playerCivilization,
                              data,
                              points: _playerPoints,
                              showPassButton: _passButtonUnlocked,
                              pointsKey: const ValueKey(
                                'tutorial-player-points',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    double cellSide,
    String label,
    Civilizacion civilization,
    _TutorialBoardData data, {
    required int points,
    required bool showPassButton,
    required Key pointsKey,
  }) {
    final civilizationName =
        data.translations[civilization.nombreId] ?? civilization.nombreId;
    return SizedBox(
      height: cellSide * 0.5,
      child: Row(
        children: [
          Container(
            width: cellSide * 2,
            height: cellSide * 0.5,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.circle_outlined,
                  color: Colors.white54,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$label · $civilizationName',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: cellSide * 0.13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: cellSide * 2,
            height: cellSide * 0.5,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: _gold, size: cellSide * 0.16),
                  const SizedBox(width: 4),
                  Text(
                    key: pointsKey,
                    '$points',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: cellSide * 0.16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showPassButton)
            Container(
              width: cellSide,
              height: cellSide * 0.5,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Center(
                child: ElevatedButton(
                  key: const ValueKey('tutorial-pass-turn'),
                  onPressed: () => _passTurn(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black87,
                    minimumSize: Size(cellSide * 0.9, cellSide * 0.3),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    _text(data, 'pasar', 'PASAR'),
                    style: TextStyle(
                      fontSize: cellSide * 0.12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(width: cellSide, height: cellSide * 0.5),
        ],
      ),
    );
  }

  Widget _buildBoardRow(
    double cellSide, {
    required int row,
    required bool isTop,
    required Civilizacion civilization,
    required _TutorialBoardData data,
  }) {
    final isMonumentRow = isTop ? row == 0 : row == 3;
    return SizedBox(
      height: cellSide,
      child: Row(
        children: List.generate(5, (column) {
          if (isMonumentRow && column == 2) {
            return MonumentoTablero(
              key:
                  isTop
                      ? const ValueKey('tutorial-opponent-monument')
                      : const ValueKey('tutorial-player-monument'),
              ladoCelda: cellSide,
              imagenPath: civilization.muralla.imagen,
              vida:
                  !isTop
                      ? _playerMonumentHealth ?? civilization.muralla.vida
                      : civilization.muralla.vida,
              onTap: () {},
            );
          }
          if (isTop && isMonumentRow && _opponentTurnComplete) {
            return _buildCropCell(
              cellSide,
              data.opponentCrop,
              data,
              key: ValueKey('tutorial-opponent-crop-$column'),
              interactive: false,
              harvestAnimating: _opponentCropHarvestAnimating,
              animationKey: ValueKey('tutorial-opponent-crop-harvest-$column'),
              productionKey: ValueKey(
                'tutorial-opponent-crop-production-$column',
              ),
              productionOverride:
                  _opponentCropProduction[column] ??
                  data.opponentCrop.puntosPorTurno,
            );
          }
          if (!isTop &&
              _villagerSummoned &&
              ((!_villagerMoved && row == 2 && column == 2) ||
                  (_villagerMoved && row == 3 && column == 0))) {
            return _buildVillagerCell(
              cellSide,
              data,
              interactive: !_villagerMoved && !_villagerMoveTargetEnabled,
            );
          }
          if (!isTop && row == 3 && column == 0 && _villagerMoveTargetEnabled) {
            return _buildVillagerMoveTargetCell(cellSide);
          }
          if (!isTop && row == 2 && column == 2) {
            if (_villagerSummoningEnabled) {
              return _buildVillagerSummonCell(cellSide, data);
            }
          }
          if (!isTop &&
              isMonumentRow &&
              column != 2 &&
              (column == 1 || column == 3 || column == 4)) {
            if (_invokedPlayerCropColumns.contains(column)) {
              return _buildCropCell(
                cellSide,
                data.playerCrop,
                data,
                key:
                    column == 1
                        ? const ValueKey('tutorial-crop-piece')
                        : ValueKey('tutorial-player-crop-$column'),
                productionKey: ValueKey('tutorial-player-crop-health-$column'),
                column: column,
              );
            }
            final canSummon =
                column == 1
                    ? _cropSummoningEnabled
                    : _additionalCropSummoningEnabled;
            if (canSummon) {
              return _buildCropSummonCell(cellSide, data, column);
            }
          }
          return _buildEmptyCell(cellSide);
        }),
      ),
    );
  }

  Widget _buildCropSummonCell(
    double cellSide,
    _TutorialBoardData data,
    int column,
  ) {
    return SizedBox(
      width: cellSide,
      height: cellSide,
      child: Tooltip(
        message: _text(data, 'tutorial_summon_crop_button', 'Invocar cultivo'),
        child: Padding(
          padding: EdgeInsets.all(cellSide * 0.05),
          child: ElevatedButton(
            key: ValueKey('tutorial-summon-crop-$column'),
            onPressed: () => _showCropInvocationDialog(data, column),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[700],
              elevation: 4,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cellSide * 0.05),
              ),
            ),
            child: Icon(Icons.add, size: cellSide * 0.36),
          ),
        ),
      ),
    );
  }

  Widget _buildVillagerSummonCell(double cellSide, _TutorialBoardData data) {
    return SizedBox(
      width: cellSide,
      height: cellSide,
      child: Tooltip(
        message: _text(
          data,
          'tutorial_summon_villager_button',
          'Invocar aldeano',
        ),
        child: Padding(
          padding: EdgeInsets.all(cellSide * 0.05),
          child: ElevatedButton(
            key: const ValueKey('tutorial-summon-villager'),
            onPressed: () => _showVillagerInvocationDialog(data),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[700],
              elevation: 4,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cellSide * 0.05),
              ),
            ),
            child: Icon(Icons.add, size: cellSide * 0.36),
          ),
        ),
      ),
    );
  }

  Widget _buildVillagerCell(
    double cellSide,
    _TutorialBoardData data, {
    required bool interactive,
  }) {
    final villager = data.playerVillager;
    final statHeight = cellSide * 0.25;
    return InkWell(
      onTap: interactive ? () => _showVillagerOptionsDialog(data) : null,
      child: SizedBox(
        key: const ValueKey('tutorial-villager-piece'),
        width: cellSide,
        height: cellSide,
        child: Padding(
          padding: EdgeInsets.all(cellSide * 0.05),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cellSide * 0.08),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: cellSide * 0.05,
                  left: cellSide * 0.05,
                  child: AnimatedContainer(
                    key: const ValueKey('tutorial-villager-hammer-animation'),
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOutBack,
                    width:
                        cellSide * 0.9 * (_villagerHammerAnimating ? 0.5 : 1),
                    height:
                        cellSide * 0.9 * (_villagerHammerAnimating ? 0.5 : 1),
                    decoration: BoxDecoration(
                      color: Colors.brown[600],
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(villager.imagen),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: statHeight,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.72),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '🔨 ${villager.puntosReconstruccion}   👨 ${villager.vida}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: statHeight * 0.48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVillagerMoveTargetCell(double cellSide) {
    return GestureDetector(
      key: const ValueKey('tutorial-villager-move-target'),
      onTap: () {
        if (!_villagerMoveTargetEnabled || !mounted) return;
        setState(() {
          _villagerMoved = true;
          _villagerMoveTargetEnabled = false;
          _passButtonUnlocked = true;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: cellSide,
        height: cellSide,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.3),
          border: Border.all(color: _gold, width: 4),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.65),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.touch_app,
          color: Colors.white,
          size: cellSide * 0.36,
        ),
      ),
    );
  }

  Widget _buildEmptyCell(double cellSide) {
    return Container(
      width: cellSide,
      height: cellSide,
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        border: Border.all(color: const Color(0xFF303030)),
      ),
    );
  }

  Widget _buildCropCell(
    double cellSide,
    Cultivo crop,
    _TutorialBoardData data, {
    Key? key,
    Key? animationKey,
    Key? productionKey,
    bool interactive = true,
    bool? harvestAnimating,
    int? productionOverride,
    int? column,
  }) {
    final imageSize = cellSide * 0.9;
    final imageMargin = (cellSide - imageSize) / 2;
    final statHeight = cellSide * 0.25;
    final production =
        productionOverride ??
        (column == null
            ? crop.puntosPorTurno
            : _playerCropProduction[column] ?? crop.puntosPorTurno);
    final health =
        column == null ? crop.vida : _playerCropHealth[column] ?? crop.vida;
    final isHarvestAnimating =
        harvestAnimating ?? (interactive && _playerCropHarvestAnimating);
    return GestureDetector(
      key: key ?? const ValueKey('tutorial-crop-piece'),
      behavior: HitTestBehavior.opaque,
      onTap:
          !interactive || _cropUpgradeInProgress || _cropHarvestInProgress
              ? null
              : () => _showCropOptionsDialog(crop, data, column ?? 1),
      child: SizedBox(
        width: cellSide,
        height: cellSide,
        child: Stack(
          children: [
            Positioned(
              top: imageMargin,
              left: imageMargin,
              child: AnimatedContainer(
                key:
                    animationKey ??
                    (interactive
                        ? const ValueKey('tutorial-player-crop-harvest')
                        : null),
                duration: const Duration(milliseconds: 500),
                constraints: BoxConstraints.tightFor(
                  width: imageSize * (isHarvestAnimating ? 1.1 : 1),
                  height: imageSize * (isHarvestAnimating ? 1.1 : 1),
                ),
                curve: Curves.easeOutBack,
                decoration: BoxDecoration(
                  color: Colors.brown[600],
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(crop.imagen),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: statHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    key: productionKey,
                    '🌾 $production   ❤️ $health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: statHeight * 0.48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCropOptionsDialog(
    Cultivo crop,
    _TutorialBoardData data,
    int column,
  ) async {
    if (_playerCropProduction.isEmpty ||
        _playerPoints <= 0 ||
        _cropUpgradeInProgress) {
      return;
    }
    final selectedUpgrade = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => Dialog(
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
                border: Border.all(color: _gold, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌾', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 8),
                      Text(
                        _text(data, 'modal_cultivo', 'CULTIVO'),
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.brown[300],
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: AssetImage(crop.imagen),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _buildCropUpgradeStat(
                              _text(data, 'puntos_turno', 'Puntos/turno:'),
                              _playerCropProduction[column] ??
                                  crop.puntosPorTurno,
                              '🌾',
                              Colors.green,
                            ),
                            const SizedBox(height: 4),
                            _buildCropUpgradeStat(
                              _text(data, 'vida', 'Vida:'),
                              _playerCropHealth[column] ?? crop.vida,
                              '🌱',
                              Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber[800]?.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.flash_on,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_playerPoints ${_text(data, 'puntos_disponibles', 'puntos disponibles')}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropUpgradeAction(
                          dialogContext,
                          title: _text(
                            data,
                            'mejorar_produccion',
                            'MEJORAR PRODUCCIÓN',
                          ),
                          icon: '🌾',
                          color: Colors.green,
                          value: 'production',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCropUpgradeAction(
                          dialogContext,
                          title: _text(data, 'reconstruir', 'RECONSTRUIR'),
                          icon: '🌱',
                          color: Colors.blue,
                          value: 'health',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      _text(data, 'cancelar', 'CANCELAR'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    if (selectedUpgrade == null || !mounted) return;
    await _showCropUpgradePointsDialog(selectedUpgrade, data, column);
  }

  Widget _buildCropUpgradeAction(
    BuildContext dialogContext, {
    required String title,
    required String icon,
    required Color color,
    required String value,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(dialogContext, value),
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
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropUpgradeStat(
    String label,
    int value,
    String icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '$icon $label',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _showCropUpgradePointsDialog(
    String upgrade,
    _TutorialBoardData data,
    int column,
  ) async {
    final currentValue =
        upgrade == 'production'
            ? _playerCropProduction[column] ?? data.playerCrop.puntosPorTurno
            : _playerCropHealth[column] ?? data.playerCrop.vida;
    final production = upgrade == 'production';
    final pointsToSpend = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        var selectedPoints = 1.0;
        return StatefulBuilder(
          builder:
              (context, setDialogState) => Dialog(
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
                        '${production ? '🌾' : '🌱'} ${_text(data, production ? 'mejorar_produccion' : 'reconstruir', production ? 'MEJORAR PRODUCCIÓN' : 'RECONSTRUIR')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_text(data, 'valor_actual', 'Valor actual:')} $currentValue',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '⚡ $_playerPoints ${_text(data, 'disponibles', 'disponibles')}',
                        style: const TextStyle(color: _gold),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: selectedPoints,
                        min: 1,
                        max: _playerPoints.toDouble(),
                        divisions: _playerPoints > 1 ? _playerPoints - 1 : null,
                        activeColor: Colors.orange,
                        onChanged:
                            _playerPoints > 1
                                ? (value) =>
                                    setDialogState(() => selectedPoints = value)
                                : null,
                      ),
                      Text(
                        '${selectedPoints.toInt()} ⚡',
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
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: Text(
                                _text(data, 'cancelar', 'CANCELAR'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  () => Navigator.pop(
                                    dialogContext,
                                    selectedPoints.toInt(),
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: Text(
                                _text(data, 'mejorar', 'MEJORAR'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
    if (pointsToSpend == null || !mounted) return;
    setState(() {
      _cropUpgradeInProgress = true;
      _playerPoints -= pointsToSpend;
      if (production) {
        _playerCropProduction.update(
          column,
          (value) => value + pointsToSpend,
          ifAbsent: () => data.playerCrop.puntosPorTurno + pointsToSpend,
        );
      } else {
        _playerCropHealth.update(
          column,
          (value) => value + pointsToSpend,
          ifAbsent: () => data.playerCrop.vida + pointsToSpend,
        );
      }
    });
    await _showPassTurnInstructions(data);
    if (!mounted) return;
    setState(() {
      _cropUpgradeInProgress = false;
      _passButtonUnlocked = true;
    });
  }

  Future<void> _passTurn(_TutorialBoardData data) async {
    if (!_passButtonUnlocked || _opponentTurnInProgress) return;
    setState(() {
      _passButtonUnlocked = false;
      _opponentTurnInProgress = true;
    });

    if (_villagerMoved) {
      await _runNextOpponentTurn(data);
      if (!mounted) return;
      setState(() => _opponentTurnInProgress = false);
      return;
    }

    await _showOpponentDiceDialog(data);
    if (!mounted) return;

    setState(() {
      _opponentPoints += _opponentDieOne + _opponentDieTwo;
      _opponentPoints -= data.opponentCrop.costoInvocacion * _opponentCropCount;
      _opponentTurnComplete = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_jugador', '🎲 TIRANDO DADOS...'),
      dieOne: _playerTurnDieOne,
      dieTwo: _playerTurnDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _playerPoints += _playerTurnDieOne + _playerTurnDieTwo;
      _cropHarvestInProgress = _playerCropProduction.values.any(
        (production) => production > 0,
      );
    });
    await _harvestPlayerCrop();
    if (!mounted) return;
    setState(() {
      _cropHarvestInProgress = false;
      _opponentTurnInProgress = false;
    });
    await _showPlantMoreCropsInstructions(data);
    if (!mounted) return;
    setState(() => _additionalCropSummoningEnabled = true);
  }

  Future<void> _runNextOpponentTurn(_TutorialBoardData data) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_ia', '🤖 IA TIRANDO DADOS...'),
      dieOne: _nextOpponentDieOne,
      dieTwo: _nextOpponentDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _opponentPoints += _nextOpponentDieOne + _nextOpponentDieTwo;
    });
    await _harvestOpponentCrops(data);
    if (!mounted) return;
    await _upgradeOpponentCropProduction(data);
    if (!mounted) return;
    await _runNextPlayerTurn(data);
  }

  Future<void> _runNextPlayerTurn(_TutorialBoardData data) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_jugador', '🎲 TIRANDO DADOS...'),
      dieOne: _nextPlayerDieOne,
      dieTwo: _nextPlayerDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _playerPoints += _nextPlayerDieOne + _nextPlayerDieTwo;
      _cropHarvestInProgress = _playerCropProduction.values.any(
        (production) => production > 0,
      );
    });
    await _harvestPlayerCrop();
    if (!mounted) return;
    setState(() => _cropHarvestInProgress = false);
    await _repairPlayerElementsWithVillager(data);
  }

  Future<void> _repairPlayerElementsWithVillager(
    _TutorialBoardData data,
  ) async {
    if (!_villagerMoved) return;

    const villagerRow = 3;
    const villagerColumn = 0;
    const playerCropRow = 3;
    final repairedCropColumns =
        _invokedPlayerCropColumns
            .where(
              (column) =>
                  villagerRow == playerCropRow || column == villagerColumn,
            )
            .toList();
    final repairPower = data.playerVillager.puntosReconstruccion;

    setState(() {
      for (final column in repairedCropColumns) {
        _playerCropHealth.update(
          column,
          (health) => health + repairPower,
          ifAbsent: () => data.playerCrop.vida + repairPower,
        );
      }
      if (villagerRow == 3 || villagerColumn == 2) {
        _playerMonumentHealth =
            (_playerMonumentHealth ?? data.playerCivilization.muralla.vida) +
            repairPower;
      }
    });

    for (var hit = 0; hit < 3; hit++) {
      if (!mounted) return;
      setState(() => _villagerHammerAnimating = true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _villagerHammerAnimating = false);
      if (hit < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    }
  }

  Future<void> _upgradeOpponentCropProduction(_TutorialBoardData data) async {
    for (final column in [0, 1, 3, 4]) {
      if (!mounted) return;
      await Future<void>.delayed(_opponentUpgradeDelay);
      if (!mounted) return;
      if (_opponentPoints < _opponentCropProductionUpgrade) return;

      setState(() {
        _opponentPoints -= _opponentCropProductionUpgrade;
        _opponentCropProduction[column] =
            (_opponentCropProduction[column] ??
                data.opponentCrop.puntosPorTurno) +
            _opponentCropProductionUpgrade;
      });
    }
  }

  Future<void> _showVillagerInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(data, 'tutorial_villager_title', 'Aldeanos'),
            message: _text(
              data,
              'tutorial_villager_explanation',
              'No solo puedes mejorar la vida de tus cultivos con tus puntos de invocación. También los aldeanos pueden reconstruirlos para que sean más fuertes. Invoca un aldeano para que cada turno reconstruya tus cultivos y tus monumentos.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _harvestPlayerCrop() async {
    final points = _playerCropProduction.values.fold<int>(
      0,
      (total, production) => total + production,
    );
    await _animateCropHarvest(points, opponent: false);
  }

  Future<void> _harvestOpponentCrops(_TutorialBoardData data) async {
    final points = data.opponentCrop.puntosPorTurno * _opponentCropCount;
    await _animateCropHarvest(points, opponent: true);
  }

  Future<void> _animateCropHarvest(int points, {required bool opponent}) async {
    if (points <= 0) return;
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: MediaQuery.of(context).size.width / 2 - 50,
            top: MediaQuery.of(context).size.height / 2 - 60,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 10),
              tween: Tween<double>(begin: 0, end: -100),
              curve: Curves.easeOutCubic,
              builder:
                  (context, value, child) => Transform.translate(
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
                              '+$points',
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
                  ),
            ),
          ),
    );

    setState(() {
      if (opponent) {
        _opponentPoints += points;
        _opponentCropHarvestAnimating = true;
      } else {
        _playerPoints += points;
        _playerCropHarvestAnimating = true;
      }
    });
    Overlay.of(context).insert(overlayEntry);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        if (opponent) {
          _opponentCropHarvestAnimating = false;
        } else {
          _playerCropHarvestAnimating = false;
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } finally {
      if (overlayEntry.mounted) overlayEntry.remove();
    }
  }

  Future<void> _showPlantMoreCropsInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(data, 'tutorial_plant_more_crops_title', 'Cultivos'),
            message: _text(
              data,
              'tutorial_plant_more_crops_explanation',
              'Continúa plantando cultivos para incrementar tu producción de puntos. Selecciona las casillas vacías y planta un par más de cultivos.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showOpponentDiceDialog(_TutorialBoardData data) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_ia', '🤖 IA TIRANDO DADOS...'),
      dieOne: _opponentDieOne,
      dieTwo: _opponentDieTwo,
    );
  }

  Future<void> _showDiceRollDialog(
    _TutorialBoardData data, {
    required String title,
    required int dieOne,
    required int dieTwo,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        });

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
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/dados/${dieOne}x$dieTwo.png',
                  width: 200,
                  height: 200,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 200,
                        height: 200,
                        color: Colors.brown[600],
                        alignment: Alignment.center,
                        child: Text(
                          '$dieOne x $dieTwo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          ),
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

  Future<void> _showPassTurnInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(data, 'tutorial_pass_turn_title', 'Turno'),
            message: _text(
              data,
              'tutorial_pass_turn_explanation',
              'Para terminar tu turno, presiona el botón «Pasar» en la parte inferior del tablero.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showCropInvocationDialog(
    _TutorialBoardData data,
    int column,
  ) async {
    final canSummon =
        column == 1
            ? _cropSummoningEnabled
            : _additionalCropSummoningEnabled && (column == 3 || column == 4);
    if (!canSummon || _invokedPlayerCropColumns.contains(column)) return;
    final crop = data.playerCrop;
    if (_playerPoints < crop.costoInvocacion) return;

    final selected = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[700]!, Colors.amber[900]!],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '⚡ ${_text(data, 'invocar', 'INVOCAR')}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$_playerPoints ⚡',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      key: const ValueKey('tutorial-crop-option'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold, width: 2),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              crop.imagen,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _text(data, '${crop.id}_nombre', crop.nombre),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '🌾 ${crop.puntosPorTurno}   ❤️ ${crop.vida}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '⚡ ${crop.costoInvocacion}',
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        _text(data, 'tutorial_dice_continue', 'Entendido'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (selected != true || !mounted) return;
    setState(() {
      _playerPoints -= crop.costoInvocacion;
      _invokedPlayerCropColumns.add(column);
      _playerCropHealth[column] = crop.vida;
      _playerCropProduction[column] = crop.puntosPorTurno;
    });
    if (column == 1) await _showCropUpgradeInstructions(data);
    if (_invokedPlayerCropColumns.containsAll({3, 4}) &&
        !_villagerInstructionsShown &&
        mounted) {
      _villagerInstructionsShown = true;
      await _showVillagerInstructions(data);
      if (!mounted) return;
      setState(() => _villagerSummoningEnabled = true);
    }
  }

  Future<void> _showVillagerInvocationDialog(_TutorialBoardData data) async {
    final villager = data.playerVillager;
    if (!_villagerSummoningEnabled ||
        _villagerSummoned ||
        _playerPoints < villager.costoInvocacion) {
      return;
    }

    final selected = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[700]!, Colors.amber[900]!],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '⚡ ${_text(data, 'invocar', 'INVOCAR')}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$_playerPoints ⚡',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      key: const ValueKey('tutorial-villager-option'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold, width: 2),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              villager.imagen,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _text(
                                data,
                                '${villager.id}_nombre',
                                villager.nombre,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '🔨 ${villager.puntosReconstruccion}   👨 ${villager.vida}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '⚡ ${villager.costoInvocacion}',
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        _text(data, 'tutorial_dice_continue', 'Entendido'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (selected != true || !mounted) return;
    setState(() {
      _playerPoints -= villager.costoInvocacion;
      _villagerSummoned = true;
      _villagerSummoningEnabled = false;
    });
    await _showVillagerRepairInstructions(data);
  }

  Future<void> _showVillagerRepairInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(data, 'tutorial_villager_repair_title', '🔨 Aldeanos'),
            message: _text(
              data,
              'tutorial_villager_repair_explanation',
              'Los aldeanos reparan edificios y cultivos con su poder de reconstrucción. 🔨 Cada inicio de turno reparan todos los edificios y cultivos que se encuentren en su fila y su columna.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
    if (!mounted) return;
    await _showVillagerMoveInstructions(data);
  }

  Future<void> _showVillagerMoveInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(data, 'tutorial_villager_move_title', 'Aldeanos'),
            message: _text(
              data,
              'tutorial_villager_move_explanation',
              'Mueve tus aldeanos a la posición más conveniente para ti. Para hacerlo, da clic en el aldeano y selecciona la opción de mover.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showVillagerOptionsDialog(_TutorialBoardData data) async {
    if (!_villagerSummoned ||
        _villagerMoved ||
        _villagerMoveTargetEnabled ||
        !mounted) {
      return;
    }

    final villager = data.playerVillager;
    final shouldMove = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
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
                border: Border.all(color: _gold, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👨', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _text(data, '${villager.id}_nombre', villager.nombre),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '🔨 ${villager.puntosReconstruccion}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '❤️ ${villager.vida}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const ValueKey('tutorial-villager-move-action'),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.directions_walk),
                      label: Text(_text(data, 'mover', 'MOVER')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      _text(data, 'cancelar', 'CANCELAR'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (shouldMove != true || !mounted) return;
    setState(() => _villagerMoveTargetEnabled = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_villager_move_target_title',
              'Mueve al aldeano',
            ),
            message: _text(
              data,
              'tutorial_villager_move_target_explanation',
              'Selecciona la casilla resaltada junto al cultivo para mover allí al aldeano.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showCropInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(data, 'tutorial_spending_title', 'Invocar y mejorar'),
            message: _text(
              data,
              'tutorial_crop_explanation',
              'Al invocar o mejorar un elemento en el tablero, los puntos se descontarán de tus puntos acumulados. No solo los dados pueden darte puntos: los cultivos también los generan. Selecciona una casilla vacía e invoca un cultivo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  void _showDiceTutorial(_TutorialBoardData data) {
    if (_diceTutorialShown) return;
    _diceTutorialShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.brown[800],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _text(data, 'tutorial_dice_title', 'Tirada de dados'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _text(
                        data,
                        'tutorial_dice_explanation',
                        'Al inicio de cada turno, cada jugador suma a sus puntos de invocación el resultado de los dados. Usa esos puntos para invocar o mejorar elementos.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Image.asset(
                      'assets/images/dados/$_tutorialDieOne'
                      'x$_tutorialDieTwo.png',
                      width: 160,
                      height: 160,
                      errorBuilder:
                          (context, error, stackTrace) => Text(
                            '$_tutorialDieOne + $_tutorialDieTwo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                    Text(
                      _text(data, 'tutorial_dice_result', '1 + 3 = 4 puntos'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          _text(data, 'tutorial_dice_continue', 'Entendido'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );
      if (!mounted) return;
      setState(() {
        _playerPoints += _tutorialDieOne + _tutorialDieTwo;
      });
      await _showCropInstructions(data);
      if (!mounted) return;
      setState(() => _cropSummoningEnabled = true);
    });
  }

  Widget _buildTutorialDialog({
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.brown[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialBoardData {
  final Map<String, String> translations;
  final Civilizacion opponentCivilization;
  final Civilizacion playerCivilization;
  final Cultivo opponentCrop;
  final Cultivo playerCrop;
  final Aldeano playerVillager;

  const _TutorialBoardData({
    required this.translations,
    required this.opponentCivilization,
    required this.playerCivilization,
    required this.opponentCrop,
    required this.playerCrop,
    required this.playerVillager,
  });
}
