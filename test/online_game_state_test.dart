import 'package:flutter_test/flutter_test.dart';
import 'package:mitic/models/online_game_state.dart';

void main() {
  group('OnlineGamePlayer.availableVillagerMoveCoordinates', () {
    const piece = OnlineBoardPiece(
      type: 'villager',
      id: 'villager-1',
      health: 10,
      primaryStat: 2,
    );

    test('returns empty board squares and excludes the monument square', () {
      final player = OnlineGamePlayer(
        uid: 'host-uid',
        civilizationId: 'azteca',
        monumentHealth: 100,
        accumulatedPoints: 0,
        warriorIds: const [],
        board: const {'r0c0': piece, 'r1c1': piece},
      );

      final coordinates = player.availableVillagerMoveCoordinates();

      expect(coordinates, hasLength(17));
      expect(coordinates, isNot(contains('r0c0')));
      expect(coordinates, isNot(contains('r1c1')));
      expect(coordinates, isNot(contains('r3c2')));
      expect(coordinates, contains('r3c1'));
    });

    test(
      'returns no destinations when all non-monument squares are occupied',
      () {
        final board = {
          for (var row = 0; row < 4; row++)
            for (var column = 0; column < 5; column++)
              if (!(row == 3 && column == 2)) 'r${row}c$column': piece,
        };
        final player = OnlineGamePlayer(
          uid: 'host-uid',
          civilizationId: 'azteca',
          monumentHealth: 100,
          accumulatedPoints: 0,
          warriorIds: const [],
          board: board,
        );

        expect(player.availableVillagerMoveCoordinates(), isEmpty);
      },
    );
  });

  group('OnlineGamePlayer.availableWarriorMoveCoordinates', () {
    const piece = OnlineBoardPiece(
      type: 'warrior',
      id: 'warrior-1',
      health: 30,
      primaryStat: 10,
    );

    test('returns empty board squares and excludes the monument square', () {
      final player = OnlineGamePlayer(
        uid: 'host-uid',
        civilizationId: 'azteca',
        monumentHealth: 100,
        accumulatedPoints: 0,
        warriorIds: const [],
        board: const {'r0c0': piece, 'r1c1': piece},
      );

      final coordinates = player.availableWarriorMoveCoordinates();

      expect(coordinates, hasLength(17));
      expect(coordinates, isNot(contains('r0c0')));
      expect(coordinates, isNot(contains('r1c1')));
      expect(coordinates, isNot(contains('r3c2')));
      expect(coordinates, contains('r3c1'));
    });

    test(
      'returns no destinations when all non-monument squares are occupied',
      () {
        final board = {
          for (var row = 0; row < 4; row++)
            for (var column = 0; column < 5; column++)
              if (!(row == 3 && column == 2)) 'r${row}c$column': piece,
        };
        final player = OnlineGamePlayer(
          uid: 'host-uid',
          civilizationId: 'azteca',
          monumentHealth: 100,
          accumulatedPoints: 0,
          warriorIds: const [],
          board: board,
        );

        expect(player.availableWarriorMoveCoordinates(), isEmpty);
      },
    );
  });

  group('OnlineGameState.fromRoomSnapshot', () {
    final players = {
      'host': {
        'uid': 'host-uid',
        'civilizationId': 'azteca',
        'monumentHealth': 100,
        'accumulatedPoints': 0,
        'warriorIds': ['azteca_001'],
      },
      'guest': {
        'uid': 'guest-uid',
        'civilizationId': 'maya',
        'monumentHealth': 120,
        'accumulatedPoints': 0,
        'warriorIds': ['maya_001'],
      },
    };
    final room = {
      'phase': 'gameReady',
      'game': {
        'status': 'ready',
        'currentPlayer': 'host',
        'turn': 0,
        'players': players,
      },
    };

    test('parses initial host turn and both monuments', () {
      final state = OnlineGameState.fromRoomSnapshot(room);

      expect(state.currentPlayer, 'host');
      expect(state.turn, 0);
      expect(state.host.uid, 'host-uid');
      expect(state.host.monumentHealth, 100);
      expect(state.host.accumulatedPoints, 0);
      expect(state.guest.civilizationId, 'maya');
    });

    test('parses board pieces by coordinate', () {
      final roomWithPiece = {
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 0,
          'players': {
            'host': {
              ...players['host']!,
              'board': {
                'r1c2': {
                  'type': 'warrior',
                  'id': 'azteca_001',
                  'health': 34,
                  'primaryStat': 17,
                },
              },
            },
            'guest': players['guest'],
          },
        },
      };

      final state = OnlineGameState.fromRoomSnapshot(roomWithPiece);

      expect(state.host.board['r1c2']?.type, 'warrior');
      expect(state.host.board['r1c2']?.health, 34);
    });

    test('warrior can hit the first enemy piece in its column', () {
      const warrior = {
        'type': 'warrior',
        'id': 'azteca_001',
        'health': 34,
        'primaryStat': 17,
      };
      const villager = {
        'type': 'villager',
        'id': 'maya_ald_001',
        'health': 20,
        'primaryStat': 2,
      };
      final state = OnlineGameState.fromRoomSnapshot({
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 0,
          'players': {
            'host': {
              ...players['host']!,
              'board': {'r3c1': warrior},
            },
            'guest': {
              ...players['guest']!,
              'board': {'r2c1': villager, 'r0c1': villager},
            },
          },
        },
      });

      expect(state.canWarriorAttack('host', 'r3c1'), isTrue);
      expect(
        OnlineTowerAttackEvent.frontTargetCoordinate(
          board: state.guest.board,
          column: 1,
          attackerRole: 'host',
        ),
        'r0c1',
      );
    });

    test(
      'warrior can hit the monument only when the entire enemy board is empty',
      () {
        const warrior = {
          'type': 'warrior',
          'id': 'azteca_001',
          'health': 34,
          'primaryStat': 17,
        };
        const villager = {
          'type': 'villager',
          'id': 'maya_ald_001',
          'health': 20,
          'primaryStat': 2,
        };
        final stateWithEnemyPiece = OnlineGameState.fromRoomSnapshot({
          'phase': 'gameReady',
          'game': {
            'status': 'ready',
            'currentPlayer': 'host',
            'turn': 0,
            'players': {
              'host': {
                ...players['host']!,
                'board': {'r2c4': warrior},
              },
              'guest': {
                ...players['guest']!,
                'board': {'r2c0': villager},
              },
            },
          },
        });
        final stateWithEmptyEnemyBoard = OnlineGameState.fromRoomSnapshot({
          'phase': 'gameReady',
          'game': {
            'status': 'ready',
            'currentPlayer': 'host',
            'turn': 0,
            'players': {
              'host': {
                ...players['host']!,
                'board': {'r2c4': warrior},
              },
              'guest': players['guest'],
            },
          },
        });

        expect(stateWithEnemyPiece.canWarriorAttack('host', 'r2c4'), isFalse);
        expect(
          stateWithEmptyEnemyBoard.canWarriorAttack('host', 'r2c4'),
          isTrue,
        );
      },
    );

    test('tracks attacks independently for warriors with the same id', () {
      const attackedWarrior = {
        'type': 'warrior',
        'id': 'azteca_001',
        'health': 34,
        'primaryStat': 17,
        'warriorAttackedTurn': 0,
      };
      const readyWarrior = {
        'type': 'warrior',
        'id': 'azteca_001',
        'health': 34,
        'primaryStat': 17,
      };
      final state = OnlineGameState.fromRoomSnapshot({
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 0,
          'players': {
            'host': {
              ...players['host']!,
              'board': {'r2c4': attackedWarrior, 'r1c1': readyWarrior},
            },
            'guest': players['guest'],
          },
        },
      });

      expect(state.hasWarriorAttacked('host', 'r2c4'), isTrue);
      expect(state.hasWarriorAttacked('host', 'r1c1'), isFalse);
      expect(state.canWarriorAttack('host', 'r2c4'), isFalse);
      expect(state.canWarriorAttack('host', 'r1c1'), isTrue);

      final movedBoard = {
        'r3c4': state.host.board['r2c4']!.toValue(),
        'r1c1': state.host.board['r1c1']!.toValue(),
      };
      final movedState = OnlineGameState.fromRoomSnapshot({
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 0,
          'players': {
            'host': {...players['host']!, 'board': movedBoard},
            'guest': players['guest'],
          },
        },
      });

      expect(movedState.hasWarriorAttacked('host', 'r3c4'), isTrue);
      expect(movedState.canWarriorAttack('host', 'r3c4'), isFalse);
      expect(movedState.canWarriorAttack('host', 'r1c1'), isTrue);
    });

    test('rejects a turn assigned to an unknown player', () {
      final malformed = {
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'spectator',
          'turn': 0,
          'players': players,
        },
      };

      expect(
        () => OnlineGameState.fromRoomSnapshot(malformed),
        throwsFormatException,
      );
    });

    test('parses the dice result for the current turn', () {
      final rolledRoom = {
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 0,
          'diceRolledTurn': 0,
          'lastRoll': {
            'turn': 0,
            'rollerRole': 'host',
            'firstDie': 4,
            'secondDie': 2,
            'total': 6,
          },
          'players': players,
        },
      };

      final state = OnlineGameState.fromRoomSnapshot(rolledRoom);

      expect(state.diceRolledTurn, 0);
      expect(state.diceRolledBy, 'host');
      expect(state.firstDie, 4);
      expect(state.secondDie, 2);
      expect(state.lastRollTotal, 6);
    });

    test('parses disaster countdowns and previous turn events', () {
      final roomWithEarthquake = {
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 3,
          'earthquakeCountdown': 7,
          'earthquakeProcessedTurn': 3,
          'plagueCountdown': 4,
          'plagueProcessedTurn': 3,
          'lastPlague': {
            'turn': 2,
            'playerRole': 'guest',
            'damage': 8,
            'affectedPieces': 3,
            'destroyedPieces': 1,
          },
          'epidemicCountdown': 11,
          'epidemicProcessedTurn': 3,
          'lastEpidemic': {
            'turn': 1,
            'playerRole': 'host',
            'damage': 12,
            'affectedPieces': 2,
            'destroyedPieces': 0,
          },
          'lastEarthquake': {
            'turn': 2,
            'playerRole': 'guest',
            'damage': 15,
            'affectedStructures': 2,
            'monumentDestroyed': false,
          },
          'players': players,
        },
      };

      final state = OnlineGameState.fromRoomSnapshot(roomWithEarthquake);

      expect(state.earthquakeCountdown, 7);
      expect(state.earthquakeProcessedTurn, 3);
      expect(state.lastEarthquake?.turn, 2);
      expect(state.lastEarthquake?.damage, 15);
      expect(state.lastEarthquake?.affectedStructures, 2);
      expect(state.lastEarthquake?.monumentDestroyed, isFalse);
      expect(state.plagueCountdown, 4);
      expect(state.plagueProcessedTurn, 3);
      expect(state.lastPlague?.turn, 2);
      expect(state.lastPlague?.affectedPieces, 3);
      expect(state.lastPlague?.destroyedPieces, 1);
      expect(state.epidemicCountdown, 11);
      expect(state.epidemicProcessedTurn, 3);
      expect(state.lastEpidemic?.turn, 1);
      expect(state.lastEpidemic?.damage, 12);
      expect(state.lastEpidemic?.destroyedPieces, 0);
    });

    test('rejects an earthquake result from a future turn', () {
      final malformed = {
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 1,
          'lastEarthquake': {
            'turn': 2,
            'playerRole': 'guest',
            'damage': 15,
            'affectedStructures': 2,
            'monumentDestroyed': false,
          },
          'players': players,
        },
      };

      expect(
        () => OnlineGameState.fromRoomSnapshot(malformed),
        throwsFormatException,
      );
    });

    test('parses the current turn crop harvest', () {
      final harvestedRoom = {
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 0,
          'diceRolledTurn': 0,
          'harvestedTurn': 0,
          'lastHarvest': {
            'turn': 0,
            'playerRole': 'host',
            'totalPoints': 5,
            'cropPoints': {'r1c2': 2, 'r2c3': 3},
          },
          'players': players,
        },
      };

      final state = OnlineGameState.fromRoomSnapshot(harvestedRoom);

      expect(state.harvestedTurn, 0);
      expect(state.lastHarvest?.totalPoints, 5);
      expect(state.lastHarvest?.cropPoints, {'r1c2': 2, 'r2c3': 3});
    });

    test('rejects harvest totals that do not match crop production', () {
      final malformedHarvest = {
        'phase': 'gameReady',
        'game': {
          'status': 'ready',
          'currentPlayer': 'host',
          'turn': 0,
          'harvestedTurn': 0,
          'lastHarvest': {
            'turn': 0,
            'playerRole': 'host',
            'totalPoints': 5,
            'cropPoints': {'r1c2': 2},
          },
          'players': players,
        },
      };

      expect(
        () => OnlineGameState.fromRoomSnapshot(malformedHarvest),
        throwsFormatException,
      );
    });

    test('parses ordered tower attacks and a finished monument attack', () {
      final finishedRoom = {
        'phase': 'gameReady',
        'game': {
          'status': 'finished',
          'winner': 'host',
          'currentPlayer': 'host',
          'turn': 0,
          'towerAttackTurn': 0,
          'towerAttackRole': 'host',
          'towerCoordinates': ['r0c0', 'r0c2'],
          'towerAttackIndex': 2,
          'towerAttacksComplete': true,
          'towerAttacksTurn': 0,
          'lastTowerAttack': {
            'turn': 0,
            'index': 1,
            'playerRole': 'host',
            'towerCoordinate': 'r0c2',
            'targetRole': 'guest',
            'targetType': 'monument',
            'damage': 120,
            'targetHealthAfter': -10,
            'targetDestroyed': false,
          },
          'players': {
            'host': players['host'],
            'guest': {...players['guest']!, 'monumentHealth': 0},
          },
        },
      };

      final state = OnlineGameState.fromRoomSnapshot(finishedRoom);

      expect(state.towerCoordinates, ['r0c0', 'r0c2']);
      expect(state.towerAttackIndex, 2);
      expect(state.towerAttacksComplete, isTrue);
      expect(state.lastTowerAttack?.targetType, 'monument');
      expect(state.guest.monumentHealth, 0);
      expect(state.winner, 'host');
    });
  });
}
