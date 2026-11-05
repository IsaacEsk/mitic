import 'package:flutter/material.dart';
import 'package:mitic/models/aldeano_model.dart';
import 'package:mitic/models/civilizacion_model.dart';
import 'package:mitic/models/cultivo_model.dart';
import 'package:mitic/models/guerrero_field_model_2.0.dart';
import 'package:mitic/screens/game_mode_screen.dart';
import 'package:mitic/models/guerrero_model.dart';
import 'package:mitic/models/hospital_campo.dart';
import 'package:mitic/models/hospital_model.dart';
import 'package:mitic/models/torre_campo.dart';
import 'package:mitic/models/torre_model.dart';
import 'package:mitic/services/mitic2_data_service.dart';
import 'package:mitic/services/translationService.dart';
import 'package:mitic/widgets/monumento_tablero.dart';
import 'package:mitic/widgets/guerrero_tablero.dart';
import 'package:mitic/widgets/hospital_tablero.dart';
import 'package:mitic/widgets/torre_tablero.dart';

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
  static const _terracottaOpponentDieOne = 1;
  static const _terracottaOpponentDieTwo = 1;
  static const _terracottaPlayerDieOne = 2;
  static const _terracottaPlayerDieTwo = 5;
  static const _monumentOpponentDieOne = 2;
  static const _monumentOpponentDieTwo = 1;
  static const _monumentPlayerDieOne = 5;
  static const _monumentPlayerDieTwo = 6;
  static const _nextOpponentDieOne = 4;
  static const _nextOpponentDieTwo = 5;
  static const _towerOpponentDieOne = 3;
  static const _towerOpponentDieTwo = 6;
  static const _nextPlayerDieOne = 4;
  static const _nextPlayerDieTwo = 1;
  static const _towerDefensePlayerDieOne = 2;
  static const _towerDefensePlayerDieTwo = 5;
  static const _playerTurnDieOne = 6;
  static const _playerTurnDieTwo = 5;
  static const _finalPlayerDieOne = 6;
  static const _finalPlayerDieTwo = 6;
  static const _earthquakePlayerDieOne = 4;
  static const _earthquakePlayerDieTwo = 5;
  static const _finalOpponentDieOne = 5;
  static const _finalOpponentDieTwo = 6;
  static const _opponentCropCount = 4;
  static const _opponentCropProductionUpgrade = 4;
  static const _earthquakeMonumentHealth = 76;
  static const _finalJoanAttackUpgradeMinimum = 11;
  static const _opponentUpgradeDelay = Duration(milliseconds: 600);
  static const _opponentCivilizationId = 'azteca';
  static const _playerCivilizationId = 'maya';
  static const _opponentCropId = 'cultivo_azteca';
  static const _playerCropId = 'cultivo_maya';
  static const _playerVillagerId = 'aldeano_maya';
  static const _playerWarriorId = 'maya_001';
  static const _opponentWarriorId = 'azteca_001';
  static const _joanWarriorId = 'francia_001';
  static const _terracottaWarriorId = 'china_001';

  int _playerPoints = 0;
  int _opponentPoints = 0;
  bool _diceTutorialShown = false;
  bool _cropSummoningEnabled = false;
  bool _cropUpgradeInProgress = false;
  bool _passButtonUnlocked = false;
  bool _opponentTurnComplete = false;
  bool _opponentTurnInProgress = false;
  TorreCampo? _opponentTower;
  int? _opponentMonumentHealth;
  GuerreroCampo? _opponentWarrior;
  bool _hospitalSummoningEnabled = false;
  bool _joanSummoningEnabled = false;
  HospitalCampo? _playerHospital;
  GuerreroCampo? _playerJoan;
  GuerreroCampo? _epidemicKukulkanWarrior;
  final Map<int, GuerreroCampo> _playerTerracottaWarriors = {};
  bool _finalPlayerTurnActive = false;
  bool _joanHasAttacked = false;
  bool _kukulkanAttackEnabled = false;
  bool _defensiveMovesEnabled = false;
  bool _kukulkanDefensivelyMoved = false;
  bool _kukulkanEnemyMoveEnabled = false;
  bool _kukulkanEnemyPositioned = false;
  bool _kukulkanEnemyAttackEnabled = false;
  bool _kukulkanEnemyAttackCompleted = false;
  bool _joanEnemyAttackEnabled = false;
  bool _terracottaSummoningEnabled = false;
  bool _terracottaAttackEnabled = false;
  bool _terracottaTurnSequenceCompleted = false;
  final Set<int> _terracottaAttackedColumns = {};
  bool _epidemicKukulkanSummoningEnabled = false;
  bool _epidemicKukulkanSummoned = false;
  bool _epidemicKukulkanCropAttackEnabled = false;
  bool _plagueTerracottaAttackEnabled = false;
  bool _plagueTerracottaAttackCompleted = false;
  bool _finalJoanAttackUpgradeEnabled = false;
  bool _finalJoanMonumentAttackEnabled = false;
  bool _finalMonumentDestroyed = false;
  final Set<String> _finalMonumentAttackedWarriors = {};
  bool _monumentAttacksEnabled = false;
  bool _monumentTurnSequenceCompleted = false;
  bool _opponentMonumentTargetGlowing = false;
  final Set<String> _monumentAttackedWarriors = {};
  bool _joanDefensivelyMoved = false;
  String? _defensiveMoveTargetWarrior;
  bool _defensiveWarriorMoveAnimating = false;
  bool _playerWarriorHealing = false;
  bool _playerWarriorDestroyed = false;
  bool _playerVillagerTargetGlowing = false;
  bool _playerVillagerDestroyed = false;
  int? _playerVillagerHealth;
  bool _playerCropHarvestAnimating = false;
  bool _opponentCropHarvestAnimating = false;
  bool _villagerHammerAnimating = false;
  bool _cropHarvestInProgress = false;
  int? _playerMonumentHealth;
  int? _playerWarriorHealth;
  bool _playerWarriorTargetGlowing = false;
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
  bool _warriorSummoningEnabled = false;
  bool _warriorSummoned = false;
  bool _warriorMoveTargetEnabled = false;
  bool _warriorDefenseMoveEnabled = false;
  int _warriorMoveCount = 0;
  bool _warriorAttackAnimating = false;
  bool _warriorHasAttacked = false;
  bool _towerDefenseTurnCompleted = false;
  final Set<int> _remainingOpponentCropColumns = {0, 1, 3, 4};
  final Set<int> _glowingOpponentCropColumns = {};
  final Set<int> _glowingPlayerCropColumns = {};

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
    final warriors = loadedData['guerreros'];
    final crops = await Mitic2DataService.cargarCultivos();
    final villagers = await Mitic2DataService.cargarAldeanos();
    final towers = await Mitic2DataService.cargarTorres();
    final hospitals = await Mitic2DataService.cargarHospitales();
    if (civilizations is! Map<String, Civilizacion> ||
        warriors is! Map<String, Guerrero>) {
      throw StateError('No se pudieron cargar los datos del tutorial.');
    }

    final opponentCivilization = civilizations[_opponentCivilizationId];
    final playerCivilization = civilizations[_playerCivilizationId];
    final opponentCrop = crops[_opponentCropId];
    final playerCrop = crops[_playerCropId];
    final playerVillager = villagers[_playerVillagerId];
    final playerWarrior = warriors[_playerWarriorId];
    final opponentWarrior = warriors[_opponentWarriorId];
    final joanWarrior = warriors[_joanWarriorId];
    final terracottaWarrior = warriors[_terracottaWarriorId];
    final opponentTower = towers['torre_azteca'];
    final playerHospital = hospitals['hospital_maya'];
    if (opponentCivilization == null ||
        playerCivilization == null ||
        opponentCrop == null ||
        playerCrop == null ||
        playerVillager == null ||
        playerWarrior == null ||
        opponentWarrior == null ||
        joanWarrior == null ||
        terracottaWarrior == null ||
        opponentTower == null ||
        playerHospital == null) {
      throw StateError('Faltan datos del tablero del tutorial.');
    }

    return _TutorialBoardData(
      translations: translations,
      opponentCivilization: opponentCivilization,
      playerCivilization: playerCivilization,
      opponentCrop: opponentCrop,
      playerCrop: playerCrop,
      playerVillager: playerVillager,
      playerWarrior: playerWarrior,
      opponentWarrior: opponentWarrior,
      joanWarrior: joanWarrior,
      terracottaWarrior: terracottaWarrior,
      opponentTower: opponentTower,
      playerHospital: playerHospital,
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
          final isKukulkanCell =
              _warriorSummoned &&
              !_playerWarriorDestroyed &&
              (_epidemicKukulkanSummoned
                  ? row == 2 && column == 0
                  : _defensiveMovesEnabled
                  ? (_kukulkanEnemyPositioned
                      ? row == 0 && column == 0
                      : _kukulkanDefensivelyMoved
                      ? row == 1 && column == 4
                      : _defensiveMoveTargetWarrior != 'kukulkan' &&
                          row == 0 &&
                          column == 0)
                  : ((_warriorMoveCount == 0 && row == 2 && column == 2) ||
                      (_warriorMoveCount == 1 && row == 2 && column == 1) ||
                      (_warriorMoveCount >= 2 && row == 0 && column == 0)));
          if (isMonumentRow && column == 2) {
            if (isTop && _finalMonumentDestroyed) {
              return _buildEmptyCell(cellSide);
            }
            return MonumentoTablero(
              key:
                  isTop
                      ? const ValueKey('tutorial-opponent-monument')
                      : const ValueKey('tutorial-player-monument'),
              ladoCelda: cellSide,
              imagenPath: civilization.muralla.imagen,
              vida:
                  isTop
                      ? _opponentMonumentHealth ?? civilization.muralla.vida
                      : _playerMonumentHealth ?? civilization.muralla.vida,
              resplandor: isTop && _opponentMonumentTargetGlowing,
              onTap: () {},
            );
          }
          if (isTop && isMonumentRow && _opponentTurnComplete) {
            if (!_remainingOpponentCropColumns.contains(column)) {
              return _buildEmptyCell(cellSide);
            }
            return _buildCropCell(
              cellSide,
              data.opponentCrop,
              data,
              key: ValueKey('tutorial-opponent-crop-$column'),
              interactive: false,
              harvestAnimating: _opponentCropHarvestAnimating,
              glowing: _glowingOpponentCropColumns.contains(column),
              animationKey: ValueKey('tutorial-opponent-crop-harvest-$column'),
              productionKey: ValueKey(
                'tutorial-opponent-crop-production-$column',
              ),
              productionOverride:
                  _opponentCropProduction[column] ??
                  data.opponentCrop.puntosPorTurno,
              glowColumn: column,
            );
          }
          if (isTop && row == 3 && column == 0 && _opponentWarrior != null) {
            return GuerreroTablero(
              key: const ValueKey('tutorial-opponent-warrior'),
              ladoCelda: cellSide,
              guerrero: _opponentWarrior!,
              onTap: () {},
            );
          }
          if (isTop && row == 3 && column == 4 && _opponentTower != null) {
            return TorreTablero(
              key: const ValueKey('tutorial-opponent-tower'),
              ladoCelda: cellSide,
              torre: _opponentTower!,
              onTap: () {},
            );
          }
          if (!isTop &&
              _villagerSummoned &&
              !_playerVillagerDestroyed &&
              ((!_villagerMoved && row == 2 && column == 2) ||
                  (_villagerMoved && row == 3 && column == 0))) {
            return _buildVillagerCell(
              cellSide,
              data,
              interactive: !_villagerMoved && !_villagerMoveTargetEnabled,
            );
          }
          if (!isTop && row == 0 && column == 4) {
            if (_playerHospital != null) {
              return HospitalTablero(
                key: const ValueKey('tutorial-player-hospital'),
                ladoCelda: cellSide,
                hospital: _playerHospital!,
                onTap: () {},
              );
            }
            if (_hospitalSummoningEnabled) {
              return _buildHospitalSummonCell(cellSide, data);
            }
          }
          if (!isTop && row == 3 && column == 0 && _villagerMoveTargetEnabled) {
            return _buildVillagerMoveTargetCell(cellSide);
          }
          if (!isTop &&
              row == 2 &&
              column == 0 &&
              _epidemicKukulkanSummoningEnabled &&
              !_epidemicKukulkanSummoned) {
            return _buildEpidemicKukulkanSummonCell(cellSide, data);
          }
          if (!isTop && isKukulkanCell) {
            return _buildWarriorCell(
              cellSide,
              data,
              key:
                  _epidemicKukulkanSummoned
                      ? const ValueKey('tutorial-epidemic-kukulkan-warrior')
                      : null,
              interactive:
                  _finalJoanMonumentAttackEnabled
                      ? !_finalMonumentDestroyed &&
                          !_finalMonumentAttackedWarriors.contains(
                            'kukulkan',
                          ) &&
                          !(_epidemicKukulkanWarrior?.yaAtacoEsteTurno ?? true)
                      : _epidemicKukulkanSummoned
                      ? (_epidemicKukulkanCropAttackEnabled &&
                          !(_epidemicKukulkanWarrior?.yaAtacoEsteTurno ??
                              false))
                      : _defensiveMovesEnabled
                      ? _defensiveMoveTargetWarrior == null &&
                          (_kukulkanEnemyMoveEnabled
                              ? _kukulkanEnemyPositioned
                                  ? _kukulkanEnemyAttackEnabled &&
                                      !_kukulkanEnemyAttackCompleted
                                  : true
                              : !_kukulkanDefensivelyMoved)
                      : !_warriorMoveTargetEnabled &&
                          !_warriorHasAttacked &&
                          (!_finalPlayerTurnActive || _kukulkanAttackEnabled),
              onTapOverride:
                  _finalJoanMonumentAttackEnabled &&
                          !_finalMonumentDestroyed &&
                          !_finalMonumentAttackedWarriors.contains('kukulkan')
                      ? () => _showFinalMonumentAttackDialog(
                        data,
                        warriorId: 'kukulkan',
                      )
                      : null,
            );
          }
          if (!isTop &&
              row == 2 &&
              _playerJoan != null &&
              (_defensiveMovesEnabled
                  ? (_joanDefensivelyMoved
                      ? column == 4
                      : column == 3 && _defensiveMoveTargetWarrior != 'joan')
                  : column == 3)) {
            return GuerreroTablero(
              key: const ValueKey('tutorial-player-joan'),
              ladoCelda: cellSide,
              guerrero: _playerJoan!,
              onTap:
                  _finalJoanAttackUpgradeEnabled
                      ? () => _showFinalJoanUpgradeOptionsDialog(data)
                      : _finalJoanMonumentAttackEnabled &&
                          !_finalMonumentDestroyed &&
                          !_finalMonumentAttackedWarriors.contains('joan') &&
                          !_playerJoan!.yaAtacoEsteTurno
                      ? () => _showFinalMonumentAttackDialog(
                        data,
                        warriorId: 'joan',
                      )
                      : _monumentAttacksEnabled &&
                          !_playerJoan!.yaAtacoEsteTurno &&
                          !_monumentAttackedWarriors.contains('joan')
                      ? () => _showMonumentAttackDialog(data, warriorId: 'joan')
                      : _joanEnemyAttackEnabled && !_joanHasAttacked
                      ? () => _showJoanAttackDialog(data)
                      : _defensiveMovesEnabled
                      ? _joanDefensivelyMoved ||
                              _defensiveMoveTargetWarrior != null
                          ? () {}
                          : () => _showDefensiveWarriorOptionsDialog(
                            data,
                            warriorId: 'joan',
                          )
                      : _joanHasAttacked
                      ? () {}
                      : () => _showJoanAttackDialog(data),
            );
          }
          if (!isTop &&
              row == 2 &&
              (column == 1 || column == 3) &&
              (_terracottaSummoningEnabled ||
                  _playerTerracottaWarriors.containsKey(column))) {
            final warrior = _playerTerracottaWarriors[column];
            if (warrior != null) {
              return GuerreroTablero(
                key: ValueKey('tutorial-terracotta-warrior-$column'),
                ladoCelda: cellSide,
                guerrero: warrior,
                onTap:
                    _finalJoanMonumentAttackEnabled &&
                            !_finalMonumentDestroyed &&
                            !warrior.yaAtacoEsteTurno &&
                            !_finalMonumentAttackedWarriors.contains(
                              'terracotta-$column',
                            )
                        ? () => _showFinalMonumentAttackDialog(
                          data,
                          warriorId: 'terracotta-$column',
                        )
                        : _plagueTerracottaAttackEnabled && column == 3
                        ? () => _showPlagueTerracottaAttackDialog(data)
                        : _monumentAttacksEnabled &&
                            !warrior.yaAtacoEsteTurno &&
                            !_monumentAttackedWarriors.contains(
                              'terracotta-$column',
                            )
                        ? () => _showMonumentAttackDialog(
                          data,
                          warriorId: 'terracotta-$column',
                        )
                        : _terracottaAttackEnabled &&
                            !_terracottaAttackedColumns.contains(column)
                        ? () => _showTerracottaAttackDialog(data, column)
                        : () {},
              );
            }
            return _buildTerracottaSummonCell(cellSide, data, column);
          }
          if (!isTop &&
              _defensiveMovesEnabled &&
              ((_defensiveMoveTargetWarrior == 'kukulkan' &&
                      (_kukulkanEnemyMoveEnabled
                          ? row == 0 && column == 0
                          : row == 1 && column == 4)) ||
                  (_defensiveMoveTargetWarrior == 'joan' &&
                      row == 2 &&
                      column == 4))) {
            return _buildWarriorMoveTargetCell(
              cellSide,
              onTap: () => _completeDefensiveWarriorMove(data),
            );
          }
          if (!isTop &&
              row == 2 &&
              column == 3 &&
              _joanSummoningEnabled &&
              _playerJoan == null) {
            return _buildJoanSummonCell(cellSide, data);
          }
          if (!isTop &&
              _warriorMoveTargetEnabled &&
              ((_warriorMoveCount == 0 && row == 2 && column == 1) ||
                  (_warriorMoveCount == 1 && row == 0 && column == 0))) {
            return _buildWarriorMoveTargetCell(
              cellSide,
              onTap: () => _completeWarriorMove(data),
            );
          }
          if (!isTop && row == 2 && column == 2) {
            if (_warriorSummoningEnabled) {
              return _buildWarriorSummonCell(cellSide, data);
            }
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
                glowing: _glowingPlayerCropColumns.contains(column),
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

  Widget _buildHospitalSummonCell(double cellSide, _TutorialBoardData data) {
    return SizedBox(
      width: cellSide,
      height: cellSide,
      child: Tooltip(
        message: _text(data, 'modal_hospital', 'HOSPITAL'),
        child: Padding(
          padding: EdgeInsets.all(cellSide * 0.05),
          child: ElevatedButton(
            key: const ValueKey('tutorial-summon-hospital'),
            onPressed: () => _showHospitalInvocationDialog(data),
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

  Widget _buildEpidemicKukulkanSummonCell(
    double cellSide,
    _TutorialBoardData data,
  ) {
    return SizedBox(
      width: cellSide,
      height: cellSide,
      child: Tooltip(
        message: _text(
          data,
          'tutorial_summon_warrior_button',
          'Invocar guerrero',
        ),
        child: Padding(
          padding: EdgeInsets.all(cellSide * 0.05),
          child: ElevatedButton(
            key: const ValueKey('tutorial-summon-epidemic-kukulkan'),
            onPressed: () => _showEpidemicKukulkanInvocationDialog(data),
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

  Widget _buildWarriorSummonCell(double cellSide, _TutorialBoardData data) {
    return SizedBox(
      width: cellSide,
      height: cellSide,
      child: Tooltip(
        message: _text(
          data,
          'tutorial_summon_warrior_button',
          'Invocar guerrero',
        ),
        child: Padding(
          padding: EdgeInsets.all(cellSide * 0.05),
          child: ElevatedButton(
            key: const ValueKey('tutorial-summon-warrior'),
            onPressed: () => _showWarriorInvocationDialog(data),
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

  Widget _buildTerracottaSummonCell(
    double cellSide,
    _TutorialBoardData data,
    int column,
  ) {
    return SizedBox(
      width: cellSide,
      height: cellSide,
      child: Tooltip(
        message: _text(
          data,
          'tutorial_summon_warrior_button',
          'Invocar guerrero',
        ),
        child: Padding(
          padding: EdgeInsets.all(cellSide * 0.05),
          child: ElevatedButton(
            key: ValueKey('tutorial-summon-terracotta-$column'),
            onPressed: () => _showTerracottaInvocationDialog(data, column),
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

  Widget _buildJoanSummonCell(double cellSide, _TutorialBoardData data) {
    return SizedBox(
      width: cellSide,
      height: cellSide,
      child: Tooltip(
        message: _text(
          data,
          'tutorial_summon_warrior_button',
          'Invocar guerrero',
        ),
        child: Padding(
          padding: EdgeInsets.all(cellSide * 0.05),
          child: ElevatedButton(
            key: const ValueKey('tutorial-summon-joan'),
            onPressed: () => _showJoanInvocationDialog(data),
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

  Widget _buildWarriorCell(
    double cellSide,
    _TutorialBoardData data, {
    Key? key,
    required bool interactive,
    VoidCallback? onTapOverride,
  }) {
    final warrior =
        _epidemicKukulkanWarrior?.guerreroBase ?? data.playerWarrior;
    final statHeight = cellSide * 0.25;
    return InkWell(
      key: key,
      onTap:
          interactive
              ? onTapOverride ??
                  (_epidemicKukulkanSummoned
                      ? _epidemicKukulkanCropAttackEnabled
                          ? () => _showEpidemicKukulkanAttackDialog(data)
                          : () => _showMonumentAttackDialog(
                            data,
                            warriorId: 'kukulkan',
                          )
                      : _defensiveMovesEnabled
                      ? () => _showDefensiveWarriorOptionsDialog(
                        data,
                        warriorId: 'kukulkan',
                      )
                      : () => _showWarriorOptionsDialog(data))
              : null,
      child: AnimatedContainer(
        key: const ValueKey('tutorial-warrior-piece'),
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          boxShadow:
              _playerWarriorTargetGlowing
                  ? [
                    BoxShadow(
                      color: (_playerWarriorHealing ? Colors.green : Colors.red)
                          .withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ]
                  : null,
        ),
        child: SizedBox(
          width: cellSide,
          height: cellSide,
          child: Padding(
            padding: EdgeInsets.all(cellSide * 0.05),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cellSide * 0.08),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AnimatedContainer(
                      key: const ValueKey('tutorial-warrior-attack-animation'),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      width:
                          cellSide *
                          0.9 *
                          (_warriorAttackAnimating ||
                                  _defensiveWarriorMoveAnimating
                              ? 0.7
                              : 1),
                      height:
                          cellSide *
                          0.9 *
                          (_warriorAttackAnimating ||
                                  _defensiveWarriorMoveAnimating
                              ? 0.7
                              : 1),
                      child: Image.asset(warrior.imagen, fit: BoxFit.cover),
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
                          key: const ValueKey('tutorial-player-warrior-stats'),
                          '⚔️ ${warrior.ataque}   ❤️ ${_playerWarriorHealth ?? warrior.vida}',
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
      ),
    );
  }

  Widget _buildWarriorMoveTargetCell(
    double cellSide, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: const ValueKey('tutorial-warrior-move-target'),
      onTap: onTap,
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

  Future<void> _completeWarriorMove(_TutorialBoardData data) async {
    if (!_warriorMoveTargetEnabled || !mounted) return;
    setState(() {
      _warriorMoveCount++;
      _warriorMoveTargetEnabled = false;
    });
    await _showWarriorAttackActionInstructions(data);
  }

  Future<void> _showWarriorAttackActionInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_warrior_attack_action_title',
              'Ataca el cultivo',
            ),
            message: _text(
              data,
              'tutorial_warrior_attack_action_explanation',
              'Para atacar al cultivo, da clic en el guerrero y selecciona la opción de atacar.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
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
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    width:
                        cellSide *
                        0.9 *
                        (_villagerHammerAnimating ||
                                _playerVillagerTargetGlowing
                            ? 0.5
                            : 1),
                    height:
                        cellSide *
                        0.9 *
                        (_villagerHammerAnimating ||
                                _playerVillagerTargetGlowing
                            ? 0.5
                            : 1),
                    decoration: BoxDecoration(
                      boxShadow:
                          _playerVillagerTargetGlowing
                              ? [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ]
                              : null,
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
                        '🔨 ${villager.puntosReconstruccion}   👨 ${_playerVillagerHealth ?? villager.vida}',
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
    bool glowing = false,
    int? productionOverride,
    int? column,
    int? glowColumn,
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
            if (glowing)
              Positioned.fill(
                child: AnimatedContainer(
                  key: ValueKey(
                    'tutorial-${interactive ? 'player' : 'opponent'}-crop-glow-${glowColumn ?? column}',
                  ),
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.8),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
    if (_monumentTurnSequenceCompleted) return;
    setState(() {
      _passButtonUnlocked = false;
      _opponentTurnInProgress = true;
    });

    if (_monumentAttackedWarriors.length == 3) {
      await _runMonumentOpponentAndPlayerTurn(data);
      if (!mounted) return;
      setState(() {
        _opponentTurnInProgress = false;
        _monumentTurnSequenceCompleted = true;
      });
      return;
    }

    if (_terracottaAttackedColumns.length == 2 &&
        !_terracottaTurnSequenceCompleted) {
      await _runTerracottaOpponentTurn(data);
      if (!mounted) return;
      setState(() {
        _opponentTurnInProgress = false;
        _terracottaTurnSequenceCompleted = true;
      });
      return;
    }

    if (_warriorHasAttacked && !_towerDefenseTurnCompleted) {
      await _runOpponentTowerTurn(data);
      if (!mounted) return;
      setState(() => _opponentTurnInProgress = false);
      return;
    }

    if (_warriorHasAttacked && _towerDefenseTurnCompleted) {
      if (_finalPlayerTurnActive) {
        await _runEarthquakeOpponentTurn(data);
      } else {
        await _runFinalOpponentTowerTurn(data);
      }
      if (!mounted) return;
      setState(() => _opponentTurnInProgress = false);
      return;
    }

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

  Future<void> _runTerracottaOpponentTurn(_TutorialBoardData data) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_ia', '🤖 IA TIRANDO DADOS...'),
      dieOne: _terracottaOpponentDieOne,
      dieTwo: _terracottaOpponentDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _opponentPoints += _terracottaOpponentDieOne + _terracottaOpponentDieTwo;
    });
    await _harvestOpponentCrops(data);
    if (!mounted) return;
    await _investOpponentPointsInRemainingCrop(data);
    if (!mounted) return;
    await _runTerracottaPlayerTurn(data);
  }

  Future<void> _runMonumentOpponentAndPlayerTurn(
    _TutorialBoardData data,
  ) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_ia', '🤖 IA TIRANDO DADOS...'),
      dieOne: _monumentOpponentDieOne,
      dieTwo: _monumentOpponentDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _opponentPoints += _monumentOpponentDieOne + _monumentOpponentDieTwo;
    });
    await _harvestOpponentCrops(data);
    if (!mounted) return;
    await _summonOpponentCrop(data, column: 3);
    if (!mounted) return;

    setState(() {
      _warriorHasAttacked = false;
      _joanHasAttacked = false;
      _playerJoan?.yaAtacoEsteTurno = false;
      _epidemicKukulkanWarrior?.yaAtacoEsteTurno = false;
      for (final warrior in _playerTerracottaWarriors.values) {
        warrior.yaAtacoEsteTurno = false;
      }
    });
    _applyTutorialPlague(data);
    await _showTutorialPlague(data);
    if (!mounted) return;

    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_jugador', '🎲 TIRANDO DADOS...'),
      dieOne: _monumentPlayerDieOne,
      dieTwo: _monumentPlayerDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _playerPoints += _monumentPlayerDieOne + _monumentPlayerDieTwo;
      _cropHarvestInProgress = _playerCropProduction.values.any(
        (production) => production > 0,
      );
    });
    await _harvestPlayerCrop();
    if (!mounted) return;
    setState(() => _cropHarvestInProgress = false);
    await _healPlayerUnitsWithHospital(data);
    if (!mounted) return;
    await _showCropPlagueInstructions(data);
    if (!mounted) return;
    setState(() => _opponentTurnInProgress = false);
  }

  void _applyTutorialPlague(_TutorialBoardData data) {
    setState(() {
      for (final column in _invokedPlayerCropColumns) {
        _playerCropHealth[column] = 0;
        _playerCropProduction[column] = 0;
      }
      _invokedPlayerCropColumns.clear();
      _playerCropHealth.clear();
      _playerCropProduction.clear();
      _cropSummoningEnabled = false;
      _additionalCropSummoningEnabled = false;
    });
  }

  Future<void> _showCropPlagueInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_crop_plague_title',
              'Plaga en tus cultivos',
            ),
            message: _text(
              data,
              'tutorial_crop_plague_explanation',
              'Tus cultivos fueron atacados por una plaga. Las plagas actúan eventualmente en cualquier civilización, debilitando o incluso destruyendo los cultivos de tu civilización.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_plague_terracotta_attack_title',
              'Destruye el cultivo enemigo',
            ),
            message: _text(
              data,
              'tutorial_plague_terracotta_attack_explanation',
              'Utiliza a tu guerrero terracota frente al cultivo enemigo para destruirlo. Da clic sobre el guerrero para atacar.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
    if (!mounted) return;
    setState(() => _plagueTerracottaAttackEnabled = true);
  }

  Future<void> _showTutorialPlague(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        });

        return Dialog(
          key: const ValueKey('tutorial-plague-dialog'),
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
                Text(
                  _text(data, 'desastre_plaga_titulo', '🌾 PLAGA 🌾'),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _text(
                    data,
                    'desastre_plaga_mensaje',
                    'Las plagas devoran tus cultivos...',
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  _text(
                    data,
                    'desastre_plaga_cerrando',
                    '⏳ Cerrando en 2 segundos...',
                  ),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _investOpponentPointsInRemainingCrop(
    _TutorialBoardData data,
  ) async {
    if (_opponentPoints == 0) return;
    if (_remainingOpponentCropColumns.isEmpty) {
      throw StateError('La CPU no tiene cultivos para mejorar.');
    }

    final targetColumn = _remainingOpponentCropColumns.first;
    final pointsToInvest = _opponentPoints;
    await Future<void>.delayed(_opponentUpgradeDelay);
    if (!mounted) return;
    setState(() {
      _opponentCropProduction.update(
        targetColumn,
        (production) => production + pointsToInvest,
        ifAbsent: () => data.opponentCrop.puntosPorTurno + pointsToInvest,
      );
      _opponentPoints = 0;
    });
  }

  Future<void> _runTerracottaPlayerTurn(_TutorialBoardData data) async {
    setState(() {
      _warriorHasAttacked = false;
      _joanHasAttacked = false;
      _playerJoan?.yaAtacoEsteTurno = false;
      for (final warrior in _playerTerracottaWarriors.values) {
        warrior.yaAtacoEsteTurno = false;
      }
    });

    _applyTutorialEpidemic(data);
    await _showTutorialEpidemic(data);
    if (!mounted) return;

    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_jugador', '🎲 TIRANDO DADOS...'),
      dieOne: _terracottaPlayerDieOne,
      dieTwo: _terracottaPlayerDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _playerPoints += _terracottaPlayerDieOne + _terracottaPlayerDieTwo;
      _cropHarvestInProgress = _playerCropProduction.values.any(
        (production) => production > 0,
      );
    });
    await _harvestPlayerCrop();
    if (!mounted) return;
    setState(() => _cropHarvestInProgress = false);
    await _healPlayerUnitsWithHospital(data);
    if (!mounted) return;
    await _showEpidemicExplanation(data);
    if (!mounted) return;
    await _showEpidemicKukulkanSummonInstructions(data);
    if (!mounted) return;
    setState(() => _epidemicKukulkanSummoningEnabled = true);
  }

  Future<void> _showEpidemicExplanation(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_epidemic_explanation_title',
              'Epidemias',
            ),
            message: _text(
              data,
              'tutorial_epidemic_explanation',
              'Acabas de sufrir una epidemia. Tus guerreros y aldeanos se debilitarán e incluso algunos morirán. Las epidemias ocurren eventualmente en cada una de las civilizaciones.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showEpidemicKukulkanSummonInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_epidemic_kukulkan_summon_title',
              'Invoca otro guerrero',
            ),
            message: _text(
              data,
              'tutorial_epidemic_kukulkan_summon_explanation',
              'Vamos a invocar otro guerrero para destruir el último cultivo del enemigo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  void _applyTutorialEpidemic(_TutorialBoardData data) {
    setState(() {
      if (_warriorSummoned && !_playerWarriorDestroyed) {
        _playerWarriorHealth =
            (_playerWarriorHealth ?? data.playerWarrior.vida) - 16;
        if (_epidemicKukulkanWarrior != null) {
          _epidemicKukulkanWarrior!.vidaActual = _playerWarriorHealth!;
        }
        if (_playerWarriorHealth! <= 0) {
          _playerWarriorHealth = 0;
          _playerWarriorDestroyed = true;
          _epidemicKukulkanWarrior = null;
        }
      }

      final joan = _playerJoan;
      if (joan != null) {
        joan.vidaActual -= 16;
        if (joan.vidaActual <= 0) {
          _playerJoan = null;
        }
      }

      _playerTerracottaWarriors.removeWhere((_, warrior) {
        warrior.vidaActual -= 16;
        return warrior.vidaActual <= 0;
      });
    });
  }

  Future<void> _showTutorialEpidemic(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        });

        return Dialog(
          key: const ValueKey('tutorial-epidemic-dialog'),
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
                Text(
                  _text(data, 'desastre_epidemia_titulo', '🦠 EPIDEMIA 🦠'),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _text(
                    data,
                    'desastre_epidemia_mensaje',
                    'Una enfermedad azota a tus unidades...',
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  _text(
                    data,
                    'desastre_epidemia_cerrando',
                    '⏳ Cerrando en 2 segundos...',
                  ),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> _runFinalOpponentTowerTurn(_TutorialBoardData data) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_ia', '🤖 IA TIRANDO DADOS...'),
      dieOne: _finalOpponentDieOne,
      dieTwo: _finalOpponentDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _opponentPoints += _finalOpponentDieOne + _finalOpponentDieTwo;
    });
    await _harvestOpponentCrops(data);
    if (!mounted) return;
    await _attackPlayerWithOpponentTower();
    if (!mounted) return;
    await _summonAndAttackWithOpponentWarrior(data);
    if (!mounted) return;
    await _runFinalPlayerTurn(data);
  }

  Future<void> _runEarthquakeOpponentTurn(_TutorialBoardData data) async {
    await _showTutorialEarthquake(data);
    if (!mounted) return;
    await _showEarthquakeExplanation(data);
    if (!mounted) return;
    await _harvestOpponentCrops(data);
    for (final column in [0, 1, 3, 4]) {
      if (!mounted) return;
      await _summonOpponentCrop(data, column: column);
    }
    if (!mounted) return;
    await _attackPlayerWithOpponentWarrior(data);
    if (!mounted) return;
    await _runEarthquakePlayerTurn(data);
  }

  Future<void> _runEarthquakePlayerTurn(_TutorialBoardData data) async {
    setState(() {
      _warriorHasAttacked = false;
      _joanHasAttacked = false;
      _playerJoan?.yaAtacoEsteTurno = false;
    });
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_jugador', '🎲 TIRANDO DADOS...'),
      dieOne: _earthquakePlayerDieOne,
      dieTwo: _earthquakePlayerDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _playerPoints += _earthquakePlayerDieOne + _earthquakePlayerDieTwo;
      _cropHarvestInProgress = _playerCropProduction.values.any(
        (production) => production > 0,
      );
    });
    await _harvestPlayerCrop();
    if (!mounted) return;
    setState(() => _cropHarvestInProgress = false);
    await _healPlayerUnitsWithHospital(data);
    if (!mounted) return;
    await _showKukulkanFinishEnemyInstructions(data);
    if (!mounted) return;
    setState(() => _kukulkanEnemyMoveEnabled = true);
  }

  Future<void> _showKukulkanFinishEnemyInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_kukulkan_finish_enemy_title',
              'Huitzilopochtli está débil',
            ),
            message: _text(
              data,
              'tutorial_kukulkan_finish_enemy_explanation',
              'Huitzilopochtli está débil, es momento de terminar con él. Da clic en Kukulkán para moverlo y colocarlo frente al guerrero enemigo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showKukulkanEnemyAttackInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_kukulkan_enemy_attack_title',
              'Ataca al enemigo',
            ),
            message: _text(
              data,
              'tutorial_kukulkan_enemy_attack_explanation',
              'Da clic en Kukulkán y ataca al enemigo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _summonOpponentCrop(
    _TutorialBoardData data, {
    required int column,
  }) async {
    if (_remainingOpponentCropColumns.contains(column)) return;
    if (_opponentPoints < data.opponentCrop.costoInvocacion) {
      throw StateError(
        'La CPU no tiene puntos suficientes para invocar un cultivo.',
      );
    }

    setState(() {
      _opponentPoints -= data.opponentCrop.costoInvocacion;
      _remainingOpponentCropColumns.add(column);
      _opponentCropProduction[column] = data.opponentCrop.puntosPorTurno;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _attackPlayerWithOpponentWarrior(_TutorialBoardData data) async {
    final warrior = _opponentWarrior;
    if (warrior == null || !_villagerSummoned || !_villagerMoved) {
      throw StateError(
        'No se encontró al guerrero o aldeano para el ataque del tutorial.',
      );
    }

    final villagerHealth = _playerVillagerHealth ?? data.playerVillager.vida;
    setState(() {
      warrior.animar = true;
      warrior.yaAtacoEsteTurno = true;
      _playerVillagerTargetGlowing = true;
      _playerVillagerHealth = villagerHealth - warrior.ataqueActual;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    if (warrior.ataqueActual < villagerHealth) {
      throw StateError(
        'El ataque de Huitzilopochtli no destruyó al aldeano como se esperaba.',
      );
    }

    setState(() {
      warrior.animar = false;
      _playerVillagerTargetGlowing = false;
      _playerVillagerDestroyed = true;
    });
  }

  Future<void> _showTutorialEarthquake(_TutorialBoardData data) async {
    if (_opponentTower == null) {
      throw StateError(
        'No se encontró la torre para el terremoto del tutorial.',
      );
    }

    setState(() {
      _opponentTower = null;
      _opponentMonumentHealth = _earthquakeMonumentHealth;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
                const Text('🌍', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                Text(
                  _text(data, 'desastre_terremoto_titulo', '🌍 TERREMOTO 🌍'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _text(
                    data,
                    'desastre_terremoto_mensaje',
                    'La tierra tiembla...',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  _text(
                    data,
                    'desastre_terremoto_cerrando',
                    '⏳ Cerrando en 2 segundos...',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEarthquakeExplanation(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_earthquake_explanation_title',
              'Terremotos',
            ),
            message: _text(
              data,
              'tutorial_earthquake_explanation',
              'Cuando un terremoto afecta a una ciudad, las torres, hospitales y monumentos se ven afectados e incluso pueden destruirse. Los terremotos pueden ocurrir eventualmente en cualquiera de las dos ciudades.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _runFinalPlayerTurn(_TutorialBoardData data) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_jugador', '🎲 TIRANDO DADOS...'),
      dieOne: _finalPlayerDieOne,
      dieTwo: _finalPlayerDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _playerPoints += _finalPlayerDieOne + _finalPlayerDieTwo;
      _cropHarvestInProgress = _playerCropProduction.values.any(
        (production) => production > 0,
      );
    });
    await _harvestPlayerCrop();
    if (!mounted) return;
    setState(() => _cropHarvestInProgress = false);
    await _repairPlayerElementsWithVillager(
      data,
      showWarriorInstructions: false,
    );
    if (!mounted) return;
    await _healPlayerUnitsWithHospital(data);
    if (!mounted) return;

    setState(() {
      _finalPlayerTurnActive = true;
      _warriorHasAttacked = false;
      _kukulkanAttackEnabled = false;
      _passButtonUnlocked = false;
    });
    await _showJoanSummoningInstructions(data);
    if (!mounted) return;
    setState(() => _joanSummoningEnabled = true);
  }

  Future<void> _healPlayerUnitsWithHospital(_TutorialBoardData data) async {
    final hospital = _playerHospital;
    if (hospital == null) return;

    const hospitalRow = 0;
    const hospitalColumn = 4;
    final healingPower =
        hospital.poderCuracionActual *
        (data.playerCivilization.id == 'maya' ? 2 : 1);
    final kukulkanHealth = _playerWarriorHealth ?? data.playerWarrior.vida;
    final healsKukulkan =
        _warriorSummoned &&
        kukulkanHealth > 0 &&
        (hospitalRow == (_kukulkanDefensivelyMoved ? 1 : 0) ||
            hospitalColumn == (_kukulkanDefensivelyMoved ? 4 : 0));
    final joan = _playerJoan;
    final healsJoan =
        joan != null &&
        joan.vidaActual > 0 &&
        (hospitalRow == 2 || hospitalColumn == (_joanDefensivelyMoved ? 4 : 3));
    if (!healsKukulkan && !healsJoan) return;

    setState(() {
      hospital.animar = true;
      if (healsKukulkan) {
        _playerWarriorHealing = true;
        _playerWarriorTargetGlowing = true;
        _playerWarriorHealth =
            ((_playerWarriorHealth ?? data.playerWarrior.vida) + healingPower)
                .clamp(0, data.playerWarrior.vida);
      }
      if (healsJoan) {
        joan.resplandor = true;
        joan.vidaActual = (joan.vidaActual + healingPower).clamp(
          0,
          joan.guerreroBase.vida,
        );
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      hospital.animar = false;
      _playerWarriorHealing = false;
      _playerWarriorTargetGlowing = false;
      joan?.resplandor = false;
    });
  }

  Future<void> _showJoanSummoningInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_joan_summon_title',
              'Invoca otro guerrero',
            ),
            message: _text(
              data,
              'tutorial_joan_summon_explanation',
              'Invoca otro guerrero y acaba con su cultivo desprotegido.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showJoanInvocationDialog(_TutorialBoardData data) async {
    final warrior = data.joanWarrior;
    if (!_joanSummoningEnabled || _playerJoan != null || !mounted) return;
    if (_playerPoints < warrior.costoInvocacion) {
      throw StateError(
        'No tienes suficientes puntos para invocar a Juana de Arco.',
      );
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
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '⚔️ ${_text(data, 'guerreros', 'GUERREROS')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      key: const ValueKey('tutorial-joan-option'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        width: 136,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              warrior.imagen,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _text(data, warrior.nombreId, warrior.nombreId),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚔️ ${warrior.ataque}   ❤️ ${warrior.vida}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚡ ${warrior.costoInvocacion}',
                              style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

    if (selected != true || !mounted) return;
    if (_playerPoints < warrior.costoInvocacion) {
      throw StateError(
        'No tienes suficientes puntos para invocar a Juana de Arco.',
      );
    }
    final joan = GuerreroCampo.desdeGuerrero(
      guerrero: warrior,
      coordenada: 'D2',
    )..animar = true;
    setState(() {
      _playerPoints -= warrior.costoInvocacion;
      _joanSummoningEnabled = false;
      _playerJoan = joan;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => joan.animar = false);
    await _showJoanAttackInstructions(data);
  }

  Future<void> _showJoanAttackInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_joan_attack_title',
              'Ataca el cultivo',
            ),
            message: _text(
              data,
              'tutorial_joan_attack_explanation',
              'Da clic sobre Juana de Arco y selecciona la opción de atacar para destruir su cultivo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showJoanAttackDialog(_TutorialBoardData data) async {
    final joan = _playerJoan;
    if (joan == null || _joanHasAttacked || !mounted) return;
    final action = await showDialog<bool>(
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
                      const Text('⚔️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _text(
                            data,
                            joan.guerreroBase.nombreId,
                            joan.guerreroBase.nombreId,
                          ),
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
                        '⚔️ ${joan.ataqueActual}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '❤️ ${joan.vidaActual}',
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
                      key: const ValueKey('tutorial-joan-attack-action'),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.gps_fixed),
                      label: Text(_text(data, 'atacar', 'ATACAR')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
    if (action == true && mounted) await _attackWithJoan(data);
  }

  Future<void> _attackWithJoan(_TutorialBoardData data) async {
    final joan = _playerJoan;
    final targetColumn = _joanEnemyAttackEnabled ? 4 : 3;
    if (joan == null ||
        _joanHasAttacked ||
        !_remainingOpponentCropColumns.contains(targetColumn) ||
        !mounted) {
      return;
    }

    setState(() {
      joan.animar = true;
      joan.yaAtacoEsteTurno = true;
      _glowingOpponentCropColumns.add(targetColumn);
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (joan.ataqueActual >= data.opponentCrop.vida) {
      setState(() {
        _remainingOpponentCropColumns.remove(targetColumn);
        _glowingOpponentCropColumns.remove(targetColumn);
        _joanHasAttacked = true;
        joan.animar = false;
      });
    } else {
      throw StateError('Juana de Arco no pudo destruir el cultivo objetivo.');
    }

    if (_joanEnemyAttackEnabled) {
      setState(() => _joanEnemyAttackEnabled = false);
      await _showTerracottaSummonInstructions(data);
      if (!mounted) return;
      setState(() => _terracottaSummoningEnabled = true);
      return;
    }
    await _showKukulkanAttackReminder(data);
    if (!mounted) return;
    setState(() => _kukulkanAttackEnabled = true);
  }

  Future<void> _showKukulkanAttackReminder(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_kukulkan_attack_reminder_title',
              'Kukulkán aún puede atacar',
            ),
            message: _text(
              data,
              'tutorial_kukulkan_attack_reminder_explanation',
              'Kukulkán todavía no ha atacado en este turno. Da clic sobre él y selecciona la opción de atacar.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _attackWithKukulkan(_TutorialBoardData data) async {
    final opponentWarrior = _opponentWarrior;
    if (!_finalPlayerTurnActive ||
        !_kukulkanAttackEnabled ||
        _warriorHasAttacked ||
        opponentWarrior == null ||
        !mounted) {
      return;
    }

    setState(() {
      _warriorAttackAnimating = true;
      opponentWarrior.resplandor = true;
      opponentWarrior.vidaActual -= data.playerWarrior.ataque;
      _warriorHasAttacked = true;
      _kukulkanAttackEnabled = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _warriorAttackAnimating = false;
      opponentWarrior.resplandor = false;
    });
    await _showProtectWarriorsDialog(data);
    if (!mounted) return;
    await _showMoveWarriorsBehindHospitalDialog(data);
    if (!mounted) return;
    setState(() {
      _defensiveMovesEnabled = true;
      _passButtonUnlocked = false;
    });
  }

  Future<void> _attackEnemyWithKukulkan(_TutorialBoardData data) async {
    final opponentWarrior = _opponentWarrior;
    if (!_kukulkanEnemyAttackEnabled ||
        _kukulkanEnemyAttackCompleted ||
        !_kukulkanEnemyPositioned ||
        opponentWarrior == null ||
        !mounted) {
      return;
    }

    setState(() {
      _warriorAttackAnimating = true;
      opponentWarrior.animar = true;
      opponentWarrior.resplandor = true;
      opponentWarrior.vidaActual -= data.playerWarrior.ataque;
      _kukulkanEnemyAttackCompleted = true;
      _kukulkanEnemyAttackEnabled = false;
      _warriorHasAttacked = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      _warriorAttackAnimating = false;
      opponentWarrior.animar = false;
      opponentWarrior.resplandor = false;
      if (opponentWarrior.vidaActual <= 0) _opponentWarrior = null;
    });
    if (_opponentWarrior == null) {
      await _showJoanEnemyAttackInstructions(data);
      if (!mounted) return;
      setState(() => _joanEnemyAttackEnabled = true);
    }
  }

  Future<void> _showJoanEnemyAttackInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_joan_finish_enemy_title',
              'Debilita más al enemigo',
            ),
            message: _text(
              data,
              'tutorial_joan_finish_enemy_explanation',
              'Da clic sobre Juana de Arco para atacar su otro cultivo y debilitar más al enemigo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showTerracottaSummonInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_terracotta_summon_title',
              'Invoca más guerreros',
            ),
            message: _text(
              data,
              'tutorial_terracotta_summon_explanation',
              'Podemos seguir invocando guerreros para atacar a los cultivos.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showTerracottaAttackInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_terracotta_attack_title',
              '¡Al ataque!',
            ),
            message: _text(
              data,
              'tutorial_terracotta_attack_explanation',
              'Utiliza tus nuevos guerreros que no han atacado aún para destruir más cultivos enemigos. Da clic en tus guerreros terracota para atacar los cultivos.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showProtectWarriorsDialog(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_protect_warriors_title',
              'Protege a tus guerreros',
            ),
            message: _text(
              data,
              'tutorial_protect_warriors_explanation',
              'Protege a tus guerreros del ataque de Huitzilopochtli, muévelos detrás de tu hospital. Recuerda que recuperarán vida en tu siguiente turno.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showMoveWarriorsBehindHospitalDialog(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_move_warriors_title',
              'Mueve a tus guerreros',
            ),
            message: _text(
              data,
              'tutorial_move_warriors_explanation',
              'Da clic en tus guerreros y muévelos detrás de tu hospital.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showDefensiveWarriorOptionsDialog(
    _TutorialBoardData data, {
    required String warriorId,
  }) async {
    if (!_defensiveMovesEnabled ||
        _defensiveMoveTargetWarrior != null ||
        (warriorId == 'joan' && _joanDefensivelyMoved) ||
        (warriorId == 'kukulkan' &&
            (_kukulkanEnemyMoveEnabled
                ? _kukulkanEnemyPositioned
                    ? !_kukulkanEnemyAttackEnabled ||
                        _kukulkanEnemyAttackCompleted
                    : _kukulkanEnemyAttackEnabled
                : _kukulkanDefensivelyMoved)) ||
        !mounted) {
      return;
    }

    final attackingEnemy =
        warriorId == 'kukulkan' && _kukulkanEnemyAttackEnabled;
    final warrior = warriorId == 'joan' ? _playerJoan : null;
    final baseWarrior = warrior?.guerreroBase ?? data.playerWarrior;
    final health =
        warrior?.vidaActual ?? _playerWarriorHealth ?? baseWarrior.vida;
    final selected = await showDialog<bool>(
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
                      const Text('⚔️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _text(
                            data,
                            baseWarrior.nombreId,
                            baseWarrior.nombreId,
                          ),
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
                        '⚔️ ${warrior?.ataqueActual ?? baseWarrior.ataque}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '❤️ $health',
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
                      key:
                          attackingEnemy
                              ? const ValueKey(
                                'tutorial-kukulkan-enemy-attack-action',
                              )
                              : ValueKey(
                                'tutorial-$warriorId-defensive-move-action',
                              ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: Icon(
                        attackingEnemy
                            ? Icons.gps_fixed
                            : Icons.directions_walk,
                      ),
                      label: Text(
                        _text(
                          data,
                          attackingEnemy ? 'atacar' : 'mover',
                          attackingEnemy ? 'ATACAR' : 'MOVER',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            attackingEnemy ? Colors.red : Colors.blue,
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
    if (selected != true || !mounted) return;
    if (attackingEnemy) {
      await _attackEnemyWithKukulkan(data);
      return;
    }

    setState(() => _defensiveMoveTargetWarrior = warriorId);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              _kukulkanEnemyMoveEnabled
                  ? 'tutorial_kukulkan_finish_enemy_target_title'
                  : 'tutorial_move_warriors_target_title',
              'Elige una casilla',
            ),
            message: _text(
              data,
              _kukulkanEnemyMoveEnabled
                  ? 'tutorial_kukulkan_finish_enemy_target_explanation'
                  : 'tutorial_move_warriors_target_explanation',
              'Selecciona la casilla resaltada detrás del hospital para mover a tu guerrero.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _completeDefensiveWarriorMove(_TutorialBoardData data) async {
    final warriorId = _defensiveMoveTargetWarrior;
    if (!_defensiveMovesEnabled || warriorId == null || !mounted) return;
    final movingToEnemy = warriorId == 'kukulkan' && _kukulkanEnemyMoveEnabled;

    setState(() {
      _defensiveWarriorMoveAnimating = true;
      if (movingToEnemy) {
        _kukulkanEnemyPositioned = true;
      } else if (warriorId == 'joan') {
        _joanDefensivelyMoved = true;
        _playerJoan?.animar = true;
      } else {
        _kukulkanDefensivelyMoved = true;
      }
      _defensiveMoveTargetWarrior = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    setState(() {
      _defensiveWarriorMoveAnimating = false;
      _playerJoan?.animar = false;
    });
    if (movingToEnemy) {
      await _showKukulkanEnemyAttackInstructions(data);
      if (!mounted) return;
      setState(() => _kukulkanEnemyAttackEnabled = true);
      return;
    }
    if (!_joanDefensivelyMoved || !_kukulkanDefensivelyMoved) return;

    await _showPassTurnInstructions(data);
    if (!mounted) return;
    setState(() => _passButtonUnlocked = true);
  }

  Future<void> _summonAndAttackWithOpponentWarrior(
    _TutorialBoardData data,
  ) async {
    final warrior = data.opponentWarrior;
    if (_opponentPoints < warrior.costoInvocacion) {
      throw StateError(
        'La CPU no tiene puntos suficientes para invocar a Huitzilopochtli.',
      );
    }

    final warriorOnBoard = GuerreroCampo.desdeGuerrero(
      guerrero: warrior,
      coordenada: 'A3',
    )..animar = true;
    setState(() {
      _opponentPoints -= warrior.costoInvocacion;
      _opponentWarrior = warriorOnBoard;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() => warriorOnBoard.animar = false);
    final targetHealth = _playerWarriorHealth ?? data.playerWarrior.vida;
    if (!_warriorSummoned || targetHealth <= 0) return;

    setState(() {
      warriorOnBoard.animar = true;
      warriorOnBoard.yaAtacoEsteTurno = true;
      _playerWarriorTargetGlowing = true;
      _playerWarriorHealth = targetHealth - warriorOnBoard.ataqueActual;
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      warriorOnBoard.animar = false;
      _playerWarriorTargetGlowing = false;
    });
  }

  Future<void> _attackPlayerWithOpponentTower() async {
    final tower = _opponentTower;
    final hospital = _playerHospital;
    final cropColumn =
        hospital == null && _invokedPlayerCropColumns.contains(4) ? 4 : null;
    if (tower == null || (hospital == null && cropColumn == null)) return;

    setState(() {
      tower.animar = true;
      if (hospital != null) {
        hospital.resplandor = true;
        hospital.vidaActual -= tower.ataqueActual;
        if (hospital.vidaActual <= 0) {
          _playerHospital = null;
        }
      } else {
        _glowingPlayerCropColumns.add(cropColumn!);
        _playerCropHealth.update(
          cropColumn,
          (health) => health - tower.ataqueActual,
          ifAbsent: () => 0,
        );
        if (_playerCropHealth[cropColumn]! <= 0) {
          _invokedPlayerCropColumns.remove(cropColumn);
          _playerCropHealth.remove(cropColumn);
          _playerCropProduction.remove(cropColumn);
        }
      }
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      tower.animar = false;
      if (hospital != null) hospital.resplandor = false;
      if (cropColumn != null) _glowingPlayerCropColumns.remove(cropColumn);
    });
  }

  Future<void> _runOpponentTowerTurn(_TutorialBoardData data) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_ia', '🤖 IA TIRANDO DADOS...'),
      dieOne: _towerOpponentDieOne,
      dieTwo: _towerOpponentDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _opponentPoints += _towerOpponentDieOne + _towerOpponentDieTwo;
    });
    await _harvestOpponentCrops(data);
    if (!mounted) return;

    if (_opponentPoints < data.opponentTower.costoInvocacion) {
      throw StateError(
        'La CPU no tiene puntos suficientes para invocar la torre.',
      );
    }

    final tower = TorreCampo.desdeTorre(
      torre: data.opponentTower,
      coordenada: 'E3',
    )..animar = true;
    setState(() {
      _opponentPoints -= data.opponentTower.costoInvocacion;
      _opponentTower = tower;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() => tower.animar = false);
    await Future<void>.delayed(_opponentUpgradeDelay);
    if (!mounted) return;

    setState(() {
      tower.ataqueActual += _opponentPoints;
      _opponentPoints = 0;
    });

    await _runPlayerTowerDefenseTurn(data);
  }

  Future<void> _runPlayerTowerDefenseTurn(_TutorialBoardData data) async {
    await _showDiceRollDialog(
      data,
      title: _text(data, 'lanzar_dados_jugador', '🎲 TIRANDO DADOS...'),
      dieOne: _towerDefensePlayerDieOne,
      dieTwo: _towerDefensePlayerDieTwo,
    );
    if (!mounted) return;

    setState(() {
      _playerPoints += _towerDefensePlayerDieOne + _towerDefensePlayerDieTwo;
      _cropHarvestInProgress = _playerCropProduction.values.any(
        (production) => production > 0,
      );
    });
    await _harvestPlayerCrop();
    if (!mounted) return;

    setState(() => _cropHarvestInProgress = false);
    await _repairPlayerElementsWithVillager(
      data,
      showWarriorInstructions: false,
    );
    if (!mounted) return;

    await _showEnemyTowerThreatDialog(data);
    if (!mounted) return;
    await _showTowerDefenseInstructionDialog(data);
    if (!mounted) return;
    setState(() {
      _hospitalSummoningEnabled = true;
      _towerDefenseTurnCompleted = true;
    });
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
    _TutorialBoardData data, {
    bool showWarriorInstructions = true,
  }) async {
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
    if (!mounted) return;
    if (showWarriorInstructions) {
      await _showWarriorInstructions(data);
      if (!mounted) return;
      setState(() => _warriorSummoningEnabled = true);
    }
  }

  Future<void> _showEnemyTowerThreatDialog(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_enemy_tower_title',
              '¡Una torre enemiga!',
            ),
            message: _text(
              data,
              'tutorial_enemy_tower_explanation',
              'El enemigo ha construido una torre y ha incrementado su poder de ataque. Las torres atacan al primer objetivo rival que tienen enfrente al comenzar el turno. ¡Nuestro cultivo está en peligro!',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showTowerDefenseInstructionDialog(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_tower_defense_title',
              'Protege tu cultivo',
            ),
            message: _text(
              data,
              'tutorial_tower_defense_explanation',
              'Para proteger nuestro cultivo, podemos colocar algún edificio frente a él.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showWarriorInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(data, 'tutorial_summon_warrior_title', 'Guerreros'),
            message: _text(
              data,
              'tutorial_summon_warrior_explanation',
              'Es momento de invocar a un guerrero. Selecciona la casilla vacía en el tablero e invoca un guerrero.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showWarriorInvocationDialog(_TutorialBoardData data) async {
    final warrior = data.playerWarrior;
    if (!_warriorSummoningEnabled ||
        _warriorSummoned ||
        _playerPoints < warrior.costoInvocacion) {
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
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '⚔️ ${_text(data, 'guerreros', 'GUERREROS')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      key: const ValueKey('tutorial-warrior-option'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        width: 136,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[500],
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage(warrior.imagen),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _text(data, warrior.nombreId, warrior.nombreId),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚔️ ${warrior.ataque}   ❤️ ${warrior.vida}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚡ ${warrior.costoInvocacion}',
                              style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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

    if (selected != true || !mounted) return;
    if (_playerPoints < warrior.costoInvocacion) return;
    setState(() {
      _playerPoints -= warrior.costoInvocacion;
      _warriorSummoned = true;
      _playerWarriorHealth = warrior.vida;
      _warriorSummoningEnabled = false;
    });
    await _showWarriorAttackInstructions(data);
  }

  Future<void> _showEpidemicKukulkanInvocationDialog(
    _TutorialBoardData data,
  ) async {
    final warrior = data.playerWarrior;
    if (!_epidemicKukulkanSummoningEnabled ||
        _epidemicKukulkanSummoned ||
        !mounted) {
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
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '⚔️ ${_text(data, 'guerreros', 'GUERREROS')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      key: const ValueKey('tutorial-epidemic-kukulkan-option'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        width: 136,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              warrior.imagen,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _text(data, warrior.nombreId, warrior.nombreId),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚔️ ${warrior.ataque}   ❤️ ${warrior.vida}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚡ ${warrior.costoInvocacion}',
                              style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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

    if (selected != true || !mounted) return;
    if (_playerPoints < warrior.costoInvocacion) {
      throw StateError('No tienes suficientes puntos para invocar a Kukulkán.');
    }

    setState(() {
      _playerPoints -= warrior.costoInvocacion;
      _playerWarriorHealth = warrior.vida;
      _playerWarriorDestroyed = false;
      _epidemicKukulkanSummoned = true;
      _epidemicKukulkanSummoningEnabled = false;
      _warriorHasAttacked = false;
      _epidemicKukulkanWarrior = GuerreroCampo.desdeGuerrero(
        guerrero: warrior,
        coordenada: 'A2',
      );
    });
    await _showEpidemicKukulkanAttackInstructions(data);
    if (!mounted) return;
    setState(() => _epidemicKukulkanCropAttackEnabled = true);
  }

  Future<void> _showEpidemicKukulkanAttackInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_epidemic_kukulkan_attack_title',
              'Destruye el último cultivo',
            ),
            message: _text(
              data,
              'tutorial_epidemic_kukulkan_attack_explanation',
              'Da clic en Kukulkán para atacar el último cultivo enemigo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showEpidemicKukulkanAttackDialog(
    _TutorialBoardData data,
  ) async {
    final warrior = _epidemicKukulkanWarrior;
    if (!_epidemicKukulkanCropAttackEnabled ||
        warrior == null ||
        !_remainingOpponentCropColumns.contains(0) ||
        !mounted) {
      return;
    }

    final shouldAttack = await _showTutorialWarriorAttackDialog(
      data,
      warrior: warrior,
      actionKey: const ValueKey('tutorial-epidemic-kukulkan-attack-action'),
    );
    if (shouldAttack && mounted) {
      await _attackLastOpponentCropWithKukulkan(data, warrior);
    }
  }

  Future<bool> _showTutorialWarriorAttackDialog(
    _TutorialBoardData data, {
    required GuerreroCampo warrior,
    required Key actionKey,
  }) async {
    return await showDialog<bool>(
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
                          const Text('⚔️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _text(
                                data,
                                warrior.guerreroBase.nombreId,
                                warrior.guerreroBase.nombreId,
                              ),
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
                            '⚔️ ${warrior.ataqueActual}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '❤️ ${warrior.vidaActual}',
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
                          key: actionKey,
                          onPressed: () => Navigator.pop(dialogContext, true),
                          icon: const Icon(Icons.gps_fixed),
                          label: Text(_text(data, 'atacar', 'ATACAR')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
        ) ??
        false;
  }

  Future<void> _attackLastOpponentCropWithKukulkan(
    _TutorialBoardData data,
    GuerreroCampo warrior,
  ) async {
    if (!_epidemicKukulkanCropAttackEnabled ||
        !_remainingOpponentCropColumns.contains(0) ||
        warrior.ataqueActual < data.opponentCrop.vida ||
        !mounted) {
      return;
    }

    setState(() {
      _warriorAttackAnimating = true;
      warrior.animar = true;
      warrior.yaAtacoEsteTurno = true;
      _glowingOpponentCropColumns.add(0);
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      _remainingOpponentCropColumns.remove(0);
      _glowingOpponentCropColumns.remove(0);
      _warriorAttackAnimating = false;
      warrior.animar = false;
      _epidemicKukulkanCropAttackEnabled = false;
      _monumentAttacksEnabled = true;
      _monumentAttackedWarriors.clear();
    });

    await _showEnemyMonumentAttackInstructions(data);
    if (!mounted) return;
    setState(() => _monumentAttacksEnabled = true);
  }

  Future<void> _showEnemyMonumentAttackInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_enemy_monument_attack_title',
              'Ataca el monumento',
            ),
            message: _text(
              data,
              'tutorial_enemy_monument_attack_explanation',
              'El enemigo ya no tiene otros elementos en el tablero. Tus guerreros pueden atacar libremente el monumento desde donde están; no es necesario moverlos. Da clic en cada guerrero que no haya atacado y selecciona Atacar.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showMonumentAttackDialog(
    _TutorialBoardData data, {
    required String warriorId,
  }) async {
    if (!_monumentAttacksEnabled ||
        _monumentAttackedWarriors.contains(warriorId) ||
        !mounted) {
      return;
    }

    final warrior = switch (warriorId) {
      'kukulkan' => _epidemicKukulkanWarrior,
      'joan' => _playerJoan,
      'terracotta-1' => _playerTerracottaWarriors[1],
      'terracotta-3' => _playerTerracottaWarriors[3],
      _ => null,
    };
    if (warrior == null ||
        warrior.yaAtacoEsteTurno ||
        warriorId == 'kukulkan') {
      return;
    }

    final shouldAttack = await _showTutorialWarriorAttackDialog(
      data,
      warrior: warrior,
      actionKey: ValueKey('tutorial-monument-attack-action-$warriorId'),
    );
    if (shouldAttack && mounted) {
      await _attackEnemyMonument(data, warriorId: warriorId, warrior: warrior);
    }
  }

  Future<void> _attackEnemyMonument(
    _TutorialBoardData data, {
    required String warriorId,
    required GuerreroCampo warrior,
  }) async {
    if (!_monumentAttacksEnabled ||
        _monumentAttackedWarriors.contains(warriorId) ||
        !mounted) {
      return;
    }

    setState(() {
      warrior.animar = true;
      warrior.resplandor = true;
      warrior.yaAtacoEsteTurno = true;
      if (warriorId == 'joan') _joanHasAttacked = true;
      _opponentMonumentTargetGlowing = true;
      _opponentMonumentHealth =
          (_opponentMonumentHealth ?? data.opponentCivilization.muralla.vida) -
          warrior.ataqueActual;
      _monumentAttackedWarriors.add(warriorId);
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      warrior.animar = false;
      warrior.resplandor = false;
      _opponentMonumentTargetGlowing = false;
    });

    if (_monumentAttackedWarriors.length == 3) {
      setState(() => _monumentAttacksEnabled = false);
      await _showPassTurnInstructions(data);
      if (!mounted) return;
      setState(() => _passButtonUnlocked = true);
    }
  }

  Future<void> _showTerracottaInvocationDialog(
    _TutorialBoardData data,
    int column,
  ) async {
    final warrior = data.terracottaWarrior;
    if (!_terracottaSummoningEnabled ||
        (column != 1 && column != 3) ||
        _playerTerracottaWarriors.containsKey(column) ||
        !mounted) {
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
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '⚔️ ${_text(data, 'guerreros', 'GUERREROS')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      key: ValueKey('tutorial-terracotta-option-$column'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        width: 136,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              warrior.imagen,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _text(data, warrior.nombreId, warrior.nombreId),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚔️ ${warrior.ataque}   ❤️ ${warrior.vida}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚡ ${warrior.costoInvocacion}',
                              style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
    if (selected != true || !mounted) return;
    if (_playerPoints < warrior.costoInvocacion) {
      throw StateError(
        'No tienes suficientes puntos para invocar al guerrero terracota.',
      );
    }

    final warriorOnBoard = GuerreroCampo.desdeGuerrero(
      guerrero: warrior,
      coordenada: column == 1 ? 'B2' : 'D2',
    )..animar = true;
    final allTerracottaWarriorsSummoned = _playerTerracottaWarriors.length == 1;
    setState(() {
      _playerPoints -= warrior.costoInvocacion;
      _playerTerracottaWarriors[column] = warriorOnBoard;
      if (_playerTerracottaWarriors.length == 2) {
        _terracottaSummoningEnabled = false;
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => warriorOnBoard.animar = false);
    if (allTerracottaWarriorsSummoned) {
      await _showTerracottaAttackInstructions(data);
      if (!mounted) return;
      setState(() => _terracottaAttackEnabled = true);
    }
  }

  Future<void> _showTerracottaAttackDialog(
    _TutorialBoardData data,
    int column,
  ) async {
    final warrior = _playerTerracottaWarriors[column];
    if (!_terracottaAttackEnabled ||
        warrior == null ||
        _terracottaAttackedColumns.contains(column) ||
        !mounted) {
      return;
    }

    final action = await showDialog<bool>(
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
                      const Text('⚔️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _text(
                            data,
                            warrior.guerreroBase.nombreId,
                            warrior.guerreroBase.nombreId,
                          ),
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
                        '⚔️ ${warrior.ataqueActual}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '❤️ ${warrior.vidaActual}',
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
                      key: ValueKey(
                        'tutorial-terracotta-attack-action-$column',
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.gps_fixed),
                      label: Text(_text(data, 'atacar', 'ATACAR')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
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

    if (action == true && mounted) {
      await _attackWithTerracotta(data, column);
    }
  }

  Future<void> _showPlagueTerracottaAttackDialog(
    _TutorialBoardData data,
  ) async {
    final warrior = _playerTerracottaWarriors[3];
    if (!_plagueTerracottaAttackEnabled ||
        _plagueTerracottaAttackCompleted ||
        warrior == null ||
        warrior.yaAtacoEsteTurno ||
        !_remainingOpponentCropColumns.contains(3) ||
        !mounted) {
      return;
    }

    final action = await showDialog<bool>(
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
                      const Text('⚔️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _text(
                            data,
                            warrior.guerreroBase.nombreId,
                            warrior.guerreroBase.nombreId,
                          ),
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
                        '⚔️ ${warrior.ataqueActual}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '❤️ ${warrior.vidaActual}',
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
                      key: const ValueKey(
                        'tutorial-plague-terracotta-attack-action',
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.gps_fixed),
                      label: Text(_text(data, 'atacar', 'ATACAR')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
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

    if (action == true && mounted) {
      await _attackCropWithPlagueTerracotta(data, warrior);
    }
  }

  Future<void> _attackCropWithPlagueTerracotta(
    _TutorialBoardData data,
    GuerreroCampo warrior,
  ) async {
    if (!_plagueTerracottaAttackEnabled ||
        _plagueTerracottaAttackCompleted ||
        !_remainingOpponentCropColumns.contains(3) ||
        !mounted) {
      return;
    }
    if (warrior.ataqueActual < data.opponentCrop.vida) {
      throw StateError(
        'El guerrero terracota no pudo destruir el cultivo objetivo.',
      );
    }

    setState(() {
      warrior.animar = true;
      warrior.yaAtacoEsteTurno = true;
      _glowingOpponentCropColumns.add(3);
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      _remainingOpponentCropColumns.remove(3);
      _glowingOpponentCropColumns.remove(3);
      warrior.animar = false;
      _plagueTerracottaAttackEnabled = false;
      _plagueTerracottaAttackCompleted = true;
    });
    await _showFinalJoanUpgradeInstructions(data);
  }

  Future<void> _showFinalJoanUpgradeInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_final_joan_upgrade_title',
              'Mejora el ataque de Juana de Arco',
            ),
            message: _text(
              data,
              'tutorial_final_joan_upgrade_explanation',
              'Los guerreros pueden aumentar su ataque con tus puntos de invocación. Utilízalos para aumentar el ataque de Juana de Arco: da clic sobre ella y selecciona la opción de incrementar ataque.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
    if (!mounted) return;
    setState(() => _finalJoanAttackUpgradeEnabled = true);
  }

  Future<void> _showFinalJoanUpgradeOptionsDialog(
    _TutorialBoardData data,
  ) async {
    final joan = _playerJoan;
    if (!_finalJoanAttackUpgradeEnabled || joan == null || !mounted) return;
    if (_playerPoints < _finalJoanAttackUpgradeMinimum) {
      throw StateError(
        'Juana necesita al menos $_finalJoanAttackUpgradeMinimum puntos de invocación para mejorar su ataque.',
      );
    }

    final selectedUpgrade = await showDialog<bool>(
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
                  Text(
                    _text(
                      data,
                      joan.guerreroBase.nombreId,
                      joan.guerreroBase.nombreId,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⚔️ ${joan.ataqueActual}   ❤️ ${joan.vidaActual}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const ValueKey(
                        'tutorial-joan-upgrade-attack-action',
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Text('💪'),
                      label: Text(
                        _text(data, 'mejorar_ataque', 'MEJORAR ATAQUE'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
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
    if (selectedUpgrade == true && mounted) {
      await _showFinalJoanAttackUpgradeSlider(data, joan);
    }
  }

  Future<void> _showFinalJoanAttackUpgradeSlider(
    _TutorialBoardData data,
    GuerreroCampo joan,
  ) async {
    final availablePoints = _playerPoints;
    if (availablePoints < _finalJoanAttackUpgradeMinimum) {
      throw StateError(
        'Juana necesita al menos $_finalJoanAttackUpgradeMinimum puntos de invocación para mejorar su ataque.',
      );
    }

    final pointsToSpend = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        var selectedPoints = _finalJoanAttackUpgradeMinimum.toDouble();
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
                        '💪 ${_text(data, 'mejorar_ataque', 'MEJORAR ATAQUE')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_text(data, 'valor_actual', 'Valor actual:')} ${joan.ataqueActual}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '⚡ $availablePoints ${_text(data, 'disponibles', 'disponibles')}',
                        style: const TextStyle(color: _gold),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        key: const ValueKey(
                          'tutorial-joan-attack-upgrade-slider',
                        ),
                        value: selectedPoints,
                        min: _finalJoanAttackUpgradeMinimum.toDouble(),
                        max: availablePoints.toDouble(),
                        divisions:
                            availablePoints > _finalJoanAttackUpgradeMinimum
                                ? availablePoints -
                                    _finalJoanAttackUpgradeMinimum
                                : null,
                        activeColor: Colors.orange,
                        onChanged:
                            availablePoints > _finalJoanAttackUpgradeMinimum
                                ? (value) =>
                                    setDialogState(() => selectedPoints = value)
                                : null,
                      ),
                      Text(
                        '${selectedPoints.toInt()} ⚡',
                        key: const ValueKey(
                          'tutorial-joan-attack-upgrade-points',
                        ),
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
                              child: Text(_text(data, 'cancelar', 'CANCELAR')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              key: const ValueKey(
                                'tutorial-confirm-joan-attack-upgrade',
                              ),
                              onPressed:
                                  () => Navigator.pop(
                                    dialogContext,
                                    selectedPoints.toInt(),
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: Text(_text(data, 'mejorar', 'MEJORAR')),
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
    if (pointsToSpend < _finalJoanAttackUpgradeMinimum ||
        pointsToSpend > _playerPoints) {
      throw StateError('La cantidad de puntos para la mejora no es válida.');
    }

    setState(() {
      joan.ataqueActual += pointsToSpend;
      _playerPoints -= pointsToSpend;
      _finalJoanAttackUpgradeEnabled = false;
    });
    await _showFinalJoanMonumentAttackInstructions(data);
    if (!mounted) return;
    setState(() => _finalJoanMonumentAttackEnabled = true);
  }

  Future<void> _showFinalJoanMonumentAttackInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_enemy_monument_attack_title',
              'Ataca el monumento',
            ),
            message: _text(
              data,
              'tutorial_final_joan_monument_attack_explanation',
              'El monumento tiene 48 puntos de vida. Da clic en Kukulkán, el guerrero terracota y Juana de Arco para que ataquen; sus ataques suman más que la vida restante.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showFinalMonumentAttackDialog(
    _TutorialBoardData data, {
    required String warriorId,
  }) async {
    final warrior = switch (warriorId) {
      'kukulkan' => _epidemicKukulkanWarrior,
      'terracotta-1' => _playerTerracottaWarriors[1],
      'terracotta-3' => _playerTerracottaWarriors[3],
      'joan' => _playerJoan,
      _ => null,
    };
    if (!_finalJoanMonumentAttackEnabled ||
        _finalMonumentDestroyed ||
        warrior == null ||
        warrior.yaAtacoEsteTurno ||
        _finalMonumentAttackedWarriors.contains(warriorId) ||
        !mounted) {
      return;
    }
    final shouldAttack = await _showTutorialWarriorAttackDialog(
      data,
      warrior: warrior,
      actionKey: ValueKey('tutorial-final-monument-attack-action-$warriorId'),
    );
    if (shouldAttack && mounted) {
      await _attackFinalMonumentWithWarrior(data, warriorId, warrior);
    }
  }

  Future<void> _attackFinalMonumentWithWarrior(
    _TutorialBoardData data,
    String warriorId,
    GuerreroCampo warrior,
  ) async {
    final monumentHealth =
        _opponentMonumentHealth ?? data.opponentCivilization.muralla.vida;
    if (!_finalJoanMonumentAttackEnabled ||
        _finalMonumentDestroyed ||
        warrior.yaAtacoEsteTurno ||
        _finalMonumentAttackedWarriors.contains(warriorId) ||
        !mounted) {
      return;
    }

    setState(() {
      warrior.animar = true;
      warrior.resplandor = true;
      warrior.yaAtacoEsteTurno = true;
      _opponentMonumentTargetGlowing = true;
      _opponentMonumentHealth = (monumentHealth - warrior.ataqueActual).clamp(
        0,
        monumentHealth,
      );
      _finalMonumentAttackedWarriors.add(warriorId);
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final monumentDestroyed = _opponentMonumentHealth == 0;
    setState(() {
      warrior.animar = false;
      warrior.resplandor = false;
      _opponentMonumentTargetGlowing = false;
    });
    if (!monumentDestroyed) return;

    setState(() {
      _finalJoanMonumentAttackEnabled = false;
      _finalMonumentDestroyed = true;
      _monumentTurnSequenceCompleted = true;
    });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_final_monument_destroyed_title',
              '¡Victoria!',
            ),
            message: _text(
              data,
              'tutorial_final_monument_destroyed_explanation',
              'Tus guerreros destruyeron el monumento enemigo. ¡Has ganado!',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_farewell_title',
              '¡Gracias por jugar!',
            ),
            message: _text(
              data,
              'tutorial_farewell_explanation',
              'Mitic es un juego de libre decisión. Sé creativo para derrotar a tu enemigo y diviértete intentándolo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
    if (!mounted) return;

    Navigator.pushAndRemoveUntil<void>(
      context,
      MaterialPageRoute<void>(
        builder:
            (context) =>
                GameModeScreen(selectedLanguage: widget.selectedLanguage),
      ),
      (route) => false,
    );
  }

  Future<void> _attackWithTerracotta(
    _TutorialBoardData data,
    int column,
  ) async {
    final warrior = _playerTerracottaWarriors[column];
    if (!_terracottaAttackEnabled ||
        warrior == null ||
        _terracottaAttackedColumns.contains(column) ||
        !_remainingOpponentCropColumns.contains(column) ||
        !mounted) {
      return;
    }
    if (warrior.ataqueActual < data.opponentCrop.vida) {
      throw StateError(
        'El guerrero terracota no pudo destruir el cultivo objetivo.',
      );
    }

    setState(() {
      warrior.animar = true;
      warrior.yaAtacoEsteTurno = true;
      _glowingOpponentCropColumns.add(column);
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      _remainingOpponentCropColumns.remove(column);
      _glowingOpponentCropColumns.remove(column);
      _terracottaAttackedColumns.add(column);
      warrior.animar = false;
      _terracottaAttackEnabled = _terracottaAttackedColumns.length < 2;
    });
    if (_terracottaAttackedColumns.length == 2) {
      await _showTerracottaPassTurnInstructions(data);
      if (!mounted) return;
      setState(() => _passButtonUnlocked = true);
    }
  }

  Future<void> _showTerracottaPassTurnInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_terracotta_pass_turn_title',
              'Termina tu turno',
            ),
            message: _text(
              data,
              'tutorial_terracotta_pass_turn_explanation',
              'No tenemos más guerreros para atacar. Presiona Pasar para terminar tu turno.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showHospitalInvocationDialog(_TutorialBoardData data) async {
    final hospital = data.playerHospital;
    if (!_hospitalSummoningEnabled ||
        _playerHospital != null ||
        _playerPoints < hospital.costoInvocacion) {
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
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '🏥 ${_text(data, 'modal_hospital', 'HOSPITAL')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: InkWell(
                      key: const ValueKey('tutorial-hospital-option'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(dialogContext, true),
                      child: Container(
                        width: 136,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              hospital.imagen,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _text(
                                data,
                                '${hospital.id}_nombre',
                                hospital.nombre,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '💊 ${hospital.poderCuracion}   ❤️ ${hospital.vida}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '⚡ ${hospital.costoInvocacion}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

    if (selected != true || !mounted) return;
    if (_playerPoints < hospital.costoInvocacion) return;
    setState(() {
      _playerPoints -= hospital.costoInvocacion;
      _playerHospital = HospitalCampo.desdeHospital(
        hospital: hospital,
        coordenada: 'E0',
      );
      _hospitalSummoningEnabled = false;
    });
    await _showHospitalHealingInstructions(data);
    if (!mounted) return;
    await _showHospitalWarriorStrategyInstructions(data);
    if (!mounted) return;
    setState(() {
      _warriorDefenseMoveEnabled = true;
      _warriorHasAttacked = false;
      _passButtonUnlocked = false;
    });
  }

  Future<void> _showHospitalHealingInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_hospital_healing_title',
              'Curación del hospital',
            ),
            message: _text(
              data,
              'tutorial_hospital_healing_explanation',
              'Los hospitales curan a tus guerreros y aldeanos que se encuentran en su misma fila y columna. Al inicio de cada turno, los hospitales usan su poder de curación 💊 para aumentar la vida de tus guerreros y aldeanos.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showHospitalWarriorStrategyInstructions(
    _TutorialBoardData data,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_hospital_warrior_strategy_title',
              'Aprovecha el hospital',
            ),
            message: _text(
              data,
              'tutorial_hospital_warrior_strategy_explanation',
              'No olvides atacar en cada uno de tus turnos cuando sea posible. Mueve tu guerrero para atacar otro cultivo y que se beneficie estratégicamente de tu hospital.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showWarriorAttackInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_warrior_attack_title',
              'Ataque de los guerreros',
            ),
            message: _text(
              data,
              'tutorial_warrior_attack_explanation',
              'Los guerreros atacan al primer elemento enemigo que se encuentre frente a ellos. Pero ¡atención!: no puedes atacar el monumento hasta que sea el único elemento que quede en el tablero.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
    if (!mounted) return;
    await _showWarriorMoveInstructions(data);
  }

  Future<void> _showWarriorMoveInstructions(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_warrior_move_title',
              'Mueve a tu guerrero',
            ),
            message: _text(
              data,
              'tutorial_warrior_move_explanation',
              'Mueve tu guerrero a una posición conveniente para que pueda atacar algún cultivo del rival. Para hacerlo, da clic en el guerrero y selecciona la opción de mover.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showWarriorOptionsDialog(_TutorialBoardData data) async {
    if (!_warriorSummoned ||
        _warriorMoveTargetEnabled ||
        _warriorHasAttacked ||
        !mounted) {
      return;
    }

    final canMoveWarrior =
        _warriorMoveCount == 0 ||
        (_warriorDefenseMoveEnabled && _warriorMoveCount == 1);
    final warrior = data.playerWarrior;
    final action = await showDialog<String>(
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
                      const Text('⚔️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _text(data, warrior.nombreId, warrior.nombreId),
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
                        '⚔️ ${warrior.ataque}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '❤️ ${warrior.vida}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!canMoveWarrior)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const ValueKey('tutorial-warrior-attack-action'),
                        onPressed: () => Navigator.pop(dialogContext, 'attack'),
                        icon: const Icon(Icons.gps_fixed),
                        label: Text(_text(data, 'atacar', 'ATACAR')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (canMoveWarrior)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const ValueKey('tutorial-warrior-move-action'),
                        onPressed: () => Navigator.pop(dialogContext, 'move'),
                        icon: const Icon(Icons.directions_walk),
                        label: Text(_text(data, 'mover', 'MOVER')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
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

    if (!mounted) return;
    if (action == 'attack') {
      if (_finalPlayerTurnActive) {
        await _attackWithKukulkan(data);
      } else {
        await _attackOpponentCrop(data);
      }
      return;
    }
    if (action != 'move' || !canMoveWarrior) return;
    setState(() => _warriorMoveTargetEnabled = true);
    final movingForHospital =
        _warriorDefenseMoveEnabled && _warriorMoveCount == 1;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              movingForHospital
                  ? 'tutorial_warrior_hospital_move_target_title'
                  : 'tutorial_warrior_move_target_title',
              'Elige una posición',
            ),
            message: _text(
              data,
              movingForHospital
                  ? 'tutorial_warrior_hospital_move_target_explanation'
                  : 'tutorial_warrior_move_target_explanation',
              movingForHospital
                  ? 'Selecciona la casilla resaltada para colocar a tu guerrero en la misma fila que el hospital y frente a otro cultivo enemigo.'
                  : 'Selecciona la casilla resaltada para colocar a Kukulkan frente a un cultivo enemigo.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _attackOpponentCrop(_TutorialBoardData data) async {
    final targetColumn = _warriorMoveCount >= 2 ? 0 : 1;
    if (_warriorMoveCount == 0 ||
        _warriorHasAttacked ||
        !_remainingOpponentCropColumns.contains(targetColumn) ||
        !mounted) {
      return;
    }

    setState(() {
      _warriorAttackAnimating = true;
      _glowingOpponentCropColumns.add(targetColumn);
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final cropDestroyed = data.playerWarrior.ataque >= data.opponentCrop.vida;
    setState(() {
      if (cropDestroyed) {
        _remainingOpponentCropColumns.remove(targetColumn);
      }
      _glowingOpponentCropColumns.remove(targetColumn);
      _warriorAttackAnimating = false;
      _warriorHasAttacked = true;
    });

    if (_warriorMoveCount < 2) {
      await _showWarriorAttackDamageDialog(data);
      if (!mounted) return;
      await _showWarriorTurnLimitDialog(data);
      if (!mounted) return;
    }
    setState(() => _passButtonUnlocked = true);
  }

  Future<void> _showWarriorAttackDamageDialog(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_warrior_damage_title',
              'Daño de ataque',
            ),
            message: _text(
              data,
              'tutorial_warrior_damage_explanation',
              'Los puntos de ataque de tu guerrero ⚔️ se restarán de los puntos de vida de tu objetivo. Si sus puntos de vida son menores o iguales que los puntos de ataque de tu guerrero, el elemento será destruido.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
  }

  Future<void> _showWarriorTurnLimitDialog(_TutorialBoardData data) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _buildTutorialDialog(
            title: _text(
              data,
              'tutorial_warrior_turn_limit_title',
              'Ataque por turno',
            ),
            message: _text(
              data,
              'tutorial_warrior_turn_limit_explanation',
              'Los guerreros solo atacan una vez por turno. Podrán volver a atacar cuando comience tu siguiente turno. Presiona Pasar para terminar tu turno.',
            ),
            buttonText: _text(data, 'tutorial_dice_continue', 'Entendido'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
    );
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
    final points = _remainingOpponentCropColumns.fold<int>(
      0,
      (total, column) =>
          total +
          (_opponentCropProduction[column] ?? data.opponentCrop.puntosPorTurno),
    );
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
      _playerVillagerHealth = villager.vida;
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
  final Guerrero playerWarrior;
  final Guerrero opponentWarrior;
  final Guerrero joanWarrior;
  final Guerrero terracottaWarrior;
  final Torre opponentTower;
  final Hospital playerHospital;

  const _TutorialBoardData({
    required this.translations,
    required this.opponentCivilization,
    required this.playerCivilization,
    required this.opponentCrop,
    required this.playerCrop,
    required this.playerVillager,
    required this.playerWarrior,
    required this.opponentWarrior,
    required this.joanWarrior,
    required this.terracottaWarrior,
    required this.opponentTower,
    required this.playerHospital,
  });
}
