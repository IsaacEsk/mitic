import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:mitic/models/online_room.dart';
import 'package:mitic/models/online_game_state.dart';
import 'package:mitic/models/online_room_setup.dart';
import 'package:mitic/services/realtime_database_service.dart';

class OnlineTowerAttackResolution {
  final bool committed;
  final bool complete;
  final bool attacked;
  final OnlineTowerAttackEvent? attack;

  const OnlineTowerAttackResolution({
    required this.committed,
    required this.complete,
    required this.attacked,
    required this.attack,
  });
}

class OnlineEarthquakeResolution {
  final bool committed;
  final OnlineEarthquakeEvent? event;
  final bool gameFinished;

  const OnlineEarthquakeResolution({
    required this.committed,
    required this.event,
    required this.gameFinished,
  });
}

class OnlineDisasterResolution {
  final bool committed;
  final OnlineDisasterEvent? event;

  const OnlineDisasterResolution({
    required this.committed,
    required this.event,
  });
}

class OnlineRoomsService {
  OnlineRoomsService._();

  static DatabaseReference get _roomsRef =>
      RealtimeDatabaseService.ref('salas');

  static Stream<List<OnlineRoom>> watchWaitingRooms() {
    return _roomsRef.orderByChild('status').equalTo('waiting').onValue.map((
      event,
    ) {
      final value = event.snapshot.value;
      if (value == null) return <OnlineRoom>[];
      if (value is! Map) {
        throw const FormatException(
          'La lista de salas tiene un formato inválido.',
        );
      }

      final rooms =
          value.entries
              .map(
                (entry) =>
                    OnlineRoom.fromSnapshot(entry.key.toString(), entry.value),
              )
              .where((room) => room.guestUid == null)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rooms;
    });
  }

  static Future<OnlineRoom> createRoom(String hostUid) async {
    final roomRef = _roomsRef.push();
    final roomId = roomRef.key;
    if (roomId == null) {
      throw StateError('No se pudo generar el identificador de la sala.');
    }

    final room = OnlineRoom(
      id: roomId,
      hostUid: hostUid,
      guestUid: null,
      status: 'waiting',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await roomRef.set({
      'hostUid': hostUid,
      'status': 'waiting',
      'phase': 'waiting',
      'createdAt': ServerValue.timestamp,
    });

    return room;
  }

  static Future<bool> joinRoom(String roomId, String guestUid) async {
    final result = await _roomsRef.child(roomId).runTransaction((value) {
      if (value is! Map) return Transaction.abort();

      final room = Map<Object?, Object?>.from(value);
      if (room['status'] != 'waiting' ||
          room['guestUid'] != null ||
          room['hostUid'] == guestUid) {
        return Transaction.abort();
      }
      room['guestUid'] = guestUid;
      room['status'] = 'ready';
      room['phase'] = 'selectingCivilizations';
      return Transaction.success(room);
    });

    return result.committed;
  }

  static DatabaseReference roomRef(String roomId) => _roomsRef.child(roomId);

  static Stream<OnlineRoomSetup> watchSetup(String roomId) {
    return roomRef(roomId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        throw StateError('La sala ya no existe.');
      }
      return OnlineRoomSetup.fromSnapshot(value);
    });
  }

  static Future<void> saveCivilization({
    required OnlineRoom room,
    required String uid,
    required String civilizationId,
    required int monumentMaxHealth,
  }) async {
    if (monumentMaxHealth <= 0) {
      throw ArgumentError.value(
        monumentMaxHealth,
        'monumentMaxHealth',
        'Monument health must be positive.',
      );
    }
    final role = _roleFor(room, uid);
    await roomRef(room.id).child('players/$role').update({
      'civilizationId': civilizationId,
      'monumentMaxHealth': monumentMaxHealth,
    });
  }

  static Future<void> saveAllies({
    required OnlineRoom room,
    required String uid,
    required List<String> allyIds,
  }) async {
    if (allyIds.length != 3 || allyIds.toSet().length != 3) {
      throw ArgumentError.value(
        allyIds,
        'allyIds',
        'Exactly three unique allies must be selected.',
      );
    }
    final role = _roleFor(room, uid);
    await roomRef(room.id).child('players/$role/allyIds').set(allyIds);
  }

  static Future<bool> initializeGameIfReady(OnlineRoom room) async {
    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();

      final roomData = Map<Object?, Object?>.from(value);
      if (roomData['phase'] == 'gameReady' && roomData['game'] is Map) {
        return Transaction.success(roomData);
      }
      if (roomData['status'] != 'ready' ||
          roomData['guestUid'] != room.guestUid ||
          room.guestUid == null) {
        return Transaction.abort();
      }

      final setup = OnlineRoomSetup.fromSnapshot(roomData);
      if (!setup.bothCivilizationsSelected || !setup.bothPlayersReady) {
        return Transaction.abort();
      }

      final hostCivId = setup.host.civilizationId!;
      final guestCivId = setup.guest.civilizationId!;
      final hostMonumentHealth = setup.host.monumentMaxHealth;
      final guestMonumentHealth = setup.guest.monumentMaxHealth;
      if (hostMonumentHealth == null || guestMonumentHealth == null) {
        return Transaction.abort();
      }
      roomData['phase'] = 'gameReady';
      roomData['game'] = {
        'version': 1,
        'status': 'ready',
        'currentPlayer': 'host',
        'turn': 0,
        'phase': 'initial',
        'earthquakeCountdown': Random().nextInt(11) + 5,
        'plagueCountdown': Random().nextInt(11) + 5,
        'epidemicCountdown': Random().nextInt(11) + 5,
        'players': {
          'host': {
            'uid': room.hostUid,
            'civilizationId': hostCivId,
            'warriorIds': ['${hostCivId}_001', ...setup.host.allyIds],
            'monumentHealth': hostMonumentHealth,
            'accumulatedPoints': 0,
          },
          'guest': {
            'uid': room.guestUid,
            'civilizationId': guestCivId,
            'warriorIds': ['${guestCivId}_001', ...setup.guest.allyIds],
            'monumentHealth': guestMonumentHealth,
            'accumulatedPoints': 0,
          },
        },
      };
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Stream<OnlineGameState> watchGame(String roomId) {
    return roomRef(roomId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        throw StateError('La sala ya no existe.');
      }
      return OnlineGameState.fromRoomSnapshot(value);
    });
  }

  static Future<bool> passTurn({
    required OnlineRoom room,
    required String uid,
  }) async {
    final role = _roleFor(room, uid);
    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['status'] != 'ready' || game['currentPlayer'] != role) {
        return Transaction.abort();
      }

      final currentTurn = game['turn'];
      if (currentTurn is! num ||
          currentTurn < 0 ||
          game['diceRolledTurn'] != currentTurn ||
          game['harvestedTurn'] != currentTurn ||
          game['towerAttacksTurn'] != currentTurn) {
        return Transaction.abort();
      }
      final storedEarthquakeCountdown = game['earthquakeCountdown'];
      final storedPlagueCountdown = game['plagueCountdown'];
      final storedEpidemicCountdown = game['epidemicCountdown'];
      bool isValidDisasterCountdown(Object? value) =>
          value == null ||
          (value is num && value >= 0 && value == value.toInt());
      if (storedEarthquakeCountdown != null &&
          (storedEarthquakeCountdown is! num ||
              storedEarthquakeCountdown < 0 ||
              storedEarthquakeCountdown != storedEarthquakeCountdown.toInt())) {
        return Transaction.abort();
      }
      if (!isValidDisasterCountdown(storedPlagueCountdown) ||
          !isValidDisasterCountdown(storedEpidemicCountdown)) {
        return Transaction.abort();
      }
      final nextRole = role == 'host' ? 'guest' : 'host';
      final nextTurn = currentTurn.toInt() + 1;
      game['currentPlayer'] = nextRole;
      game['turn'] = nextTurn;
      final earthquakeCountdown =
          storedEarthquakeCountdown is num
              ? storedEarthquakeCountdown.toInt()
              : Random().nextInt(11) + 5;
      game['earthquakeCountdown'] =
          earthquakeCountdown > 0 ? earthquakeCountdown - 1 : 0;
      final plagueCountdown =
          storedPlagueCountdown is num
              ? storedPlagueCountdown.toInt()
              : Random().nextInt(11) + 5;
      final epidemicCountdown =
          storedEpidemicCountdown is num
              ? storedEpidemicCountdown.toInt()
              : Random().nextInt(11) + 5;
      game['plagueCountdown'] = plagueCountdown > 0 ? plagueCountdown - 1 : 0;
      game['epidemicCountdown'] =
          epidemicCountdown > 0 ? epidemicCountdown - 1 : 0;
      game.remove('lastHospitalHealing');
      game.remove('lastVillagerRepair');
      game.remove('towerAttackTurn');
      game.remove('towerAttackRole');
      game.remove('towerCoordinates');
      game.remove('towerAttackIndex');
      game.remove('towerAttacksComplete');
      game.remove('towerAttacksTurn');
      game.remove('lastTowerAttack');
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Future<OnlineEarthquakeResolution> resolveEarthquakeForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
  }) async {
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }

    final random = Random();
    OnlineEarthquakeEvent? event;
    var gameFinished = false;
    final result = await roomRef(room.id).runTransaction((value) {
      event = null;
      gameFinished = false;
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['currentPlayer'] != role || game['turn'] != turn) {
        return Transaction.abort();
      }

      final rawProcessedTurn = game['earthquakeProcessedTurn'];
      if (rawProcessedTurn != null &&
          (rawProcessedTurn is! num ||
              rawProcessedTurn < 0 ||
              rawProcessedTurn != rawProcessedTurn.toInt())) {
        return Transaction.abort();
      }
      if (rawProcessedTurn == turn) {
        final rawEvent = game['lastEarthquake'];
        if (rawEvent != null) {
          try {
            final parsedEvent = OnlineEarthquakeEvent.fromValue(rawEvent);
            if (parsedEvent.turn > turn) {
              return Transaction.abort();
            }
            if (parsedEvent.turn == turn) {
              if (parsedEvent.playerRole != role) {
                return Transaction.abort();
              }
              event = parsedEvent;
            }
          } on FormatException {
            return Transaction.abort();
          }
        }
        gameFinished = game['status'] == 'finished';
        return game['status'] == 'ready' || gameFinished
            ? Transaction.success(roomData)
            : Transaction.abort();
      }

      if (game['status'] != 'ready' ||
          game['diceRolledTurn'] == turn ||
          game['harvestedTurn'] == turn) {
        return Transaction.abort();
      }

      final rawCountdown = game['earthquakeCountdown'];
      if (rawCountdown != null &&
          (rawCountdown is! num ||
              rawCountdown < 0 ||
              rawCountdown != rawCountdown.toInt())) {
        return Transaction.abort();
      }
      var countdown =
          rawCountdown is num ? rawCountdown.toInt() : random.nextInt(11) + 5;
      game['earthquakeProcessedTurn'] = turn;
      if (countdown > 0) {
        game['earthquakeCountdown'] = countdown;
        roomData['game'] = game;
        return Transaction.success(roomData);
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      if (player['uid'] != uid) return Transaction.abort();
      final board = _copyBoard(player['board']);
      final monumentHealth = player['monumentHealth'];
      if (board == null || monumentHealth is! num || monumentHealth < 0) {
        return Transaction.abort();
      }

      final buildings = <String, OnlineBoardPiece>{};
      for (final entry in board.entries) {
        if (entry.key is! String) return Transaction.abort();
        try {
          final piece = OnlineBoardPiece.fromValue(entry.value);
          if (piece.type == 'tower' || piece.type == 'hospital') {
            buildings[entry.key as String] = piece;
          }
        } on FormatException {
          return Transaction.abort();
        }
      }

      var damage = 0;
      if (buildings.isNotEmpty) {
        final buildingHealth = buildings.values.map((piece) => piece.health);
        final minimumHealth = buildingHealth.reduce(min);
        final maximumHealth = buildingHealth.reduce(max);
        damage =
            random.nextInt(maximumHealth - minimumHealth + 1) + minimumHealth;
      }

      var affectedStructures = 0;
      if (damage > 0) {
        for (final entry in buildings.entries) {
          final healthAfter = entry.value.health - damage;
          affectedStructures++;
          if (healthAfter <= 0) {
            board.remove(entry.key);
          } else {
            final rawPiece = board[entry.key];
            if (rawPiece is! Map) return Transaction.abort();
            final updatedPiece = Map<Object?, Object?>.from(rawPiece);
            updatedPiece['health'] = healthAfter;
            board[entry.key] = updatedPiece;
          }
        }
      }

      final healthAfter = monumentHealth.toInt() - damage;
      final monumentDestroyed = damage > 0 && healthAfter <= 0;
      if (damage > 0) {
        player['monumentHealth'] = healthAfter > 0 ? healthAfter : 0;
      }
      player['board'] = board;
      players[role] = player;
      game['players'] = players;
      if (monumentDestroyed) {
        game['status'] = 'finished';
        game['winner'] = role == 'host' ? 'guest' : 'host';
      }

      final committedEvent = OnlineEarthquakeEvent(
        turn: turn,
        playerRole: role,
        damage: damage,
        affectedStructures: affectedStructures,
        monumentDestroyed: monumentDestroyed,
      );
      event = committedEvent;
      game['lastEarthquake'] = committedEvent.toValue();
      countdown = random.nextInt(11) + 5;
      game['earthquakeCountdown'] = countdown;
      gameFinished = monumentDestroyed;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return OnlineEarthquakeResolution(
      committed: result.committed,
      event: event,
      gameFinished: gameFinished,
    );
  }

  static Future<OnlineDisasterResolution> resolvePlagueForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
  }) => _resolveBoardDisasterForTurn(
    room: room,
    uid: uid,
    role: role,
    turn: turn,
    disaster: 'plague',
    affectedTypes: const {'crop'},
    prerequisiteProcessedTurn: 'earthquakeProcessedTurn',
  );

  static Future<OnlineDisasterResolution> resolveEpidemicForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
  }) => _resolveBoardDisasterForTurn(
    room: room,
    uid: uid,
    role: role,
    turn: turn,
    disaster: 'epidemic',
    affectedTypes: const {'warrior', 'villager'},
    prerequisiteProcessedTurn: 'plagueProcessedTurn',
  );

  static Future<OnlineDisasterResolution> _resolveBoardDisasterForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
    required String disaster,
    required Set<String> affectedTypes,
    required String prerequisiteProcessedTurn,
  }) async {
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }
    final countdownKey = '${disaster}Countdown';
    final processedTurnKey = '${disaster}ProcessedTurn';
    final eventKey = 'last${disaster[0].toUpperCase()}${disaster.substring(1)}';
    final random = Random();
    OnlineDisasterEvent? event;
    final result = await roomRef(room.id).runTransaction((value) {
      event = null;
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          game['turn'] != turn ||
          game[prerequisiteProcessedTurn] != turn) {
        return Transaction.abort();
      }

      final rawProcessedTurn = game[processedTurnKey];
      if (rawProcessedTurn != null &&
          (rawProcessedTurn is! num ||
              rawProcessedTurn < 0 ||
              rawProcessedTurn != rawProcessedTurn.toInt())) {
        return Transaction.abort();
      }
      if (rawProcessedTurn == turn) {
        final rawEvent = game[eventKey];
        if (rawEvent != null) {
          try {
            final parsedEvent = OnlineDisasterEvent.fromValue(rawEvent);
            if (parsedEvent.turn > turn ||
                (parsedEvent.turn == turn && parsedEvent.playerRole != role)) {
              return Transaction.abort();
            }
            if (parsedEvent.turn == turn) event = parsedEvent;
          } on FormatException {
            return Transaction.abort();
          }
        }
        return Transaction.success(roomData);
      }
      if (game['diceRolledTurn'] == turn || game['harvestedTurn'] == turn) {
        return Transaction.abort();
      }

      final rawCountdown = game[countdownKey];
      if (rawCountdown != null &&
          (rawCountdown is! num ||
              rawCountdown < 0 ||
              rawCountdown != rawCountdown.toInt())) {
        return Transaction.abort();
      }
      final countdown =
          rawCountdown is num ? rawCountdown.toInt() : random.nextInt(11) + 5;
      game[processedTurnKey] = turn;
      if (countdown > 0) {
        game[countdownKey] = countdown;
        roomData['game'] = game;
        return Transaction.success(roomData);
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      if (player['uid'] != uid) return Transaction.abort();
      final board = _copyBoard(player['board']);
      if (board == null) return Transaction.abort();

      final affectedPieces = <String, OnlineBoardPiece>{};
      for (final entry in board.entries) {
        if (entry.key is! String) return Transaction.abort();
        try {
          final piece = OnlineBoardPiece.fromValue(entry.value);
          if (affectedTypes.contains(piece.type)) {
            affectedPieces[entry.key as String] = piece;
          }
        } on FormatException {
          return Transaction.abort();
        }
      }

      var damage = 0;
      if (affectedPieces.isNotEmpty) {
        final healthValues = affectedPieces.values.map((piece) => piece.health);
        final minimumHealth = healthValues.reduce(min);
        final maximumHealth = healthValues.reduce(max);
        damage =
            random.nextInt(maximumHealth - minimumHealth + 1) + minimumHealth;
      }

      var destroyedPieces = 0;
      if (damage > 0) {
        for (final entry in affectedPieces.entries) {
          final healthAfter = entry.value.health - damage;
          if (healthAfter <= 0) {
            board.remove(entry.key);
            destroyedPieces++;
          } else {
            final rawPiece = board[entry.key];
            if (rawPiece is! Map) return Transaction.abort();
            final updatedPiece = Map<Object?, Object?>.from(rawPiece);
            updatedPiece['health'] = healthAfter;
            board[entry.key] = updatedPiece;
          }
        }
      }

      player['board'] = board;
      players[role] = player;
      game['players'] = players;
      final committedEvent = OnlineDisasterEvent(
        turn: turn,
        playerRole: role,
        damage: damage,
        affectedPieces: affectedPieces.length,
        destroyedPieces: destroyedPieces,
      );
      event = committedEvent;
      game[eventKey] = committedEvent.toValue();
      game[countdownKey] = random.nextInt(11) + 5;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return OnlineDisasterResolution(committed: result.committed, event: event);
  }

  static Future<bool> rollDiceForTurn({
    required OnlineRoom room,
    required String uid,
    required int turn,
    required int firstDie,
    required int secondDie,
  }) async {
    if (firstDie < 1 || firstDie > 6 || secondDie < 1 || secondDie > 6) {
      throw ArgumentError('Los dados deben tener valores entre 1 y 6.');
    }
    final role = _roleFor(room, uid);
    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      final currentTurn = game['turn'];
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          currentTurn != turn ||
          game['earthquakeProcessedTurn'] != turn ||
          game['plagueProcessedTurn'] != turn ||
          game['epidemicProcessedTurn'] != turn ||
          game['diceRolledTurn'] == turn ||
          player['uid'] != uid) {
        return Transaction.abort();
      }

      final currentPoints = player['accumulatedPoints'];
      if (currentPoints is! num || currentPoints < 0) {
        return Transaction.abort();
      }
      final total = firstDie + secondDie;
      player['accumulatedPoints'] = currentPoints.toInt() + total;
      players[role] = player;
      game['players'] = players;
      game['diceRolledTurn'] = turn;
      game['lastRoll'] = {
        'turn': turn,
        'rollerRole': role,
        'firstDie': firstDie,
        'secondDie': secondDie,
        'total': total,
      };
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Future<bool> summonPiece({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
    required int row,
    required int column,
    required String type,
    required String id,
    required int cost,
    required int health,
    required int primaryStat,
  }) async {
    if (row < 0 ||
        row > 3 ||
        column < 0 ||
        column > 4 ||
        (row == 3 && column == 2) ||
        !const {
          'warrior',
          'tower',
          'hospital',
          'crop',
          'villager',
        }.contains(type) ||
        id.isEmpty ||
        cost <= 0 ||
        health <= 0 ||
        primaryStat < 0) {
      throw ArgumentError('Los datos de invocación no son válidos.');
    }
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }

    final coordinate = 'r${row}c$column';
    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          game['turn'] != turn ||
          game['diceRolledTurn'] != turn ||
          game['harvestedTurn'] != turn) {
        return Transaction.abort();
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      if (player['uid'] != uid) return Transaction.abort();
      final points = player['accumulatedPoints'];
      if (points is! num || points < cost) return Transaction.abort();

      final warriorIds = player['warriorIds'];
      if (type == 'warrior' &&
          (warriorIds is! List || !warriorIds.contains(id))) {
        return Transaction.abort();
      }

      final rawBoard = player['board'];
      final board =
          rawBoard == null
              ? <Object?, Object?>{}
              : rawBoard is Map
              ? Map<Object?, Object?>.from(rawBoard)
              : null;
      if (board == null || board.containsKey(coordinate)) {
        return Transaction.abort();
      }

      board[coordinate] = {
        'type': type,
        'id': id,
        'health': health,
        'primaryStat': primaryStat,
      };
      player['board'] = board;
      player['accumulatedPoints'] = points.toInt() - cost;
      players[role] = player;
      game['players'] = players;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Future<bool> moveVillagerForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
    required String fromCoordinate,
    required String toCoordinate,
  }) async {
    final coordinatePattern = RegExp(r'^r[0-3]c[0-4]$');
    if (!coordinatePattern.hasMatch(fromCoordinate) ||
        !coordinatePattern.hasMatch(toCoordinate) ||
        fromCoordinate == toCoordinate ||
        toCoordinate == 'r3c2') {
      throw ArgumentError('Las coordenadas de movimiento no son válidas.');
    }
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }

    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          game['turn'] != turn ||
          game['diceRolledTurn'] != turn ||
          game['harvestedTurn'] != turn ||
          game['towerAttacksTurn'] != turn) {
        return Transaction.abort();
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      final rawBoard = player['board'];
      if (player['uid'] != uid || rawBoard is! Map) {
        return Transaction.abort();
      }
      final board = Map<Object?, Object?>.from(rawBoard);
      final rawVillager = board[fromCoordinate];
      if (rawVillager is! Map ||
          Map<Object?, Object?>.from(rawVillager)['type'] != 'villager' ||
          board.containsKey(toCoordinate)) {
        return Transaction.abort();
      }

      board[toCoordinate] = rawVillager;
      board.remove(fromCoordinate);
      player['board'] = board;
      players[role] = player;
      game['players'] = players;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Future<bool> moveWarriorForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
    required String fromCoordinate,
    required String toCoordinate,
  }) async {
    final coordinatePattern = RegExp(r'^r[0-3]c[0-4]$');
    if (!coordinatePattern.hasMatch(fromCoordinate) ||
        !coordinatePattern.hasMatch(toCoordinate) ||
        fromCoordinate == toCoordinate ||
        toCoordinate == 'r3c2') {
      throw ArgumentError('Las coordenadas de movimiento no son válidas.');
    }
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }

    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          game['turn'] != turn ||
          game['diceRolledTurn'] != turn ||
          game['harvestedTurn'] != turn ||
          game['towerAttacksTurn'] != turn) {
        return Transaction.abort();
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      final rawBoard = player['board'];
      if (player['uid'] != uid || rawBoard is! Map) {
        return Transaction.abort();
      }
      final board = Map<Object?, Object?>.from(rawBoard);
      final rawWarrior = board[fromCoordinate];
      if (rawWarrior is! Map ||
          Map<Object?, Object?>.from(rawWarrior)['type'] != 'warrior' ||
          board.containsKey(toCoordinate)) {
        return Transaction.abort();
      }

      board[toCoordinate] = rawWarrior;
      board.remove(fromCoordinate);
      player['board'] = board;
      players[role] = player;
      game['players'] = players;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Future<bool> rebuildMonumentForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
    required int points,
  }) async {
    if (points <= 0) {
      throw ArgumentError.value(points, 'points', 'Debe ser mayor que cero.');
    }
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }

    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          game['turn'] != turn ||
          game['diceRolledTurn'] != turn ||
          game['harvestedTurn'] != turn ||
          game['towerAttacksTurn'] != turn) {
        return Transaction.abort();
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      final accumulatedPoints = player['accumulatedPoints'];
      final monumentHealth = player['monumentHealth'];
      if (player['uid'] != uid ||
          accumulatedPoints is! num ||
          accumulatedPoints < points ||
          monumentHealth is! num ||
          monumentHealth <= 0) {
        return Transaction.abort();
      }

      player['accumulatedPoints'] = accumulatedPoints.toInt() - points;
      player['monumentHealth'] = monumentHealth.toInt() + points;
      players[role] = player;
      game['players'] = players;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Future<bool> upgradeBoardPieceForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
    required String coordinate,
    required int points,
    required String pieceType,
    required String upgrade,
  }) async {
    if (!RegExp(r'^r[0-3]c[0-4]$').hasMatch(coordinate) ||
        points <= 0 ||
        (pieceType != 'crop' &&
            pieceType != 'villager' &&
            pieceType != 'hospital' &&
            pieceType != 'tower' &&
            pieceType != 'warrior') ||
        (pieceType == 'crop' &&
            upgrade != 'production' &&
            upgrade != 'health') ||
        (pieceType == 'villager' &&
            upgrade != 'reconstruction' &&
            upgrade != 'health') ||
        (pieceType == 'hospital' &&
            upgrade != 'healing' &&
            upgrade != 'health') ||
        ((pieceType == 'tower' || pieceType == 'warrior') &&
            upgrade != 'attack' &&
            upgrade != 'health')) {
      throw ArgumentError('Los datos de mejora de la pieza no son válidos.');
    }
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }

    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          game['turn'] != turn ||
          game['diceRolledTurn'] != turn ||
          game['harvestedTurn'] != turn ||
          game['towerAttacksTurn'] != turn) {
        return Transaction.abort();
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      final accumulatedPoints = player['accumulatedPoints'];
      final rawBoard = player['board'];
      if (player['uid'] != uid ||
          accumulatedPoints is! num ||
          accumulatedPoints < points ||
          rawBoard is! Map) {
        return Transaction.abort();
      }
      final board = Map<Object?, Object?>.from(rawBoard);
      final rawPiece = board[coordinate];
      if (rawPiece is! Map) return Transaction.abort();
      final piece = Map<Object?, Object?>.from(rawPiece);
      if (piece['type'] != pieceType) return Transaction.abort();

      final stat = upgrade == 'health' ? 'health' : 'primaryStat';
      final currentValue = piece[stat];
      if (currentValue is! num || currentValue < 0) {
        return Transaction.abort();
      }
      final improvement =
          pieceType == 'warrior' &&
                  upgrade == 'attack' &&
                  player['civilizationId'] == 'azteca'
              ? points * 2
              : points;
      piece[stat] = currentValue.toInt() + improvement;
      board[coordinate] = piece;
      player['board'] = board;
      player['accumulatedPoints'] = accumulatedPoints.toInt() - points;
      players[role] = player;
      game['players'] = players;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Future<bool> harvestCropsForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
  }) async {
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }
    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      final currentTurn = game['turn'];
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          currentTurn != turn ||
          game['diceRolledTurn'] != turn ||
          game['harvestedTurn'] == turn) {
        return Transaction.abort();
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawPlayer = players[role];
      if (rawPlayer is! Map) return Transaction.abort();
      final player = Map<Object?, Object?>.from(rawPlayer);
      if (player['uid'] != uid) return Transaction.abort();
      final points = player['accumulatedPoints'];
      if (points is! num || points < 0) return Transaction.abort();

      final rawBoard = player['board'];
      final board =
          rawBoard == null
              ? <Object?, Object?>{}
              : rawBoard is Map
              ? Map<Object?, Object?>.from(rawBoard)
              : null;
      if (board == null) return Transaction.abort();

      final cropPoints = <String, int>{};
      var totalPoints = 0;
      for (final entry in board.entries) {
        if (entry.key is! String || entry.value is! Map) {
          return Transaction.abort();
        }
        final piece = Map<Object?, Object?>.from(entry.value as Map);
        if (piece['type'] != 'crop') continue;
        final production = piece['primaryStat'];
        if (production is! num || production < 0) {
          return Transaction.abort();
        }
        final cropProduction = production.toInt();
        cropPoints[entry.key as String] = cropProduction;
        totalPoints += cropProduction;
      }

      player['accumulatedPoints'] = points.toInt() + totalPoints;
      final civilizationId = player['civilizationId'];
      final typedBoard = <String, OnlineBoardPiece>{};
      for (final entry in board.entries) {
        if (entry.key is! String) return Transaction.abort();
        try {
          typedBoard[entry.key as String] = OnlineBoardPiece.fromValue(
            entry.value,
          );
        } on FormatException {
          return Transaction.abort();
        }
      }
      late final OnlineHospitalHealingResult healing;
      try {
        healing = OnlineHospitalHealingResult.calculate(
          turn: turn,
          playerRole: role,
          board: typedBoard,
          isMayan: civilizationId == 'maya',
        );
      } on FormatException {
        return Transaction.abort();
      }
      for (final entry in healing.healedUnits.entries) {
        final piece = Map<Object?, Object?>.from(board[entry.key] as Map);
        piece['health'] = (piece['health'] as num).toInt() + entry.value;
        board[entry.key] = piece;
      }
      late final OnlineVillagerRepairResult reconstruction;
      try {
        reconstruction = OnlineVillagerRepairResult.calculate(
          turn: turn,
          playerRole: role,
          board: typedBoard,
        );
      } on FormatException {
        return Transaction.abort();
      }
      for (final entry in reconstruction.repairedBuildings.entries) {
        final piece = Map<Object?, Object?>.from(board[entry.key] as Map);
        piece['health'] = (piece['health'] as num).toInt() + entry.value;
        board[entry.key] = piece;
      }
      final monumentHealth = player['monumentHealth'];
      if (monumentHealth is! num || monumentHealth <= 0) {
        return Transaction.abort();
      }
      player['monumentHealth'] =
          monumentHealth.toInt() + reconstruction.monumentRepair;
      player['board'] = board;
      players[role] = player;
      game['players'] = players;
      game['harvestedTurn'] = turn;
      game['lastHarvest'] = {
        'turn': turn,
        'playerRole': role,
        'totalPoints': totalPoints,
        'cropPoints': cropPoints,
      };
      game['lastHospitalHealing'] = healing.toValue();
      game['lastVillagerRepair'] = reconstruction.toValue();
      final towerCoordinates = OnlineTowerAttackEvent.orderedTowerCoordinates(
        typedBoard,
      );
      game['towerAttackTurn'] = turn;
      game['towerAttackRole'] = role;
      game['towerCoordinates'] = towerCoordinates;
      game['towerAttackIndex'] = 0;
      game['towerAttacksComplete'] = towerCoordinates.isEmpty;
      game['towerAttacksTurn'] = towerCoordinates.isEmpty ? turn : null;
      game.remove('lastTowerAttack');
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Future<OnlineTowerAttackResolution> attackNextTowerForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
  }) async {
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }
    var attacked = false;
    var complete = false;
    OnlineTowerAttackEvent? committedAttack;
    final result = await roomRef(room.id).runTransaction((value) {
      attacked = false;
      complete = false;
      committedAttack = null;
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      final attackTurn = game['towerAttackTurn'];
      final attackRole = game['towerAttackRole'];
      final currentTurn = game['turn'];
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          currentTurn != turn ||
          attackTurn != turn ||
          attackRole != role ||
          game['harvestedTurn'] != turn ||
          game['towerAttacksComplete'] == true) {
        return Transaction.abort();
      }

      final rawPlayers = game['players'];
      final rawTowerCoordinates = game['towerCoordinates'];
      final towerCoordinates = OnlineTowerAttackEvent.parseCoordinateList(
        rawTowerCoordinates,
      );
      final rawIndex = game['towerAttackIndex'];
      if (rawPlayers is! Map ||
          towerCoordinates == null ||
          towerCoordinates.any((coordinate) => coordinate is! String) ||
          rawIndex is! num ||
          rawIndex < 0 ||
          rawIndex != rawIndex.toInt()) {
        return Transaction.abort();
      }
      final players = Map<Object?, Object?>.from(rawPlayers);
      final attackerRaw = players[role];
      final targetRole = role == 'host' ? 'guest' : 'host';
      final targetRaw = players[targetRole];
      if (attackerRaw is! Map || targetRaw is! Map) {
        return Transaction.abort();
      }
      final attacker = Map<Object?, Object?>.from(attackerRaw);
      final target = Map<Object?, Object?>.from(targetRaw);
      final attackerBoard = _copyBoard(attacker['board']);
      final targetBoard = _copyBoard(target['board']);
      if (attackerBoard == null || targetBoard == null) {
        return Transaction.abort();
      }

      final previousAttackValue = game['lastTowerAttack'];
      OnlineTowerAttackEvent? previousAttack;
      if (previousAttackValue != null) {
        try {
          previousAttack = OnlineTowerAttackEvent.fromValue(
            previousAttackValue,
          );
        } on FormatException {
          return Transaction.abort();
        }
        if (previousAttack.turn != turn ||
            previousAttack.playerRole != role ||
            previousAttack.index >= rawIndex.toInt()) {
          return Transaction.abort();
        }
      }

      final coordinates = towerCoordinates.cast<String>();
      var index = rawIndex.toInt();
      OnlineTowerAttackEvent? attack;
      while (index < coordinates.length) {
        final towerCoordinate = coordinates[index];
        final rawTower = attackerBoard[towerCoordinate];
        if (rawTower is! Map) {
          index++;
          continue;
        }
        final tower = Map<Object?, Object?>.from(rawTower);
        if (tower['type'] != 'tower' ||
            tower['primaryStat'] is! num ||
            (tower['primaryStat'] as num) <= 0) {
          index++;
          continue;
        }
        final column = int.parse(towerCoordinate[3]);
        final typedTargetBoard = <String, OnlineBoardPiece>{};
        for (final entry in targetBoard.entries) {
          if (entry.key is! String) return Transaction.abort();
          try {
            typedTargetBoard[entry.key as String] = OnlineBoardPiece.fromValue(
              entry.value,
            );
          } on FormatException {
            return Transaction.abort();
          }
        }
        final targetCoordinate = OnlineTowerAttackEvent.frontTargetCoordinate(
          board: typedTargetBoard,
          column: column,
          attackerRole: role,
        );
        final rawTargetPiece =
            targetCoordinate == null ? null : targetBoard[targetCoordinate];
        final targetPiece =
            rawTargetPiece is Map
                ? Map<Object?, Object?>.from(rawTargetPiece)
                : null;

        final canAttackMonument =
            targetPiece == null && column == 2 && targetBoard.isEmpty;
        if (targetPiece == null && !canAttackMonument) {
          index++;
          continue;
        }

        final damage = (tower['primaryStat'] as num).toInt();
        final targetType =
            canAttackMonument ? 'monument' : targetPiece!['type'] as String?;
        if (targetType == null) return Transaction.abort();
        late final int healthAfter;
        late final bool destroyed;
        if (canAttackMonument) {
          final monumentHealth = target['monumentHealth'];
          if (monumentHealth is! num || monumentHealth < 0) {
            return Transaction.abort();
          }
          healthAfter = monumentHealth.toInt() - damage;
          target['monumentHealth'] = healthAfter < 0 ? 0 : healthAfter;
          destroyed = false;
          if (healthAfter <= 0) {
            game['status'] = 'finished';
            game['winner'] = role;
            game['towerAttacksComplete'] = true;
            game['towerAttacksTurn'] = turn;
            complete = true;
          }
        } else {
          final health = targetPiece!['health'];
          if (health is! num) return Transaction.abort();
          healthAfter = health.toInt() - damage;
          destroyed = healthAfter <= 0;
          if (destroyed) {
            targetBoard.remove(targetCoordinate);
          } else {
            targetPiece['health'] = healthAfter;
            targetBoard[targetCoordinate!] = targetPiece;
          }
        }
        attack = OnlineTowerAttackEvent(
          turn: turn,
          index: index,
          playerRole: role,
          towerCoordinate: towerCoordinate,
          targetRole: targetRole,
          targetCoordinate: targetCoordinate,
          targetType: targetType,
          damage: damage,
          targetHealthAfter: healthAfter,
          targetDestroyed: destroyed,
          destroyedTargetPiece:
              destroyed ? OnlineBoardPiece.fromValue(targetPiece) : null,
        );
        committedAttack = attack;
        index++;
        attacked = true;
        break;
      }

      attacker['board'] = attackerBoard;
      target['board'] = targetBoard;
      players[role] = attacker;
      players[targetRole] = target;
      game['players'] = players;
      game['towerAttackIndex'] = index;
      if (attack != null) {
        game['lastTowerAttack'] = attack.toValue();
      } else {
        game['towerAttacksComplete'] = true;
        game['towerAttacksTurn'] = turn;
      }
      complete = complete || attack == null;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return OnlineTowerAttackResolution(
      committed: result.committed,
      complete: complete,
      attacked: attacked,
      attack: committedAttack,
    );
  }

  static Future<bool> attackWithWarriorForTurn({
    required OnlineRoom room,
    required String uid,
    required String role,
    required int turn,
    required String warriorCoordinate,
  }) async {
    if (!RegExp(r'^r[0-3]c[0-4]$').hasMatch(warriorCoordinate)) {
      throw ArgumentError.value(
        warriorCoordinate,
        'warriorCoordinate',
        'La coordenada del guerrero no es válida.',
      );
    }
    if (_roleFor(room, uid) != role) {
      throw StateError('El jugador no pertenece al lado seleccionado.');
    }

    final result = await roomRef(room.id).runTransaction((value) {
      if (value is! Map) return Transaction.abort();
      final roomData = Map<Object?, Object?>.from(value);
      final rawGame = roomData['game'];
      if (roomData['phase'] != 'gameReady' || rawGame is! Map) {
        return Transaction.abort();
      }
      final game = Map<Object?, Object?>.from(rawGame);
      if (game['status'] != 'ready' ||
          game['currentPlayer'] != role ||
          game['turn'] != turn ||
          game['diceRolledTurn'] != turn ||
          game['harvestedTurn'] != turn ||
          game['towerAttacksTurn'] != turn) {
        return Transaction.abort();
      }

      final rawPlayers = game['players'];
      if (rawPlayers is! Map) return Transaction.abort();
      final players = Map<Object?, Object?>.from(rawPlayers);
      final rawAttacker = players[role];
      final targetRole = role == 'host' ? 'guest' : 'host';
      final rawTarget = players[targetRole];
      if (rawAttacker is! Map || rawTarget is! Map) {
        return Transaction.abort();
      }
      final attacker = Map<Object?, Object?>.from(rawAttacker);
      final target = Map<Object?, Object?>.from(rawTarget);
      if (attacker['uid'] != uid) return Transaction.abort();
      final attackerBoard = _copyBoard(attacker['board']);
      final targetBoard = _copyBoard(target['board']);
      if (attackerBoard == null || targetBoard == null) {
        return Transaction.abort();
      }

      final rawWarrior = attackerBoard[warriorCoordinate];
      if (rawWarrior is! Map) return Transaction.abort();
      final warrior = Map<Object?, Object?>.from(rawWarrior);
      final warriorId = warrior['id'];
      final damage = warrior['primaryStat'];
      final attackedTurn = warrior['warriorAttackedTurn'];
      if (warrior['type'] != 'warrior' ||
          warriorId is! String ||
          damage is! num ||
          damage <= 0 ||
          (attackedTurn != null &&
              (attackedTurn is! num ||
                  attackedTurn < 0 ||
                  attackedTurn == turn))) {
        return Transaction.abort();
      }

      String? targetCoordinate;
      if (targetBoard.isNotEmpty) {
        final typedTargetBoard = <String, OnlineBoardPiece>{};
        for (final entry in targetBoard.entries) {
          if (entry.key is! String) return Transaction.abort();
          try {
            typedTargetBoard[entry.key as String] = OnlineBoardPiece.fromValue(
              entry.value,
            );
          } on FormatException {
            return Transaction.abort();
          }
        }
        targetCoordinate = OnlineTowerAttackEvent.frontTargetCoordinate(
          board: typedTargetBoard,
          column: int.parse(warriorCoordinate[3]),
          attackerRole: role,
        );
        if (targetCoordinate == null) return Transaction.abort();
      }

      final damageValue = damage.toInt();
      if (targetCoordinate == null) {
        final monumentHealth = target['monumentHealth'];
        if (monumentHealth is! num || monumentHealth <= 0) {
          return Transaction.abort();
        }
        final healthAfter = monumentHealth.toInt() - damageValue;
        target['monumentHealth'] = healthAfter > 0 ? healthAfter : 0;
        if (healthAfter <= 0) {
          game['status'] = 'finished';
          game['winner'] = role;
        }
      } else {
        final rawTargetPiece = targetBoard[targetCoordinate];
        if (rawTargetPiece is! Map) return Transaction.abort();
        final targetPiece = Map<Object?, Object?>.from(rawTargetPiece);
        final targetHealth = targetPiece['health'];
        if (targetHealth is! num || targetHealth <= 0) {
          return Transaction.abort();
        }
        final healthAfter = targetHealth.toInt() - damageValue;
        if (healthAfter <= 0) {
          targetBoard.remove(targetCoordinate);
        } else {
          targetPiece['health'] = healthAfter;
          targetBoard[targetCoordinate] = targetPiece;
        }
      }

      warrior['warriorAttackedTurn'] = turn;
      attackerBoard[warriorCoordinate] = warrior;
      attacker['board'] = attackerBoard;
      target['board'] = targetBoard;
      players[role] = attacker;
      players[targetRole] = target;
      game['players'] = players;
      roomData['game'] = game;
      return Transaction.success(roomData);
    });

    return result.committed;
  }

  static Map<Object?, Object?>? _copyBoard(Object? value) {
    if (value == null) return <Object?, Object?>{};
    if (value is! Map) return null;
    return Map<Object?, Object?>.from(value);
  }

  static Future<void> leaveRoom({
    required OnlineRoom room,
    required String uid,
  }) async {
    final roomRef = _roomsRef.child(room.id);
    if (room.hostUid == uid) {
      await roomRef.remove();
      return;
    }

    await roomRef.runTransaction((value) {
      if (value is! Map) return Transaction.abort();

      final currentRoom = Map<Object?, Object?>.from(value);
      if (currentRoom['guestUid'] != uid) return Transaction.abort();
      currentRoom.remove('guestUid');
      currentRoom['status'] = 'waiting';
      currentRoom['phase'] = 'waiting';
      currentRoom.remove('players');
      currentRoom.remove('game');
      return Transaction.success(currentRoom);
    });
  }

  static String _roleFor(OnlineRoom room, String uid) {
    if (uid == room.hostUid) return 'host';
    if (uid == room.guestUid) return 'guest';
    throw StateError('El jugador no pertenece a esta sala.');
  }
}
