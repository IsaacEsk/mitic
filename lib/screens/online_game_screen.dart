import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mitic/models/aldeano_model.dart';
import 'package:mitic/models/civilizacion_model.dart';
import 'package:mitic/models/cultivo_model.dart';
import 'package:mitic/models/guerrero_model.dart';
import 'package:mitic/models/hospital_model.dart';
import 'package:mitic/models/online_game_state.dart';
import 'package:mitic/models/online_room.dart';
import 'package:mitic/models/torre_model.dart';
import 'package:mitic/services/mitic2_data_service.dart';
import 'package:mitic/services/online_rooms_service.dart';
import 'package:mitic/services/translationService.dart';
import 'package:mitic/widgets/monumento_tablero.dart';

class OnlineGameScreen extends StatefulWidget {
  final OnlineRoom room;
  final String uid;
  final String selectedLanguage;

  const OnlineGameScreen({
    super.key,
    required this.room,
    required this.uid,
    required this.selectedLanguage,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  static const _gold = Color(0xFFFFC857);
  static const _harvestAnimationDuration = Duration(milliseconds: 1300);
  static const _hospitalAnimationDuration = Duration(milliseconds: 800);
  static const _hammerHitDuration = Duration(milliseconds: 100);
  static const _hammerPauseDuration = Duration(milliseconds: 80);
  static const _towerChargeDuration = Duration(milliseconds: 400);
  static const _towerAttackDuration = Duration(milliseconds: 500);
  static const _disasterModalDuration = Duration(seconds: 4);
  late final Stream<OnlineGameState> _gameStream;
  late final Future<_OnlineBoardData> _boardData;
  Map<String, String> _translations = {};
  String? _diceRollInProgress;
  int? _displayedDiceRollTurn;
  int? _shownEarthquakeTurn;
  int? _shownPlagueTurn;
  int? _shownEpidemicTurn;
  String? _shownVictoryRole;
  Future<void> _modalDialogQueue = Future<void>.value();
  final Map<String, Future<void>> _pendingModalDialogs = {};
  bool _passingTurn = false;
  bool _leaving = false;
  String? _summoningCoordinate;
  String? _movingVillagerCoordinate;
  String? _movingVillagerRole;
  int? _movingVillagerTurn;
  String? _movingWarriorCoordinate;
  String? _movingWarriorRole;
  int? _movingWarriorTurn;
  bool _pieceUpgradeInProgress = false;
  bool _warriorAttackInProgress = false;
  int? _harvestingTurn;
  int? _shownHarvestTurn;
  int? _cropAnimationTurn;
  int? _shownHospitalHealingTurn;
  int? _hospitalAnimationTurn;
  int? _shownVillagerRepairTurn;
  int? _villagerAnimationTurn;
  int? _runningTowerAttackTurn;
  int? _shownTowerAttackTurn;
  int? _shownTowerAttackIndex;
  int? _towerAttackAnimationTurn;
  int? _towerAttackAnimationIndex;
  bool _towerAttackReleasing = false;
  final Map<String, Completer<void>> _towerAttackAnimationCompleters = {};
  final Set<String> _completedTowerAttackAnimations = {};
  OverlayEntry? _harvestOverlay;

  @override
  void initState() {
    super.initState();
    _gameStream = OnlineRoomsService.watchGame(widget.room.id);
    _boardData = _loadBoardData();
  }

  Future<_OnlineBoardData> _loadBoardData() async {
    final data = await Mitic2DataService.cargarTodo(
      locale: widget.selectedLanguage,
    );
    final rawCivilizations = data['civilizaciones'];
    if (rawCivilizations is! Map<String, Civilizacion>) {
      throw StateError('No se pudieron cargar las civilizaciones.');
    }
    final translations = await TranslationService.loadTranslations(
      widget.selectedLanguage,
    );
    if (translations.isEmpty) {
      throw StateError('No se pudieron cargar las traducciones.');
    }
    if (mounted) setState(() => _translations = translations);
    final warriors = data['guerreros'];
    if (warriors is! Map<String, Guerrero>) {
      throw StateError('No se pudieron cargar los guerreros.');
    }
    final towers = await Mitic2DataService.cargarTorres();
    final hospitals = await Mitic2DataService.cargarHospitales();
    final crops = await Mitic2DataService.cargarCultivos();
    final villagers = await Mitic2DataService.cargarAldeanos();
    return _OnlineBoardData(
      civilizations: rawCivilizations,
      warriors: warriors,
      towers: towers,
      hospitals: hospitals,
      crops: crops,
      villagers: villagers,
    );
  }

  String _text(String key, String spanish, String english) =>
      _translations[key] ??
      (widget.selectedLanguage == 'en' ? english : spanish);

  Future<void> _passTurn() async {
    if (_passingTurn || _leaving) return;
    setState(() => _passingTurn = true);
    try {
      final passed = await OnlineRoomsService.passTurn(
        room: widget.room,
        uid: widget.uid,
      );
      if (!passed && mounted) {
        _showMessage(
          _text(
            'online_not_your_turn',
            'No es tu turno para pasar.',
            'It is not your turn to pass.',
          ),
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _passingTurn = false);
    }
  }

  void _ensureTurnDiceRoll(OnlineGameState game, String role) {
    if (game.diceRolledTurn == game.turn) return;
    final rollKey = '$role-${game.turn}';
    if (_diceRollInProgress == rollKey) return;
    _diceRollInProgress = rollKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rollTurnDice(game.turn, role, rollKey);
    });
  }

  Future<void> _rollTurnDice(int turn, String role, String rollKey) async {
    final random = Random();
    final firstDie = random.nextInt(6) + 1;
    final secondDie = random.nextInt(6) + 1;
    try {
      if (!mounted || _leaving) return;
      final earthquake = await OnlineRoomsService.resolveEarthquakeForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: turn,
      );
      if (!earthquake.committed) {
        _showMessage(
          _text(
            'online_earthquake_failed',
            'No se pudo resolver el terremoto de este turno.',
            'Could not resolve this turn’s earthquake.',
          ),
        );
        return;
      }
      final earthquakeEvent = earthquake.event;
      if (earthquakeEvent != null) {
        await _showEarthquakeEvent(earthquakeEvent);
      }
      if (!mounted || _leaving || earthquake.gameFinished) return;

      final plague = await OnlineRoomsService.resolvePlagueForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: turn,
      );
      if (!plague.committed) {
        _showMessage(
          _text(
            'online_plague_failed',
            'No se pudo resolver la plaga de este turno.',
            'Could not resolve this turn’s plague.',
          ),
        );
        return;
      }
      final plagueEvent = plague.event;
      if (plagueEvent != null) await _showPlagueEvent(plagueEvent);
      if (!mounted || _leaving) return;

      final epidemic = await OnlineRoomsService.resolveEpidemicForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: turn,
      );
      if (!epidemic.committed) {
        _showMessage(
          _text(
            'online_epidemic_failed',
            'No se pudo resolver la epidemia de este turno.',
            'Could not resolve this turn’s epidemic.',
          ),
        );
        return;
      }
      final epidemicEvent = epidemic.event;
      if (epidemicEvent != null) await _showEpidemicEvent(epidemicEvent);
      if (!mounted || _leaving) return;

      final committed = await OnlineRoomsService.rollDiceForTurn(
        room: widget.room,
        uid: widget.uid,
        turn: turn,
        firstDie: firstDie,
        secondDie: secondDie,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_dice_roll_not_saved',
            'No se pudo guardar la tirada. Vuelve a entrar a la sala para intentarlo de nuevo.',
            'The dice roll could not be saved. Rejoin the room to try again.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_dice_roll_error',
            'Error al tirar los dados: {error}',
            'Dice roll error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (_diceRollInProgress == rollKey) _diceRollInProgress = null;
    }
  }

  Future<void> _showEarthquakeEvent(OnlineEarthquakeEvent event) async {
    return _enqueueModalDialog(
      key: 'earthquake-${event.turn}',
      isShown: () => _shownEarthquakeTurn == event.turn,
      markShown: () => _shownEarthquakeTurn = event.turn,
      show: () => _displayEarthquakeEvent(event),
    );
  }

  Future<void> _displayEarthquakeEvent(OnlineEarthquakeEvent event) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future<void>.delayed(_disasterModalDuration, () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
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
                const Text('🌍', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                Text(
                  _text(
                    'desastre_terremoto_titulo',
                    '🌍 TERREMOTO 🌍',
                    '🌍 EARTHQUAKE 🌍',
                  ),
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
                    'desastre_terremoto_mensaje',
                    'La tierra tiembla...',
                    'The earth trembles...',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  event.damage > 0
                      ? _text(
                        'online_earthquake_damage',
                        'Daño: {damage}',
                        'Damage: {damage}',
                      ).replaceAll('{damage}', '${event.damage}')
                      : _text(
                        'online_earthquake_no_buildings',
                        'No había edificios afectados.',
                        'There were no buildings to affect.',
                      ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (event.monumentDestroyed) ...[
                  const SizedBox(height: 8),
                  Text(
                    _text(
                      'online_earthquake_monument_destroyed',
                      '¡El terremoto destruyó el monumento!',
                      'The earthquake destroyed the monument!',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  _text(
                    'online_disaster_closing',
                    '⏳ Cerrando en 4 segundos...',
                    '⏳ Closing in 4 seconds...',
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

  Future<void> _showPlagueEvent(OnlineDisasterEvent event) async {
    return _enqueueModalDialog(
      key: 'plague-${event.turn}',
      isShown: () => _shownPlagueTurn == event.turn,
      markShown: () => _shownPlagueTurn = event.turn,
      show: () => _displayPlagueEvent(event),
    );
  }

  Future<void> _displayPlagueEvent(OnlineDisasterEvent event) async {
    await _showBoardDisasterDialog(
      icon: '🌾',
      title: _text('desastre_plaga_titulo', '🌾 PLAGA 🌾', '🌾 PLAGUE 🌾'),
      description: _text(
        'desastre_plaga_mensaje',
        'Una plaga arrasa los cultivos.',
        'A plague is ravaging the crops.',
      ),
      event: event,
      showingZeroDamage: _text(
        'online_plague_no_crops',
        'No había cultivos afectados.',
        'There were no crops to affect.',
      ),
    );
  }

  Future<void> _showEpidemicEvent(OnlineDisasterEvent event) async {
    return _enqueueModalDialog(
      key: 'epidemic-${event.turn}',
      isShown: () => _shownEpidemicTurn == event.turn,
      markShown: () => _shownEpidemicTurn = event.turn,
      show: () => _displayEpidemicEvent(event),
    );
  }

  Future<void> _displayEpidemicEvent(OnlineDisasterEvent event) async {
    await _showBoardDisasterDialog(
      icon: '🦠',
      title: _text(
        'desastre_epidemia_titulo',
        '🦠 EPIDEMIA 🦠',
        '🦠 EPIDEMIC 🦠',
      ),
      description: _text(
        'desastre_epidemia_mensaje',
        'Una epidemia afecta a las unidades.',
        'An epidemic is affecting the units.',
      ),
      event: event,
      showingZeroDamage: _text(
        'online_epidemic_no_units',
        'No había guerreros ni aldeanos afectados.',
        'There were no warriors or villagers to affect.',
      ),
    );
  }

  Future<void> _enqueueModalDialog({
    required String key,
    required bool Function() isShown,
    required VoidCallback markShown,
    required Future<void> Function() show,
  }) {
    if (!mounted || _leaving || isShown()) return Future<void>.value();
    final existing = _pendingModalDialogs[key];
    if (existing != null) return existing;

    final completer = Completer<void>();
    _pendingModalDialogs[key] = completer.future;
    _modalDialogQueue = _modalDialogQueue.then((_) async {
      try {
        if (!mounted || _leaving || isShown()) return;
        markShown();
        await show();
      } catch (error) {
        if (mounted && !_leaving) {
          _showMessage(
            _text(
              'online_modal_error',
              'No se pudo mostrar el modal: {error}',
              'Could not show the dialog: {error}',
            ).replaceAll('{error}', error.toString()),
          );
        }
      } finally {
        _pendingModalDialogs.remove(key);
        completer.complete();
      }
    });
    return completer.future;
  }

  Future<void> _showBoardDisasterDialog({
    required String icon,
    required String title,
    required String description,
    required OnlineDisasterEvent event,
    required String showingZeroDamage,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future<void>.delayed(_disasterModalDuration, () {
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
                Text(icon, style: const TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  event.damage > 0
                      ? _text(
                            'online_disaster_damage',
                            'Daño: {damage} • Piezas destruidas: {destroyed}',
                            'Damage: {damage} • Pieces destroyed: {destroyed}',
                          )
                          .replaceAll('{damage}', '${event.damage}')
                          .replaceAll('{destroyed}', '${event.destroyedPieces}')
                      : showingZeroDamage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _text(
                    'online_disaster_closing',
                    '⏳ Cerrando en 4 segundos...',
                    '⏳ Closing in 4 seconds...',
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

  void _showDisastersFromSnapshot(OnlineGameState game) {
    final earthquake = game.lastEarthquake;
    if (game.earthquakeProcessedTurn == game.turn &&
        earthquake?.turn == game.turn) {
      unawaited(_showEarthquakeEvent(earthquake!));
    }
    final plague = game.lastPlague;
    if (game.plagueProcessedTurn == game.turn && plague?.turn == game.turn) {
      unawaited(_showPlagueEvent(plague!));
    }
    final epidemic = game.lastEpidemic;
    if (game.epidemicProcessedTurn == game.turn &&
        epidemic?.turn == game.turn) {
      unawaited(_showEpidemicEvent(epidemic!));
    }
  }

  void _showVictoryFromSnapshot(OnlineGameState game, _OnlineBoardData data) {
    final winnerRole = game.winner;
    if (winnerRole == null) return;

    final winner = game.playerForRole(winnerRole);
    final civilization = data.civilizations[winner.civilizationId];
    final playerLabel = _text(
      winnerRole == 'host' ? 'online_player_one' : 'online_player_two',
      winnerRole == 'host' ? 'Jugador 1' : 'Jugador 2',
      winnerRole == 'host' ? 'Player 1' : 'Player 2',
    );
    final civilizationName =
        civilization == null
            ? playerLabel
            : _translations[civilization.nombreId] ?? civilization.nombreId;

    unawaited(
      _enqueueModalDialog(
        key: 'victory-$winnerRole',
        isShown: () => _shownVictoryRole == winnerRole,
        markShown: () => _shownVictoryRole = winnerRole,
        show:
            () => _displayVictoryDialog(
              playerLabel: playerLabel,
              civilizationName: civilizationName,
            ),
      ),
    );
  }

  Future<void> _displayVictoryDialog({
    required String playerLabel,
    required String civilizationName,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
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
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _text(
                      'victoria_titulo',
                      '🏆 ¡VICTORIA! 🏆',
                      '🏆 VICTORY! 🏆',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _text(
                      'victoria_ganador',
                      'Ganador: {player}',
                      'Winner: {player}',
                    ).replaceAll('{player}', playerLabel),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      civilizationName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      unawaited(_leaveRoom());
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
                    child: Text(
                      _text('victoria_salir', 'SALIR', 'EXIT'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSharedDiceRoll(OnlineGameState game) {
    if (game.diceRolledTurn != game.turn ||
        game.firstDie == null ||
        game.secondDie == null ||
        game.lastRollTotal == null ||
        game.diceRolledBy == null ||
        _displayedDiceRollTurn == game.turn) {
      return;
    }

    final rollerLabel =
        game.diceRolledBy == 'host'
            ? _text('online_player_one', 'Jugador 1', 'Player 1')
            : _text('online_player_two', 'Jugador 2', 'Player 2');
    final title = _text(
      'online_player_rolling_dice',
      '{player} tirando los dados',
      '{player} rolling the dice',
    ).replaceAll('{player}', rollerLabel);
    final firstDie = game.firstDie!;
    final secondDie = game.secondDie!;

    unawaited(
      _enqueueModalDialog(
        key: 'dice-${game.turn}',
        isShown: () => _displayedDiceRollTurn == game.turn,
        markShown: () => _displayedDiceRollTurn = game.turn,
        show:
            () => _displaySharedDiceRoll(
              game: game,
              title: title,
              firstDie: firstDie,
              secondDie: secondDie,
            ),
      ),
    );
  }

  Future<void> _displaySharedDiceRoll({
    required OnlineGameState game,
    required String title,
    required int firstDie,
    required int secondDie,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 3), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 300,
            height: 340,
            decoration: BoxDecoration(
              color: Colors.brown[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/images/dados/${firstDie}x$secondDie.png',
                  width: 200,
                  height: 200,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 200,
                        height: 200,
                        color: Colors.brown[600],
                        alignment: Alignment.center,
                        child: Text(
                          '$firstDie + $secondDie',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ),
                // const SizedBox(height: 8),
                // Text(
                //   '$firstDie + $secondDie = $total',
                //   style: const TextStyle(
                //     color: _gold,
                //     fontSize: 22,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
    final isLocalRoller =
        widget.uid ==
        (game.currentPlayer == 'host' ? game.host.uid : game.guest.uid);
    if (mounted &&
        !_leaving &&
        isLocalRoller &&
        game.harvestedTurn != game.turn) {
      unawaited(_harvestCrops(game));
    }
  }

  Future<void> _harvestCrops(OnlineGameState game) async {
    if (_harvestingTurn == game.turn || game.harvestedTurn == game.turn) return;
    _harvestingTurn = game.turn;
    try {
      await OnlineRoomsService.harvestCropsForTurn(
        room: widget.room,
        uid: widget.uid,
        role: game.currentPlayer,
        turn: game.turn,
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_harvest_error',
            'No se pudo cosechar: {error}',
            'Could not harvest crops: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (_harvestingTurn == game.turn) _harvestingTurn = null;
    }
  }

  void _showHarvestAnimation(OnlineHarvestResult harvest) {
    if (_shownHarvestTurn == harvest.turn) return;
    _shownHarvestTurn = harvest.turn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _leaving || harvest.totalPoints <= 0) return;
      setState(() => _cropAnimationTurn = harvest.turn);
      final overlay = Overlay.of(context);
      final entry = OverlayEntry(
        builder:
            (context) => IgnorePointer(
              child: SafeArea(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: -70),
                    duration: const Duration(milliseconds: 1200),
                    builder:
                        (context, offset, child) => Transform.translate(
                          offset: Offset(0, offset),
                          child: child,
                        ),
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        '+${harvest.totalPoints} ⚡',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      );
      _harvestOverlay?.remove();
      _harvestOverlay = entry;
      overlay.insert(entry);
      Future.delayed(_harvestAnimationDuration, () {
        if (!mounted || _harvestOverlay != entry) return;
        entry.remove();
        _harvestOverlay = null;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _cropAnimationTurn == harvest.turn) {
          setState(() => _cropAnimationTurn = null);
        }
      });
    });
  }

  void _showHospitalHealingAnimation(
    OnlineHospitalHealingResult healing, {
    required bool waitForHarvest,
  }) {
    if (healing.hospitalCoordinates.isEmpty ||
        _shownHospitalHealingTurn == healing.turn) {
      return;
    }
    _shownHospitalHealingTurn = healing.turn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _leaving) return;
      Future.delayed(
        waitForHarvest ? _harvestAnimationDuration : Duration.zero,
        () {
          if (!mounted || _leaving) return;
          setState(() => _hospitalAnimationTurn = healing.turn);
          Future.delayed(_hospitalAnimationDuration, () {
            if (mounted && _hospitalAnimationTurn == healing.turn) {
              setState(() => _hospitalAnimationTurn = null);
            }
          });
        },
      );
    });
  }

  void _showVillagerRepairAnimation(
    OnlineVillagerRepairResult repair, {
    required Duration delay,
  }) {
    if (repair.villagerCoordinates.isEmpty ||
        _shownVillagerRepairTurn == repair.turn) {
      return;
    }
    _shownVillagerRepairTurn = repair.turn;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _leaving) return;
      if (delay > Duration.zero) await Future.delayed(delay);
      if (!mounted || _leaving) return;
      for (var hit = 0; hit < 3; hit++) {
        setState(() => _villagerAnimationTurn = repair.turn);
        await Future.delayed(_hammerHitDuration);
        if (!mounted || _leaving) return;
        setState(() => _villagerAnimationTurn = null);
        if (hit < 2) await Future.delayed(_hammerPauseDuration);
        if (!mounted || _leaving) return;
      }
    });
  }

  void _showTowerAttackAnimation(OnlineTowerAttackEvent? attack, int turn) {
    if (attack == null ||
        attack.turn != turn ||
        (_shownTowerAttackTurn == turn &&
            _shownTowerAttackIndex == attack.index)) {
      return;
    }
    _shownTowerAttackTurn = attack.turn;
    _shownTowerAttackIndex = attack.index;
    final animationKey = '${attack.turn}-${attack.index}';
    final completer = _towerAttackAnimationCompleters.putIfAbsent(
      animationKey,
      Completer<void>.new,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _leaving) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      setState(() {
        _towerAttackAnimationTurn = attack.turn;
        _towerAttackAnimationIndex = attack.index;
        _towerAttackReleasing = false;
      });
      Future.delayed(_towerChargeDuration, () {
        if (mounted &&
            _towerAttackAnimationTurn == attack.turn &&
            _towerAttackAnimationIndex == attack.index) {
          setState(() => _towerAttackReleasing = true);
        }
        Future.delayed(_towerAttackDuration - _towerChargeDuration, () {
          if (mounted &&
              _towerAttackAnimationTurn == attack.turn &&
              _towerAttackAnimationIndex == attack.index) {
            setState(() {
              _towerAttackAnimationTurn = null;
              _towerAttackAnimationIndex = null;
              _towerAttackReleasing = false;
            });
          }
          _completedTowerAttackAnimations.add(animationKey);
          _towerAttackAnimationCompleters.remove(animationKey);
          if (!completer.isCompleted) completer.complete();
        });
      });
    });
  }

  Future<void> _waitForTowerAttackAnimation(int turn, int index) {
    final animationKey = '$turn-$index';
    if (_completedTowerAttackAnimations.contains(animationKey)) {
      return Future<void>.value();
    }
    final completer = _towerAttackAnimationCompleters.putIfAbsent(
      animationKey,
      Completer<void>.new,
    );
    return completer.future.timeout(const Duration(seconds: 5));
  }

  void _ensureTowerAttackSequence(OnlineGameState game, String localRole) {
    if (game.winner != null ||
        game.currentPlayer != localRole ||
        game.towerAttackTurn != game.turn ||
        game.towerAttacksComplete ||
        _runningTowerAttackTurn == game.turn) {
      return;
    }
    _runningTowerAttackTurn = game.turn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runTowerAttackSequence(game, localRole);
    });
  }

  Future<void> _runTowerAttackSequence(
    OnlineGameState game,
    String localRole,
  ) async {
    try {
      final harvest = game.lastHarvest;
      if (harvest != null &&
          harvest.turn == game.turn &&
          harvest.totalPoints > 0) {
        await Future.delayed(_harvestAnimationDuration);
      }
      final healing = game.lastHospitalHealing;
      if (healing != null &&
          healing.turn == game.turn &&
          healing.playerRole == localRole &&
          healing.hospitalCoordinates.isNotEmpty) {
        await Future.delayed(_hospitalAnimationDuration);
      }
      final repair = game.lastVillagerRepair;
      if (repair != null &&
          repair.turn == game.turn &&
          repair.playerRole == localRole &&
          repair.villagerCoordinates.isNotEmpty) {
        await Future.delayed(_hammerHitDuration * 3 + _hammerPauseDuration * 2);
      }

      while (mounted && !_leaving) {
        final resolution = await OnlineRoomsService.attackNextTowerForTurn(
          room: widget.room,
          uid: widget.uid,
          role: localRole,
          turn: game.turn,
        );
        if (!resolution.committed) {
          if (mounted && !_leaving) {
            _showMessage(
              _text(
                'online_tower_attack_error',
                'No se pudieron resolver los ataques de las torres.',
                'Tower attacks could not be resolved.',
              ),
            );
          }
          break;
        }
        if (resolution.attacked) {
          final attack = resolution.attack;
          if (attack == null) {
            throw StateError('El ataque de torre no se sincronizó.');
          }
          _showTowerAttackAnimation(attack, game.turn);
          await _waitForTowerAttackAnimation(attack.turn, attack.index);
        }
        if (resolution.complete) break;
      }
    } catch (error) {
      if (mounted && !_leaving) {
        _showMessage(
          _text(
            'online_tower_attack_error_detail',
            'Error en el ataque de las torres: {error}',
            'Tower attack error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (_runningTowerAttackTurn == game.turn) {
        _runningTowerAttackTurn = null;
      }
    }
  }

  @override
  void dispose() {
    _harvestOverlay?.remove();
    super.dispose();
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await OnlineRoomsService.leaveRoom(room: widget.room, uid: widget.uid);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[900]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          _text('online_game_title', 'Partida online', 'Online game'),
        ),
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _leaving ? null : _leaveRoom,
            tooltip: _text(
              'online_leave_room',
              'Salir de la sala',
              'Leave room',
            ),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<_OnlineBoardData>(
          future: _boardData,
          builder: (context, dataSnapshot) {
            if (dataSnapshot.hasError) {
              return _buildMessage(
                _text(
                  'online_board_load_error',
                  'No se pudo cargar el tablero: {error}',
                  'The board could not be loaded: {error}',
                ).replaceAll('{error}', dataSnapshot.error.toString()),
              );
            }
            if (!dataSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _gold),
              );
            }
            return StreamBuilder<OnlineGameState>(
              stream: _gameStream,
              builder: (context, gameSnapshot) {
                if (gameSnapshot.hasError) {
                  return _buildMessage(
                    _text(
                      'online_game_state_error',
                      'No se pudo sincronizar la partida: {error}',
                      'Could not synchronize the game: {error}',
                    ).replaceAll('{error}', gameSnapshot.error.toString()),
                  );
                }
                if (!gameSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _gold),
                  );
                }
                final game = gameSnapshot.data!;
                _showDisastersFromSnapshot(game);
                _showVictoryFromSnapshot(game, dataSnapshot.data!);
                return _buildBoard(game, dataSnapshot.data!);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessage(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
    ),
  );

  Widget _buildBoard(OnlineGameState game, _OnlineBoardData data) {
    _showSharedDiceRoll(game);
    _showTowerAttackAnimation(game.lastTowerAttack, game.turn);
    final harvest = game.lastHarvest;
    final hasHarvestAnimation =
        harvest != null && harvest.turn == game.turn && harvest.totalPoints > 0;
    if (harvest != null && harvest.turn == game.turn) {
      _showHarvestAnimation(harvest);
    }
    final hospitalHealing = game.lastHospitalHealing;
    if (hospitalHealing != null && hospitalHealing.turn == game.turn) {
      _showHospitalHealingAnimation(
        hospitalHealing,
        waitForHarvest: hasHarvestAnimation,
      );
    }
    final villagerRepair = game.lastVillagerRepair;
    if (villagerRepair != null &&
        villagerRepair.turn == game.turn &&
        villagerRepair.playerRole == game.currentPlayer) {
      final hasHospitalAnimation =
          hospitalHealing != null &&
          hospitalHealing.turn == game.turn &&
          hospitalHealing.playerRole == villagerRepair.playerRole &&
          hospitalHealing.hospitalCoordinates.isNotEmpty;
      _showVillagerRepairAnimation(
        villagerRepair,
        delay: Duration(
          milliseconds:
              (hasHarvestAnimation
                  ? _harvestAnimationDuration.inMilliseconds
                  : 0) +
              (hasHospitalAnimation
                  ? _hospitalAnimationDuration.inMilliseconds
                  : 0),
        ),
      );
    }
    final hostCiv = data.civilizations[game.host.civilizationId];
    final guestCiv = data.civilizations[game.guest.civilizationId];
    if (hostCiv == null || guestCiv == null) {
      return _buildMessage(
        _text(
          'online_civilization_not_found',
          'La civilización seleccionada no existe en los datos del juego.',
          'The selected civilization is missing from the game data.',
        ),
      );
    }

    final activeRole = game.currentPlayer;
    final activeLabel =
        activeRole == 'host'
            ? _text('online_player_one', 'Jugador 1', 'Player 1')
            : _text('online_player_two', 'Jugador 2', 'Player 2');
    if (widget.uid != game.host.uid && widget.uid != game.guest.uid) {
      return _buildMessage(
        _text(
          'online_player_not_in_room',
          'El jugador no pertenece a esta sala.',
          'This player does not belong to this room.',
        ),
      );
    }
    final isHost = widget.uid == game.host.uid;
    final myRole = isHost ? 'host' : 'guest';
    final isMyTurn = activeRole == myRole;
    if (isMyTurn && game.diceRolledTurn != game.turn) {
      _ensureTurnDiceRoll(game, myRole);
    }
    final topRole = isHost ? 'guest' : 'host';
    final topPlayer = isHost ? game.guest : game.host;
    final topCivilization = isHost ? guestCiv : hostCiv;
    final bottomRole = myRole;
    final bottomPlayer = isHost ? game.host : game.guest;
    final bottomCivilization = isHost ? hostCiv : guestCiv;
    final topLabel =
        topRole == 'host'
            ? _text('online_player_one', 'Jugador 1', 'Player 1')
            : _text('online_player_two', 'Jugador 2', 'Player 2');
    final bottomLabel =
        bottomRole == 'host'
            ? _text('online_player_one', 'Jugador 1', 'Player 1')
            : _text('online_player_two', 'Jugador 2', 'Player 2');
    if (game.winner == null) {
      _ensureTowerAttackSequence(game, myRole);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSide = [
          constraints.maxWidth / 5,
          constraints.maxHeight / 9.2,
        ].reduce((a, b) => a < b ? a : b);
        if (cellSide <= 0) return const SizedBox.shrink();

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: cellSide * 5,
              maxHeight: cellSide * 9.2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatsRow(
                  cellSide: cellSide,
                  label: topLabel,
                  isActive: activeRole == topRole,
                  canPass:
                      activeRole == topRole &&
                      isMyTurn &&
                      game.diceRolledTurn == game.turn &&
                      game.harvestedTurn == game.turn &&
                      game.towerAttacksTurn == game.turn,
                  accumulatedPoints: topPlayer.accumulatedPoints,
                ),
                ...List.generate(
                  4,
                  (row) => _buildBoardRow(
                    cellSide: cellSide,
                    row: row,
                    monumentRow: 0,
                    ownerRole: topRole,
                    player: topPlayer,
                    civilization: topCivilization,
                    isBottom: false,
                    canInvoke: false,
                    canRebuild: false,
                    game: game,
                    data: data,
                  ),
                ),
                SizedBox(
                  height: cellSide * 0.2,
                  child: Center(
                    child: Text(
                      game.winner == null
                          ? '${_text('online_turn_indicator', 'TURNO', 'TURN')} ${game.turn + 1}  •  $activeLabel'
                          : _text(
                            'online_player_won',
                            '{player} ganó',
                            '{player} won',
                          ).replaceAll('{player}', activeLabel),
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
                    cellSide: cellSide,
                    row: row,
                    monumentRow: 3,
                    ownerRole: bottomRole,
                    player: bottomPlayer,
                    civilization: bottomCivilization,
                    isBottom: true,
                    canInvoke:
                        isMyTurn &&
                        game.diceRolledTurn == game.turn &&
                        game.harvestedTurn == game.turn &&
                        game.towerAttacksTurn == game.turn &&
                        game.winner == null &&
                        !_leaving,
                    canRebuild:
                        isMyTurn &&
                        game.diceRolledTurn == game.turn &&
                        game.harvestedTurn == game.turn &&
                        game.towerAttacksTurn == game.turn &&
                        game.winner == null &&
                        !_leaving,
                    game: game,
                    data: data,
                  ),
                ),
                _buildStatsRow(
                  cellSide: cellSide,
                  label: bottomLabel,
                  isActive: activeRole == bottomRole,
                  canPass:
                      activeRole == bottomRole &&
                      isMyTurn &&
                      game.diceRolledTurn == game.turn &&
                      game.harvestedTurn == game.turn &&
                      game.towerAttacksTurn == game.turn,
                  accumulatedPoints: bottomPlayer.accumulatedPoints,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoardRow({
    required double cellSide,
    required int row,
    required int monumentRow,
    required String ownerRole,
    required Civilizacion civilization,
    required OnlineGamePlayer player,
    required bool isBottom,
    required bool canInvoke,
    required bool canRebuild,
    required OnlineGameState game,
    required _OnlineBoardData data,
  }) {
    return SizedBox(
      height: cellSide,
      child: Row(
        children: List.generate(5, (column) {
          if (row == monumentRow && column == 2) {
            final attack = game.lastTowerAttack;
            return MonumentoTablero(
              ladoCelda: cellSide,
              imagenPath: civilization.muralla.imagen,
              vida: player.monumentHealth,
              onTap:
                  canRebuild && player.accumulatedPoints > 0
                      ? () => _showMonumentRebuildDialog(
                        game: game,
                        player: player,
                        civilization: civilization,
                        role: ownerRole,
                      )
                      : () {},
              resplandor:
                  _towerAttackAnimationTurn == game.turn &&
                  attack?.turn == game.turn &&
                  attack?.targetRole == ownerRole &&
                  attack?.targetType == 'monument' &&
                  _towerAttackAnimationIndex == attack?.index,
            );
          }
          final boardRow = isBottom ? row : 3 - row;
          final coordinate = 'r${boardRow}c$column';
          final piece = player.board[coordinate];
          if (piece != null) {
            final animateCrop =
                _cropAnimationTurn == game.turn &&
                game.lastHarvest?.turn == game.turn &&
                game.lastHarvest?.playerRole == ownerRole &&
                game.lastHarvest!.cropPoints.containsKey(coordinate);
            final animateHospital =
                _hospitalAnimationTurn == game.turn &&
                game.lastHospitalHealing?.turn == game.turn &&
                game.lastHospitalHealing?.playerRole == ownerRole &&
                game.lastHospitalHealing!.hospitalCoordinates.contains(
                  coordinate,
                );
            final animateVillager =
                _villagerAnimationTurn == game.turn &&
                game.lastVillagerRepair?.turn == game.turn &&
                game.lastVillagerRepair?.playerRole == ownerRole &&
                game.lastVillagerRepair!.villagerCoordinates.contains(
                  coordinate,
                );
            final attack = game.lastTowerAttack;
            final animateTowerAttack =
                _towerAttackAnimationTurn == game.turn &&
                attack?.turn == game.turn &&
                attack?.playerRole == ownerRole &&
                attack?.towerCoordinate == coordinate &&
                !_towerAttackReleasing &&
                _towerAttackAnimationIndex == attack?.index;
            final animateTowerRelease =
                _towerAttackAnimationTurn == game.turn &&
                attack?.turn == game.turn &&
                attack?.playerRole == ownerRole &&
                attack?.towerCoordinate == coordinate &&
                _towerAttackReleasing &&
                _towerAttackAnimationIndex == attack?.index;
            final animateTowerHit =
                _towerAttackAnimationTurn == game.turn &&
                attack?.turn == game.turn &&
                attack?.targetRole == ownerRole &&
                attack?.targetCoordinate == coordinate &&
                _towerAttackAnimationIndex == attack?.index;
            final onCropTap =
                piece.type == 'crop' &&
                        canRebuild &&
                        player.accumulatedPoints > 0
                    ? () => _showCropOptionsDialog(
                      game: game,
                      player: player,
                      piece: piece,
                      role: ownerRole,
                      coordinate: coordinate,
                      data: data,
                    )
                    : null;
            final onVillagerTap =
                piece.type == 'villager' &&
                        canRebuild &&
                        (player.accumulatedPoints > 0 ||
                            player
                                .availableVillagerMoveCoordinates()
                                .isNotEmpty)
                    ? () => _showVillagerOptionsDialog(
                      game: game,
                      player: player,
                      piece: piece,
                      role: ownerRole,
                      coordinate: coordinate,
                      data: data,
                    )
                    : null;
            final onWarriorTap =
                piece.type == 'warrior' &&
                        canRebuild &&
                        (player.accumulatedPoints > 0 ||
                            player
                                .availableWarriorMoveCoordinates()
                                .isNotEmpty ||
                            game.canWarriorAttack(ownerRole, coordinate))
                    ? () => _showWarriorOptionsDialog(
                      game: game,
                      player: player,
                      piece: piece,
                      role: ownerRole,
                      coordinate: coordinate,
                      data: data,
                    )
                    : null;
            final onHospitalTap =
                piece.type == 'hospital' &&
                        canRebuild &&
                        player.accumulatedPoints > 0
                    ? () => _showHospitalOptionsDialog(
                      game: game,
                      player: player,
                      piece: piece,
                      role: ownerRole,
                      coordinate: coordinate,
                      data: data,
                    )
                    : null;
            final onTowerTap =
                piece.type == 'tower' &&
                        canRebuild &&
                        player.accumulatedPoints > 0
                    ? () => _showTowerOptionsDialog(
                      game: game,
                      player: player,
                      piece: piece,
                      role: ownerRole,
                      coordinate: coordinate,
                      data: data,
                    )
                    : null;
            return _buildPieceCell(
              cellSide,
              piece,
              data,
              onTap:
                  onCropTap ??
                  onVillagerTap ??
                  onWarriorTap ??
                  onHospitalTap ??
                  onTowerTap,
              showWarriorAttackReady:
                  piece.type == 'warrior' &&
                  !game.hasWarriorAttacked(ownerRole, coordinate),
              animateCrop: animateCrop,
              animateHospital: animateHospital,
              animateVillager: animateVillager,
              animateTowerAttack: animateTowerAttack,
              animateTowerRelease: animateTowerRelease,
              animateTowerHit: animateTowerHit,
            );
          }
          final attack = game.lastTowerAttack;
          final animateDestroyedTarget =
              _towerAttackAnimationTurn == game.turn &&
              attack?.turn == game.turn &&
              attack?.targetRole == ownerRole &&
              attack?.targetCoordinate == coordinate &&
              attack?.targetDestroyed == true &&
              _towerAttackAnimationIndex == attack?.index;
          if (animateDestroyedTarget) {
            final destroyedPiece = attack?.destroyedTargetPiece;
            if (destroyedPiece != null) {
              return _buildPieceCell(
                cellSide,
                destroyedPiece,
                data,
                animateTowerHit: true,
              );
            }
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: cellSide,
              height: cellSide,
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                border: Border.all(color: const Color(0xFF303030)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.8),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
            );
          }
          if (canInvoke) {
            final isVillagerMoveTarget =
                canRebuild &&
                _movingVillagerTurn == game.turn &&
                _movingVillagerRole == ownerRole;
            final isWarriorMoveTarget =
                canRebuild &&
                _movingWarriorTurn == game.turn &&
                _movingWarriorRole == ownerRole;
            if (isVillagerMoveTarget || isWarriorMoveTarget) {
              return SizedBox(
                width: cellSide,
                height: cellSide,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      _pieceUpgradeInProgress
                          ? null
                          : isWarriorMoveTarget
                          ? () => _moveWarriorTo(
                            game: game,
                            role: ownerRole,
                            destination: coordinate,
                          )
                          : () => _moveVillagerTo(
                            game: game,
                            role: ownerRole,
                            destination: coordinate,
                          ),
                  child: Padding(
                    padding: EdgeInsets.all(cellSide * 0.05),
                    child: Container(
                      width: cellSide,
                      height: cellSide,
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.16),
                        border: Border.all(color: _gold, width: 2),
                        borderRadius: BorderRadius.circular(cellSide * 0.05),
                      ),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: _gold,
                        size: cellSide * 0.32,
                      ),
                    ),
                  ),
                ),
              );
            }
            return Container(
              width: cellSide,
              height: cellSide,
              padding: EdgeInsets.all(cellSide * 0.05),
              child: ElevatedButton(
                onPressed:
                    _summoningCoordinate == coordinate
                        ? null
                        : () => _showInvocationModal(
                          game: game,
                          player: player,
                          data: data,
                          row: boardRow,
                          column: column,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[600],
                  elevation: 4,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cellSide * 0.05),
                  ),
                ),
                child: Icon(Icons.add, size: cellSide * 0.36),
              ),
            );
          }
          return Container(
            width: cellSide,
            height: cellSide,
            decoration: BoxDecoration(
              color: const Color(0xFF424242),
              border: Border.all(color: const Color(0xFF303030)),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showMonumentRebuildDialog({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required Civilizacion civilization,
    required String role,
  }) async {
    final pointsAvailable = player.accumulatedPoints;
    if (_pieceUpgradeInProgress ||
        _leaving ||
        pointsAvailable <= 0 ||
        game.currentPlayer != role ||
        game.winner != null) {
      return;
    }

    final pointsToSpend = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        var selectedPoints = 1.0;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.brown[800]!, Colors.brown[900]!],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _gold, width: 3),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance,
                          color: _gold,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _text('reconstruir', 'RECONSTRUIR', 'REBUILD'),
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.brown[300],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _gold, width: 2),
                        image: DecorationImage(
                          image: AssetImage(civilization.muralla.imagen),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            '${player.monumentHealth}',
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
                    Text(
                      '⚡ $pointsAvailable ${_text('disponibles', 'disponibles', 'available')}',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _gold,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: _gold,
                        overlayColor: _gold.withValues(alpha: 0.18),
                      ),
                      child: Slider(
                        value: selectedPoints,
                        min: 1,
                        max: pointsAvailable.toDouble(),
                        divisions:
                            pointsAvailable > 1 ? pointsAvailable - 1 : null,
                        onChanged:
                            pointsAvailable > 1
                                ? (value) =>
                                    setStateDialog(() => selectedPoints = value)
                                : null,
                      ),
                    ),
                    Text(
                      '${selectedPoints.round()} ⚡',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(
                              _text('cancelar', 'CANCELAR', 'CANCEL'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              backgroundColor: Colors.brown[800],
                              side: BorderSide(
                                color: _gold.withValues(alpha: 0.65),
                              ),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => Navigator.pop(
                                  dialogContext,
                                  selectedPoints.round(),
                                ),
                            icon: const Icon(
                              Icons.construction_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _text('reconstruir', 'RECONSTRUIR', 'REBUILD'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.brown[900],
                              backgroundColor: _gold,
                              elevation: 4,
                              shadowColor: _gold.withValues(alpha: 0.35),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
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
    if (pointsToSpend == null || !mounted || _leaving) return;

    try {
      final committed = await OnlineRoomsService.rebuildMonumentForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        points: pointsToSpend,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_monument_rebuild_failed',
            'No se pudo reconstruir el monumento: revisa el turno y tus puntos.',
            'Could not rebuild the monument: check the turn and your points.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_monument_rebuild_error',
            'Error al reconstruir el monumento: {error}',
            'Monument rebuild error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    }
  }

  Future<void> _showCropOptionsDialog({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required OnlineBoardPiece piece,
    required String role,
    required String coordinate,
    required _OnlineBoardData data,
  }) async {
    final pointsAvailable = player.accumulatedPoints;
    if (_pieceUpgradeInProgress ||
        _leaving ||
        pointsAvailable <= 0 ||
        game.currentPlayer != role ||
        game.winner != null ||
        piece.type != 'crop') {
      return;
    }

    final imagePath = data.optionForPiece(piece, _translations).imagePath;
    final upgrade = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.brown[800]!, Colors.brown[900]!],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold, width: 3),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌾', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 8),
                      Text(
                        _text('modal_cultivo', 'CULTIVO', 'CROP'),
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.brown[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.7),
                          ),
                          image: DecorationImage(
                            image: AssetImage(imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            _buildCropStatRow(
                              '🌾 ${_text('puntos_turno', 'Puntos/turno:', 'Points/turn:')}',
                              piece.primaryStat,
                              Colors.greenAccent,
                            ),
                            const SizedBox(height: 8),
                            _buildCropStatRow(
                              '🌱 ${_text('vida', 'Vida:', 'Health:')}',
                              piece.health,
                              Colors.redAccent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, color: _gold, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$pointsAvailable ${_text('puntos_disponibles', 'puntos disponibles', 'available points')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropActionButton(
                          dialogContext: dialogContext,
                          title: _text(
                            'mejorar_produccion',
                            'MEJORAR PRODUCCIÓN',
                            'UPGRADE PRODUCTION',
                          ),
                          icon: Icons.grass_rounded,
                          color: const Color(0xFF4CAF50),
                          value: 'production',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCropActionButton(
                          dialogContext: dialogContext,
                          title: _text('reconstruir', 'RECONSTRUIR', 'REBUILD'),
                          icon: Icons.construction_rounded,
                          color: const Color(0xFF4FC3F7),
                          value: 'health',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: Text(_text('cancelar', 'CANCELAR', 'CANCEL')),
                  ),
                ],
              ),
            ),
          ),
    );
    if (upgrade == null || !mounted || _leaving) return;

    final currentValue =
        upgrade == 'production' ? piece.primaryStat : piece.health;
    final isProduction = upgrade == 'production';
    final pointsToSpend = await _showUpgradePointsDialog(
      title: _text(
        isProduction ? 'mejorar_produccion' : 'reconstruir',
        isProduction ? 'MEJORAR PRODUCCIÓN' : 'RECONSTRUIR',
        isProduction ? 'UPGRADE PRODUCTION' : 'REBUILD',
      ),
      icon: isProduction ? '🌾' : '🌱',
      currentValue: currentValue,
      pointsAvailable: pointsAvailable,
      accentColor:
          isProduction ? const Color(0xFF81C784) : const Color(0xFF4FC3F7),
      confirmLabel: _text('mejorar', 'MEJORAR', 'UPGRADE'),
    );
    if (pointsToSpend == null || !mounted || _leaving) return;
    if (_pieceUpgradeInProgress) return;

    setState(() => _pieceUpgradeInProgress = true);
    try {
      final committed = await OnlineRoomsService.upgradeBoardPieceForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        coordinate: coordinate,
        points: pointsToSpend,
        pieceType: 'crop',
        upgrade: upgrade,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_crop_upgrade_failed',
            'No se pudo mejorar el cultivo: revisa el turno, los puntos y la casilla.',
            'Could not upgrade the crop: check the turn, points, and square.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_crop_upgrade_error',
            'Error al mejorar el cultivo: {error}',
            'Crop upgrade error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _pieceUpgradeInProgress = false);
    }
  }

  Future<void> _showVillagerOptionsDialog({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required OnlineBoardPiece piece,
    required String role,
    required String coordinate,
    required _OnlineBoardData data,
  }) async {
    final pointsAvailable = player.accumulatedPoints;
    if (_pieceUpgradeInProgress ||
        _leaving ||
        game.currentPlayer != role ||
        game.winner != null ||
        piece.type != 'villager' ||
        (pointsAvailable <= 0 &&
            player.availableVillagerMoveCoordinates().isEmpty)) {
      return;
    }

    final name = data.optionForPiece(piece, _translations).name;
    final upgrade = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.brown[800]!, Colors.brown[900]!],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold, width: 3),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👨', style: TextStyle(fontSize: 25)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropStatRow(
                          '🔨',
                          piece.primaryStat,
                          Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCropStatRow(
                          '❤️ ${_text('vida', 'Vida:', 'Health:')}',
                          piece.health,
                          Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  if (pointsAvailable > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: _gold,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$pointsAvailable ${_text('puntos_disponibles', 'puntos disponibles', 'available points')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCropActionButton(
                            dialogContext: dialogContext,
                            title: _text(
                              'mejorar_reconstruccion',
                              'MEJORAR RECONSTRUCCIÓN',
                              'UPGRADE RECONSTRUCTION',
                            ),
                            icon: Icons.handyman_rounded,
                            color: Colors.orangeAccent,
                            value: 'reconstruction',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCropActionButton(
                            dialogContext: dialogContext,
                            title: _text('curar', 'CURAR', 'HEAL'),
                            icon: Icons.favorite_rounded,
                            color: Colors.lightGreenAccent,
                            value: 'health',
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (player.availableVillagerMoveCoordinates().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildCropActionButton(
                        dialogContext: dialogContext,
                        title: _text('mover', 'MOVER', 'MOVE'),
                        icon: Icons.open_with_rounded,
                        color: const Color(0xFF64B5F6),
                        value: 'move',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: Text(_text('cancelar', 'CANCELAR', 'CANCEL')),
                  ),
                ],
              ),
            ),
          ),
    );
    if (upgrade == null || !mounted || _leaving) return;
    if (upgrade == 'move') {
      _beginVillagerMove(game: game, role: role, coordinate: coordinate);
      return;
    }

    final isReconstruction = upgrade == 'reconstruction';
    final pointsToSpend = await _showUpgradePointsDialog(
      title: _text(
        isReconstruction ? 'mejorar_reconstruccion' : 'curar',
        isReconstruction ? 'MEJORAR RECONSTRUCCIÓN' : 'CURAR ALDEANO',
        isReconstruction ? 'UPGRADE RECONSTRUCTION' : 'HEAL VILLAGER',
      ),
      icon: isReconstruction ? '🔨' : '❤️',
      currentValue: isReconstruction ? piece.primaryStat : piece.health,
      pointsAvailable: pointsAvailable,
      accentColor:
          isReconstruction ? Colors.orangeAccent : Colors.lightGreenAccent,
      confirmLabel: _text('mejorar', 'MEJORAR', 'UPGRADE'),
    );
    if (pointsToSpend == null || !mounted || _leaving) return;
    if (_pieceUpgradeInProgress) return;

    setState(() => _pieceUpgradeInProgress = true);
    try {
      final committed = await OnlineRoomsService.upgradeBoardPieceForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        coordinate: coordinate,
        points: pointsToSpend,
        pieceType: 'villager',
        upgrade: upgrade,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_villager_upgrade_failed',
            'No se pudo mejorar el aldeano: revisa el turno, los puntos y la casilla.',
            'Could not upgrade the villager: check the turn, points, and square.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_villager_upgrade_error',
            'Error al mejorar el aldeano: {error}',
            'Villager upgrade error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _pieceUpgradeInProgress = false);
    }
  }

  void _beginVillagerMove({
    required OnlineGameState game,
    required String role,
    required String coordinate,
  }) {
    setState(() {
      _movingVillagerCoordinate = coordinate;
      _movingVillagerRole = role;
      _movingVillagerTurn = game.turn;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'online_villager_move_select',
              'Selecciona una casilla vacía para mover al aldeano.',
              'Select an empty square to move the villager.',
            ),
          ),
          action: SnackBarAction(
            label: _text('cancelar', 'CANCELAR', 'CANCEL'),
            onPressed: _cancelVillagerMove,
          ),
        ),
      );
  }

  Future<void> _moveVillagerTo({
    required OnlineGameState game,
    required String role,
    required String destination,
  }) async {
    final source = _movingVillagerCoordinate;
    if (source == null ||
        _movingVillagerTurn != game.turn ||
        _movingVillagerRole != role ||
        _pieceUpgradeInProgress) {
      _cancelVillagerMove();
      return;
    }

    setState(() => _pieceUpgradeInProgress = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      final moved = await OnlineRoomsService.moveVillagerForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        fromCoordinate: source,
        toCoordinate: destination,
      );
      if (!moved && mounted) {
        _showMessage(
          _text(
            'online_villager_move_failed',
            'No se pudo mover al aldeano: revisa el turno y la casilla.',
            'Could not move the villager: check the turn and square.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_villager_move_error',
            'Error al mover al aldeano: {error}',
            'Villager move error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pieceUpgradeInProgress = false;
          _movingVillagerCoordinate = null;
          _movingVillagerRole = null;
          _movingVillagerTurn = null;
        });
      }
    }
  }

  void _cancelVillagerMove() {
    if (!mounted ||
        (_movingVillagerCoordinate == null &&
            _movingVillagerRole == null &&
            _movingVillagerTurn == null)) {
      return;
    }
    setState(() {
      _movingVillagerCoordinate = null;
      _movingVillagerRole = null;
      _movingVillagerTurn = null;
    });
  }

  Future<void> _showWarriorOptionsDialog({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required OnlineBoardPiece piece,
    required String role,
    required String coordinate,
    required _OnlineBoardData data,
  }) async {
    if (_warriorAttackInProgress ||
        _pieceUpgradeInProgress ||
        _leaving ||
        game.currentPlayer != role ||
        game.winner != null ||
        piece.type != 'warrior') {
      return;
    }

    final option = data.optionForPiece(piece, _translations);
    final canAttack = game.canWarriorAttack(role, coordinate);
    final canMove = player.availableWarriorMoveCoordinates().isNotEmpty;
    final pointsAvailable = player.accumulatedPoints;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.brown[800]!, Colors.brown[900]!],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold, width: 3),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚔️', style: TextStyle(fontSize: 25)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          option.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropStatRow(
                          '⚔️',
                          piece.primaryStat,
                          Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCropStatRow(
                          '❤️ ${_text('vida', 'Vida:', 'Health:')}',
                          piece.health,
                          Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  if (canAttack) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: _buildCropActionButton(
                        dialogContext: dialogContext,
                        title: _text('atacar', 'ATACAR', 'ATTACK'),
                        icon: Icons.sports_martial_arts_rounded,
                        color: Colors.redAccent,
                        value: 'attack',
                      ),
                    ),
                  ],
                  if (canMove) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildCropActionButton(
                        dialogContext: dialogContext,
                        title: _text('mover', 'MOVER', 'MOVE'),
                        icon: Icons.open_with_rounded,
                        color: const Color(0xFF64B5F6),
                        value: 'move',
                      ),
                    ),
                  ],
                  if (pointsAvailable > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: _gold,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$pointsAvailable ${_text('puntos_disponibles', 'puntos disponibles', 'available points')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCropActionButton(
                            dialogContext: dialogContext,
                            title: _text(
                              'mejorar_ataque_full',
                              'MEJORAR ATAQUE',
                              'UPGRADE ATTACK',
                            ),
                            icon: Icons.gps_fixed_rounded,
                            color: Colors.orangeAccent,
                            value: 'upgrade_attack',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCropActionButton(
                            dialogContext: dialogContext,
                            title: _text(
                              'mejorar_salud',
                              'MEJORAR SALUD',
                              'UPGRADE HEALTH',
                            ),
                            icon: Icons.favorite_rounded,
                            color: Colors.lightGreenAccent,
                            value: 'upgrade_health',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: Text(_text('cancelar', 'CANCELAR', 'CANCEL')),
                  ),
                ],
              ),
            ),
          ),
    );
    if (action == null || !mounted || _leaving) return;
    if (action == 'move') {
      _beginWarriorMove(game: game, role: role, coordinate: coordinate);
    } else if (action == 'attack') {
      await _attackWithWarrior(game: game, role: role, coordinate: coordinate);
    } else if (action == 'upgrade_attack' || action == 'upgrade_health') {
      await _upgradeWarrior(
        game: game,
        player: player,
        piece: piece,
        role: role,
        coordinate: coordinate,
        upgrade: action == 'upgrade_attack' ? 'attack' : 'health',
      );
    }
  }

  Future<void> _upgradeWarrior({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required OnlineBoardPiece piece,
    required String role,
    required String coordinate,
    required String upgrade,
  }) async {
    if (_pieceUpgradeInProgress ||
        _leaving ||
        player.accumulatedPoints <= 0 ||
        game.currentPlayer != role ||
        game.winner != null ||
        piece.type != 'warrior' ||
        (upgrade != 'attack' && upgrade != 'health')) {
      return;
    }

    final isAttack = upgrade == 'attack';
    final pointsToSpend = await _showUpgradePointsDialog(
      title: _text(
        isAttack ? 'mejorar_ataque_full' : 'mejorar_salud',
        isAttack ? 'MEJORAR ATAQUE' : 'MEJORAR SALUD',
        isAttack ? 'UPGRADE ATTACK' : 'UPGRADE HEALTH',
      ),
      icon: isAttack ? '⚔️' : '❤️',
      currentValue: isAttack ? piece.primaryStat : piece.health,
      pointsAvailable: player.accumulatedPoints,
      accentColor: isAttack ? Colors.orangeAccent : Colors.lightGreenAccent,
      confirmLabel: _text('mejorar', 'MEJORAR', 'UPGRADE'),
    );
    if (pointsToSpend == null || !mounted || _leaving) return;
    if (_pieceUpgradeInProgress) return;

    setState(() => _pieceUpgradeInProgress = true);
    try {
      final committed = await OnlineRoomsService.upgradeBoardPieceForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        coordinate: coordinate,
        points: pointsToSpend,
        pieceType: 'warrior',
        upgrade: upgrade,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_warrior_upgrade_failed',
            'No se pudo mejorar al guerrero: revisa el turno, los puntos y la casilla.',
            'Could not upgrade the warrior: check the turn, points, and square.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_warrior_upgrade_error',
            'Error al mejorar al guerrero: {error}',
            'Warrior upgrade error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _pieceUpgradeInProgress = false);
    }
  }

  void _beginWarriorMove({
    required OnlineGameState game,
    required String role,
    required String coordinate,
  }) {
    setState(() {
      _movingWarriorCoordinate = coordinate;
      _movingWarriorRole = role;
      _movingWarriorTurn = game.turn;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'online_warrior_move_select',
              'Selecciona una casilla vacía para mover al guerrero.',
              'Select an empty square to move the warrior.',
            ),
          ),
          action: SnackBarAction(
            label: _text('cancelar', 'CANCELAR', 'CANCEL'),
            onPressed: _cancelWarriorMove,
          ),
        ),
      );
  }

  Future<void> _moveWarriorTo({
    required OnlineGameState game,
    required String role,
    required String destination,
  }) async {
    final source = _movingWarriorCoordinate;
    if (source == null ||
        _movingWarriorTurn != game.turn ||
        _movingWarriorRole != role ||
        _pieceUpgradeInProgress) {
      _cancelWarriorMove();
      return;
    }

    setState(() => _pieceUpgradeInProgress = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      final moved = await OnlineRoomsService.moveWarriorForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        fromCoordinate: source,
        toCoordinate: destination,
      );
      if (!moved && mounted) {
        _showMessage(
          _text(
            'online_warrior_move_failed',
            'No se pudo mover al guerrero: revisa el turno y la casilla.',
            'Could not move the warrior: check the turn and square.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_warrior_move_error',
            'Error al mover al guerrero: {error}',
            'Warrior move error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pieceUpgradeInProgress = false;
          _movingWarriorCoordinate = null;
          _movingWarriorRole = null;
          _movingWarriorTurn = null;
        });
      }
    }
  }

  void _cancelWarriorMove() {
    if (!mounted ||
        (_movingWarriorCoordinate == null &&
            _movingWarriorRole == null &&
            _movingWarriorTurn == null)) {
      return;
    }
    setState(() {
      _movingWarriorCoordinate = null;
      _movingWarriorRole = null;
      _movingWarriorTurn = null;
    });
  }

  Future<void> _attackWithWarrior({
    required OnlineGameState game,
    required String role,
    required String coordinate,
  }) async {
    if (_warriorAttackInProgress ||
        _leaving ||
        game.currentPlayer != role ||
        !game.canWarriorAttack(role, coordinate)) {
      return;
    }
    setState(() => _warriorAttackInProgress = true);
    try {
      final committed = await OnlineRoomsService.attackWithWarriorForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        warriorCoordinate: coordinate,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_warrior_attack_failed',
            'No se pudo realizar el ataque del guerrero. Revisa el turno y el objetivo.',
            'The warrior attack could not be completed. Check the turn and target.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_warrior_attack_error',
            'Error al atacar con el guerrero: {error}',
            'Warrior attack error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _warriorAttackInProgress = false);
    }
  }

  Future<void> _showHospitalOptionsDialog({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required OnlineBoardPiece piece,
    required String role,
    required String coordinate,
    required _OnlineBoardData data,
  }) async {
    final pointsAvailable = player.accumulatedPoints;
    if (_pieceUpgradeInProgress ||
        _leaving ||
        pointsAvailable <= 0 ||
        game.currentPlayer != role ||
        game.winner != null ||
        piece.type != 'hospital') {
      return;
    }

    final name = data.optionForPiece(piece, _translations).name;
    final upgrade = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.brown[800]!, Colors.brown[900]!],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold, width: 3),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏥', style: TextStyle(fontSize: 25)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropStatRow(
                          '💊 ${_text('curacion', 'Curación:', 'Healing:')}',
                          piece.primaryStat,
                          Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCropStatRow(
                          '🏥 ${_text('vida', 'Vida:', 'Health:')}',
                          piece.health,
                          Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, color: _gold, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$pointsAvailable ${_text('puntos_disponibles', 'puntos disponibles', 'available points')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropActionButton(
                          dialogContext: dialogContext,
                          title: _text(
                            'mejorar_curacion',
                            'MEJORAR CURACIÓN',
                            'UPGRADE HEALING',
                          ),
                          icon: Icons.healing_rounded,
                          color: Colors.greenAccent,
                          value: 'healing',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCropActionButton(
                          dialogContext: dialogContext,
                          title: _text('reconstruir', 'RECONSTRUIR', 'REBUILD'),
                          icon: Icons.construction_rounded,
                          color: const Color(0xFF4FC3F7),
                          value: 'health',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: Text(_text('cancelar', 'CANCELAR', 'CANCEL')),
                  ),
                ],
              ),
            ),
          ),
    );
    if (upgrade == null || !mounted || _leaving) return;

    final isHealing = upgrade == 'healing';
    final pointsToSpend = await _showUpgradePointsDialog(
      title: _text(
        isHealing ? 'mejorar_curacion' : 'reconstruir',
        isHealing ? 'MEJORAR CURACIÓN' : 'RECONSTRUIR',
        isHealing ? 'UPGRADE HEALING' : 'REBUILD',
      ),
      icon: isHealing ? '💊' : '🏥',
      currentValue: isHealing ? piece.primaryStat : piece.health,
      pointsAvailable: pointsAvailable,
      accentColor: isHealing ? Colors.greenAccent : const Color(0xFF4FC3F7),
      confirmLabel: _text('mejorar', 'MEJORAR', 'UPGRADE'),
    );
    if (pointsToSpend == null || !mounted || _leaving) return;
    if (_pieceUpgradeInProgress) return;

    setState(() => _pieceUpgradeInProgress = true);
    try {
      final committed = await OnlineRoomsService.upgradeBoardPieceForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        coordinate: coordinate,
        points: pointsToSpend,
        pieceType: 'hospital',
        upgrade: upgrade,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_hospital_upgrade_failed',
            'No se pudo mejorar el hospital: revisa el turno, los puntos y la casilla.',
            'Could not upgrade the hospital: check the turn, points, and square.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_hospital_upgrade_error',
            'Error al mejorar el hospital: {error}',
            'Hospital upgrade error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _pieceUpgradeInProgress = false);
    }
  }

  Future<void> _showTowerOptionsDialog({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required OnlineBoardPiece piece,
    required String role,
    required String coordinate,
    required _OnlineBoardData data,
  }) async {
    final pointsAvailable = player.accumulatedPoints;
    if (_pieceUpgradeInProgress ||
        _leaving ||
        pointsAvailable <= 0 ||
        game.currentPlayer != role ||
        game.winner != null ||
        piece.type != 'tower') {
      return;
    }

    final name = data.optionForPiece(piece, _translations).name;
    final upgrade = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.brown[800]!, Colors.brown[900]!],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold, width: 3),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🗼', style: TextStyle(fontSize: 25)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropStatRow(
                          '🏹 ${_text('ataque', 'Ataque:', 'Attack:')}',
                          piece.primaryStat,
                          Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCropStatRow(
                          '🏰 ${_text('vida', 'Vida:', 'Health:')}',
                          piece.health,
                          Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, color: _gold, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$pointsAvailable ${_text('puntos_disponibles', 'puntos disponibles', 'available points')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropActionButton(
                          dialogContext: dialogContext,
                          title: _text(
                            'mejorar_ataque_full',
                            'MEJORAR ATAQUE',
                            'UPGRADE ATTACK',
                          ),
                          icon: Icons.gps_fixed_rounded,
                          color: Colors.orangeAccent,
                          value: 'attack',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCropActionButton(
                          dialogContext: dialogContext,
                          title: _text('reconstruir', 'RECONSTRUIR', 'REBUILD'),
                          icon: Icons.construction_rounded,
                          color: const Color(0xFF4FC3F7),
                          value: 'health',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: Text(_text('cancelar', 'CANCELAR', 'CANCEL')),
                  ),
                ],
              ),
            ),
          ),
    );
    if (upgrade == null || !mounted || _leaving) return;

    final isAttack = upgrade == 'attack';
    final pointsToSpend = await _showUpgradePointsDialog(
      title: _text(
        isAttack ? 'mejorar_ataque_full' : 'reconstruir',
        isAttack ? 'MEJORAR ATAQUE' : 'RECONSTRUIR',
        isAttack ? 'UPGRADE ATTACK' : 'REBUILD',
      ),
      icon: isAttack ? '🏹' : '🏰',
      currentValue: isAttack ? piece.primaryStat : piece.health,
      pointsAvailable: pointsAvailable,
      accentColor: isAttack ? Colors.orangeAccent : const Color(0xFF4FC3F7),
      confirmLabel: _text('mejorar', 'MEJORAR', 'UPGRADE'),
    );
    if (pointsToSpend == null || !mounted || _leaving) return;
    if (_pieceUpgradeInProgress) return;

    setState(() => _pieceUpgradeInProgress = true);
    try {
      final committed = await OnlineRoomsService.upgradeBoardPieceForTurn(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        coordinate: coordinate,
        points: pointsToSpend,
        pieceType: 'tower',
        upgrade: upgrade,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_tower_upgrade_failed',
            'No se pudo mejorar la torre: revisa el turno, los puntos y la casilla.',
            'Could not upgrade the tower: check the turn, points, and square.',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _text(
            'online_tower_upgrade_error',
            'Error al mejorar la torre: {error}',
            'Tower upgrade error: {error}',
          ).replaceAll('{error}', error.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _pieceUpgradeInProgress = false);
    }
  }

  Widget _buildCropStatRow(String label, int value, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        '$value',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildCropActionButton({
    required BuildContext dialogContext,
    required String title,
    required IconData icon,
    required Color color,
    required String value,
  }) => ElevatedButton(
    onPressed: () => Navigator.pop(dialogContext, value),
    style: ElevatedButton.styleFrom(
      backgroundColor: color.withValues(alpha: 0.18),
      foregroundColor: color,
      minimumSize: const Size(0, 60),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      side: BorderSide(color: color.withValues(alpha: 0.8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(title, textAlign: TextAlign.center, maxLines: 2),
      ],
    ),
  );

  Future<int?> _showUpgradePointsDialog({
    required String title,
    required String icon,
    required int currentValue,
    required int pointsAvailable,
    required Color accentColor,
    required String confirmLabel,
  }) => showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      var selectedPoints = 1.0;
      return StatefulBuilder(
        builder:
            (context, setStateDialog) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.brown[900],
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _gold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$icon $title',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${_text('valor_actual', 'Valor actual:', 'Current value:')} $currentValue',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '⚡ $pointsAvailable ${_text('disponibles', 'disponibles', 'available')}',
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accentColor,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: accentColor,
                        overlayColor: accentColor.withValues(alpha: 0.18),
                      ),
                      child: Slider(
                        value: selectedPoints,
                        min: 1,
                        max: pointsAvailable.toDouble(),
                        divisions:
                            pointsAvailable > 1 ? pointsAvailable - 1 : null,
                        onChanged:
                            pointsAvailable > 1
                                ? (value) =>
                                    setStateDialog(() => selectedPoints = value)
                                : null,
                      ),
                    ),
                    Text(
                      '+${selectedPoints.round()} ⚡',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(
                                color: _gold.withValues(alpha: 0.6),
                              ),
                              minimumSize: const Size(0, 46),
                            ),
                            child: Text(
                              _text('cancelar', 'CANCELAR', 'CANCEL'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pop(
                                  dialogContext,
                                  selectedPoints.round(),
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.brown[900],
                              minimumSize: const Size(0, 46),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text(confirmLabel),
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

  Widget _buildPieceCell(
    double cellSide,
    OnlineBoardPiece piece,
    _OnlineBoardData data, {
    VoidCallback? onTap,
    bool animateCrop = false,
    bool animateHospital = false,
    bool animateVillager = false,
    bool animateTowerAttack = false,
    bool animateTowerRelease = false,
    bool animateTowerHit = false,
    bool showWarriorAttackReady = false,
  }) {
    final option = data.optionForPiece(piece, _translations);
    final statHeight = cellSide * 0.25;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          boxShadow:
              animateHospital || animateTowerHit
                  ? [
                    BoxShadow(
                      color:
                          animateTowerHit
                              ? Colors.red.withValues(alpha: 0.8)
                              : Colors.green.withValues(alpha: 0.8),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ]
                  : null,
        ),
        child: SizedBox(
          width: cellSide,
          height: cellSide,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(cellSide * 0.05),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cellSide * 0.08),
                    child: AnimatedScale(
                      scale:
                          animateTowerAttack
                              ? 0.7
                              : animateTowerRelease
                              ? 1
                              : animateVillager
                              ? 0.5
                              : animateCrop || animateHospital
                              ? 1.1
                              : 1,
                      duration:
                          animateTowerAttack
                              ? _towerChargeDuration
                              : animateTowerRelease
                              ? _towerAttackDuration - _towerChargeDuration
                              : animateVillager
                              ? _hammerHitDuration
                              : const Duration(milliseconds: 500),
                      child: Image.asset(
                        option.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => ColoredBox(
                              color: Colors.brown.shade700,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                              ),
                            ),
                      ),
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
                  padding: EdgeInsets.symmetric(horizontal: cellSide * 0.025),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(cellSide * 0.08),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_statIcon(piece.type)} ${piece.primaryStat}   ${_healthIcon(piece.type)} ${piece.health}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: cellSide * 0.12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              if (showWarriorAttackReady)
                Positioned(
                  top: cellSide * 0.08,
                  right: cellSide * 0.08,
                  child: Container(
                    padding: EdgeInsets.all(cellSide * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.9),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '⚔️',
                      style: TextStyle(fontSize: cellSide * 0.13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statIcon(String type) => switch (type) {
    'warrior' => '⚔️',
    'tower' => '🏹',
    'hospital' => '💊',
    'crop' => '🌾',
    'villager' => '🔨',
    _ => '',
  };

  String _healthIcon(String type) => switch (type) {
    'warrior' => '❤️',
    'tower' => '🏰',
    'hospital' => '🏥',
    'crop' => '🌱',
    'villager' => '👨',
    _ => '❤️',
  };

  List<_InvocationOption> _availableOptions(
    OnlineGamePlayer player,
    _OnlineBoardData data,
  ) {
    final options = <_InvocationOption>[];
    for (final id in player.warriorIds.toSet()) {
      final warrior = data.warriors[id];
      if (warrior != null &&
          warrior.costoInvocacion <= player.accumulatedPoints) {
        options.add(
          _InvocationOption(
            id: warrior.id,
            name: _translations[warrior.nombreId] ?? warrior.nombreId,
            imagePath: warrior.imagen,
            type: 'warrior',
            cost: warrior.costoInvocacion,
            health: warrior.vida,
            primaryStat: warrior.ataque,
          ),
        );
      }
    }

    final civilizationId = player.civilizationId;
    final tower = data.towers.values.where(
      (item) => item.civilizacionId == civilizationId,
    );
    if (tower.isNotEmpty) {
      final item = tower.first;
      if (item.costoInvocacion <= player.accumulatedPoints) {
        options.add(
          _InvocationOption(
            id: item.id,
            name: _translations['${item.id}_nombre'] ?? item.nombre,
            imagePath: item.imagen,
            type: 'tower',
            cost: item.costoInvocacion,
            health: item.vida,
            primaryStat: item.ataque,
          ),
        );
      }
    }
    final hospital = data.hospitals.values.where(
      (item) => item.civilizacionId == civilizationId,
    );
    if (hospital.isNotEmpty) {
      final item = hospital.first;
      if (item.costoInvocacion <= player.accumulatedPoints) {
        options.add(
          _InvocationOption(
            id: item.id,
            name: _translations['${item.id}_nombre'] ?? item.nombre,
            imagePath: item.imagen,
            type: 'hospital',
            cost: item.costoInvocacion,
            health: item.vida,
            primaryStat: item.poderCuracion,
          ),
        );
      }
    }
    final crop = data.crops.values.where(
      (item) => item.civilizacionId == civilizationId,
    );
    if (crop.isNotEmpty) {
      final item = crop.first;
      if (item.costoInvocacion <= player.accumulatedPoints) {
        options.add(
          _InvocationOption(
            id: item.id,
            name: _translations['${item.id}_nombre'] ?? item.nombre,
            imagePath: item.imagen,
            type: 'crop',
            cost: item.costoInvocacion,
            health: item.vida,
            primaryStat: item.puntosPorTurno,
          ),
        );
      }
    }
    final villager = data.villagers.values.where(
      (item) => item.civilizacionId == civilizationId,
    );
    if (villager.isNotEmpty) {
      final item = villager.first;
      if (item.costoInvocacion <= player.accumulatedPoints) {
        options.add(
          _InvocationOption(
            id: item.id,
            name: _translations['${item.id}_nombre'] ?? item.nombre,
            imagePath: item.imagen,
            type: 'villager',
            cost: item.costoInvocacion,
            health: item.vida,
            primaryStat: item.puntosReconstruccion,
          ),
        );
      }
    }
    return options;
  }

  Future<void> _showInvocationModal({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required _OnlineBoardData data,
    required int row,
    required int column,
  }) async {
    if (game.currentPlayer !=
            (widget.uid == widget.room.hostUid ? 'host' : 'guest') ||
        game.diceRolledTurn != game.turn ||
        game.harvestedTurn != game.turn ||
        _leaving) {
      return;
    }
    final options = _availableOptions(player, data);
    if (options.isEmpty) return;

    final selected = await showDialog<_InvocationOption>(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 620),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amber, width: 4),
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
                        Text(
                          '⚡ ${_text('invocar', 'INVOCAR', 'SUMMON')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${player.accumulatedPoints} ⚡',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      children: [
                        _buildOptionGroup(
                          dialogContext,
                          options
                              .where((option) => option.type == 'warrior')
                              .toList(),
                          _text('guerreros', 'GUERREROS', 'WARRIORS'),
                        ),
                        _buildOptionGroup(
                          dialogContext,
                          options
                              .where((option) => option.type != 'warrior')
                              .toList(),
                          _text(
                            'construcciones',
                            'CONSTRUCCIONES',
                            'BUILDINGS',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    if (selected == null || !mounted) return;
    await _summonPiece(
      game: game,
      player: player,
      option: selected,
      row: row,
      column: column,
    );
  }

  Widget _buildOptionGroup(
    BuildContext dialogContext,
    List<_InvocationOption> options,
    String title,
  ) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogContext, option),
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.grey[500],
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage(option.imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.name,
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
                            _buildInvocationStats(option),
                            const SizedBox(height: 2),
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
                                '⚡ ${option.cost}',
                                style: const TextStyle(
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
        ),
      ],
    );
  }

  Widget _buildInvocationStats(_InvocationOption option) {
    final (primaryIcon, healthIcon) = switch (option.type) {
      'warrior' => ('⚔️', '❤️'),
      'tower' => ('🏹', '🏰'),
      'hospital' => ('💊', '🏥'),
      'crop' => ('🌾', '🌱'),
      'villager' => ('🔨', '👨'),
      _ => ('', '❤️'),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          '$primaryIcon ${option.primaryStat}',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        Text(
          '$healthIcon ${option.health}',
          style: const TextStyle(color: Colors.red, fontSize: 15),
        ),
      ],
    );
  }

  Future<void> _summonPiece({
    required OnlineGameState game,
    required OnlineGamePlayer player,
    required _InvocationOption option,
    required int row,
    required int column,
  }) async {
    if (_summoningCoordinate != null) return;
    final role = widget.uid == widget.room.hostUid ? 'host' : 'guest';
    final coordinate = 'r${row}c$column';
    setState(() => _summoningCoordinate = coordinate);
    try {
      final committed = await OnlineRoomsService.summonPiece(
        room: widget.room,
        uid: widget.uid,
        role: role,
        turn: game.turn,
        row: row,
        column: column,
        type: option.type,
        id: option.id,
        cost: option.cost,
        health: option.health,
        primaryStat: option.primaryStat,
      );
      if (!committed && mounted) {
        _showMessage(
          _text(
            'online_summon_failed',
            'No se pudo invocar: revisa el turno, los puntos y la casilla.',
            'Could not summon: check the turn, points, and square.',
          ),
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _summoningCoordinate = null);
    }
  }

  Widget _buildStatsRow({
    required double cellSide,
    required String label,
    required bool isActive,
    required bool canPass,
    required int accumulatedPoints,
  }) {
    final activeColor = isActive ? _gold : Colors.white54;
    return SizedBox(
      height: cellSide * 0.5,
      child: Row(
        children: [
          Container(
            width: cellSide * 2,
            height: cellSide * 0.5,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.amber.withValues(alpha: 0.12) : null,
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.radio_button_checked : Icons.circle_outlined,
                  color: activeColor,
                  size: cellSide * 0.18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: activeColor,
                      fontSize: cellSide * 0.15,
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
                    '$accumulatedPoints',
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
          Container(
            width: cellSide,
            height: cellSide * 0.5,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Center(
              child: ElevatedButton(
                onPressed:
                    canPass && !_passingTurn && !_leaving ? _passTurn : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canPass ? _gold : Colors.grey[700],
                  foregroundColor: Colors.black87,
                  minimumSize: Size(cellSide * 0.9, cellSide * 0.3),
                  padding: EdgeInsets.zero,
                ),
                child:
                    _passingTurn && canPass
                        ? SizedBox(
                          width: cellSide * 0.15,
                          height: cellSide * 0.15,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87,
                          ),
                        )
                        : Text(
                          _text('pasar', 'PASAR', 'PASS'),
                          style: TextStyle(
                            fontSize: cellSide * 0.12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineBoardData {
  final Map<String, Civilizacion> civilizations;
  final Map<String, Guerrero> warriors;
  final Map<String, Torre> towers;
  final Map<String, Hospital> hospitals;
  final Map<String, Cultivo> crops;
  final Map<String, Aldeano> villagers;

  const _OnlineBoardData({
    required this.civilizations,
    required this.warriors,
    required this.towers,
    required this.hospitals,
    required this.crops,
    required this.villagers,
  });

  _InvocationOption optionForPiece(
    OnlineBoardPiece piece,
    Map<String, String> translations,
  ) {
    switch (piece.type) {
      case 'warrior':
        final item = warriors[piece.id]!;
        return _InvocationOption(
          id: item.id,
          name: translations[item.nombreId] ?? item.nombreId,
          imagePath: item.imagen,
          type: piece.type,
          cost: item.costoInvocacion,
          health: piece.health,
          primaryStat: piece.primaryStat,
        );
      case 'tower':
        final item = towers[piece.id]!;
        return _InvocationOption(
          id: item.id,
          name: translations['${item.id}_nombre'] ?? item.nombre,
          imagePath: item.imagen,
          type: piece.type,
          cost: item.costoInvocacion,
          health: piece.health,
          primaryStat: piece.primaryStat,
        );
      case 'hospital':
        final item = hospitals[piece.id]!;
        return _InvocationOption(
          id: item.id,
          name: translations['${item.id}_nombre'] ?? item.nombre,
          imagePath: item.imagen,
          type: piece.type,
          cost: item.costoInvocacion,
          health: piece.health,
          primaryStat: piece.primaryStat,
        );
      case 'crop':
        final item = crops[piece.id]!;
        return _InvocationOption(
          id: item.id,
          name: translations['${item.id}_nombre'] ?? item.nombre,
          imagePath: item.imagen,
          type: piece.type,
          cost: item.costoInvocacion,
          health: piece.health,
          primaryStat: piece.primaryStat,
        );
      case 'villager':
        final item = villagers[piece.id]!;
        return _InvocationOption(
          id: item.id,
          name: translations['${item.id}_nombre'] ?? item.nombre,
          imagePath: item.imagen,
          type: piece.type,
          cost: item.costoInvocacion,
          health: piece.health,
          primaryStat: piece.primaryStat,
        );
      default:
        throw StateError('Tipo de pieza desconocido: ${piece.type}');
    }
  }
}

class _InvocationOption {
  final String id;
  final String name;
  final String imagePath;
  final String type;
  final int cost;
  final int health;
  final int primaryStat;

  const _InvocationOption({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.type,
    required this.cost,
    required this.health,
    required this.primaryStat,
  });
}
