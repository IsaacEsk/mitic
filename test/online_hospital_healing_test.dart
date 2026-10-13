import 'package:flutter_test/flutter_test.dart';
import 'package:mitic/models/online_game_state.dart';

void main() {
  group('OnlineHospitalHealingResult.calculate', () {
    test('heals warriors and villagers sharing a hospital row or column', () {
      final result = OnlineHospitalHealingResult.calculate(
        turn: 2,
        playerRole: 'host',
        isMayan: false,
        board: {
          'r1c1': _piece('hospital', primaryStat: 3),
          'r1c4': _piece('warrior'),
          'r3c1': _piece('villager'),
          'r2c2': _piece('warrior'),
          'r1c3': _piece('crop'),
        },
      );

      expect(result.hospitalCoordinates, ['r1c1']);
      expect(result.healedUnits, {'r1c4': 3, 'r3c1': 3});
      final decoded = OnlineHospitalHealingResult.fromValue(result.toValue());
      expect(decoded.turn, result.turn);
      expect(decoded.playerRole, result.playerRole);
      expect(decoded.hospitalCoordinates, result.hospitalCoordinates);
      expect(decoded.healedUnits, result.healedUnits);
    });

    test('doubles Maya healing and adds healing from every hospital', () {
      final result = OnlineHospitalHealingResult.calculate(
        turn: 4,
        playerRole: 'guest',
        isMayan: true,
        board: {
          'r0c0': _piece('hospital', primaryStat: 2),
          'r0c4': _piece('hospital', primaryStat: 3),
          'r0c2': _piece('warrior'),
          'r2c0': _piece('villager'),
          'r3c3': _piece('warrior'),
        },
      );

      expect(result.healedUnits, {'r0c2': 10, 'r2c0': 4});
    });

    test('rejects invalid board coordinates', () {
      expect(
        () => OnlineHospitalHealingResult.calculate(
          turn: 0,
          playerRole: 'host',
          isMayan: false,
          board: {'A1': _piece('hospital', primaryStat: 1)},
        ),
        throwsFormatException,
      );
    });

    test('rejects malformed coordinates in synchronized results', () {
      expect(
        () => OnlineHospitalHealingResult.fromValue({
          'turn': 1,
          'playerRole': 'host',
          'hospitalCoordinates': ['A1'],
          'healedUnits': {},
        }),
        throwsFormatException,
      );
    });

    test('accepts empty collections omitted by Realtime Database', () {
      final result = OnlineHospitalHealingResult.fromValue({
        'turn': 1,
        'playerRole': 'guest',
        'hospitalCoordinates': null,
        'healedUnits': null,
      });

      expect(result.hospitalCoordinates, isEmpty);
      expect(result.healedUnits, isEmpty);
    });

    test('accepts indexed maps returned for synchronized hospital lists', () {
      final result = OnlineHospitalHealingResult.fromValue({
        'turn': 1,
        'playerRole': 'guest',
        'hospitalCoordinates': {'0': 'r0c1', '1': 'r2c3'},
        'healedUnits': {'r0c2': 4},
      });

      expect(result.hospitalCoordinates, ['r0c1', 'r2c3']);
      expect(result.healedUnits, {'r0c2': 4});
    });
  });

  group('OnlineVillagerRepairResult.calculate', () {
    test(
      'repairs towers, hospitals, crops, and monument in matching rows/columns',
      () {
        final result = OnlineVillagerRepairResult.calculate(
          turn: 3,
          playerRole: 'host',
          board: {
            'r3c0': _piece('villager', primaryStat: 4),
            'r2c1': _piece('villager', primaryStat: 2),
            'r1c4': _piece('villager', primaryStat: 3),
            'r0c2': _piece('villager', primaryStat: 1),
            'r3c1': _piece('tower'),
            'r1c2': _piece('hospital'),
            'r2c3': _piece('crop'),
            'r3c4': _piece('crop'),
          },
        );

        expect(result.villagerCoordinates, ['r3c0', 'r2c1', 'r1c4', 'r0c2']);
        expect(result.repairedBuildings, {
          'r3c1': 6,
          'r1c2': 4,
          'r2c3': 2,
          'r3c4': 7,
        });
        expect(result.monumentRepair, 5);
        final decoded = OnlineVillagerRepairResult.fromValue(result.toValue());
        expect(decoded.villagerCoordinates, result.villagerCoordinates);
        expect(decoded.repairedBuildings, result.repairedBuildings);
        expect(decoded.monumentRepair, result.monumentRepair);
      },
    );

    test('accepts omitted empty collections from Realtime Database', () {
      final result = OnlineVillagerRepairResult.fromValue({
        'turn': 1,
        'playerRole': 'guest',
      });

      expect(result.villagerCoordinates, isEmpty);
      expect(result.repairedBuildings, isEmpty);
      expect(result.monumentRepair, 0);
    });
  });

  group('OnlineTowerAttackEvent', () {
    test('orders towers by A, B, D, E, then C and by row within columns', () {
      final board = {
        'r2c2': _piece('tower', primaryStat: 3),
        'r3c4': _piece('tower', primaryStat: 3),
        'r1c0': _piece('tower', primaryStat: 3),
        'r0c3': _piece('tower', primaryStat: 3),
        'r0c1': _piece('tower', primaryStat: 3),
        'r0c2': _piece('tower', primaryStat: 3),
        'r0c0': _piece('tower', primaryStat: 3),
        'r1c2': _piece('tower', primaryStat: 3),
        'r0c4': _piece('tower', primaryStat: 3),
        'r1c3': _piece('tower', primaryStat: 3),
      };

      expect(OnlineTowerAttackEvent.orderedTowerCoordinates(board), [
        'r0c0',
        'r1c0',
        'r0c1',
        'r0c3',
        'r1c3',
        'r0c4',
        'r3c4',
        'r0c2',
        'r1c2',
        'r2c2',
      ]);
    });

    test('serializes and validates an attack against a destroyed piece', () {
      final attack = OnlineTowerAttackEvent(
        turn: 2,
        index: 1,
        playerRole: 'host',
        towerCoordinate: 'r0c1',
        targetRole: 'guest',
        targetCoordinate: 'r3c1',
        targetType: 'crop',
        damage: 12,
        targetHealthAfter: -2,
        targetDestroyed: true,
        destroyedTargetPiece: _piece('crop'),
      );

      final decoded = OnlineTowerAttackEvent.fromValue(attack.toValue());

      expect(decoded.turn, attack.turn);
      expect(decoded.index, attack.index);
      expect(decoded.towerCoordinate, attack.towerCoordinate);
      expect(decoded.targetCoordinate, attack.targetCoordinate);
      expect(decoded.targetHealthAfter, -2);
      expect(decoded.targetDestroyed, isTrue);
      expect(decoded.destroyedTargetPiece?.type, 'crop');
      expect(decoded.destroyedTargetPiece?.health, 10);
    });

    test('selects the nearest front target for either online side', () {
      final board = {
        'r0c2': _piece('warrior'),
        'r2c2': _piece('hospital'),
        'r1c2': _piece('tower'),
      };

      expect(
        OnlineTowerAttackEvent.frontTargetCoordinate(
          board: board,
          column: 2,
          attackerRole: 'host',
        ),
        'r0c2',
      );
      expect(
        OnlineTowerAttackEvent.frontTargetCoordinate(
          board: board,
          column: 2,
          attackerRole: 'guest',
        ),
        'r0c2',
      );
    });

    test('keeps attacking the front piece until it is destroyed', () {
      final board = <String, OnlineBoardPiece>{
        'r0c2': OnlineBoardPiece(
          type: 'tower',
          id: 'front',
          health: 7,
          primaryStat: 0,
        ),
        'r1c2': OnlineBoardPiece(
          type: 'tower',
          id: 'next',
          health: 10,
          primaryStat: 0,
        ),
      };

      String? attack() => OnlineTowerAttackEvent.frontTargetCoordinate(
        board: board,
        column: 2,
        attackerRole: 'host',
      );

      expect(attack(), 'r0c2');
      board['r0c2'] = OnlineBoardPiece(
        type: 'tower',
        id: 'front',
        health: 4,
        primaryStat: 0,
      );
      expect(attack(), 'r0c2');
      board.remove('r0c2');
      expect(attack(), 'r1c2');
    });

    test('returns no front target for an empty firing column', () {
      expect(
        OnlineTowerAttackEvent.frontTargetCoordinate(
          board: {'r1c1': _piece('warrior')},
          column: 2,
          attackerRole: 'host',
        ),
        isNull,
      );
    });
  });
}

OnlineBoardPiece _piece(String type, {int primaryStat = 0}) => OnlineBoardPiece(
  type: type,
  id: 'test_$type',
  health: 10,
  primaryStat: primaryStat,
);
