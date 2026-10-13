import 'package:flutter_test/flutter_test.dart';
import 'package:mitic/models/online_room_setup.dart';

void main() {
  group('OnlineRoomSetup.fromSnapshot', () {
    test('reads civilization and ally selections for both players', () {
      final setup = OnlineRoomSetup.fromSnapshot({
        'phase': 'gameReady',
        'players': {
          'host': {
            'civilizationId': 'civ-host',
            'monumentMaxHealth': 100,
            'allyIds': ['host-1', 'host-2', 'host-3'],
          },
          'guest': {
            'civilizationId': 'civ-guest',
            'monumentMaxHealth': 120,
            'allyIds': ['guest-1', 'guest-2', 'guest-3'],
          },
        },
      });

      expect(setup.phase, 'gameReady');
      expect(setup.bothCivilizationsSelected, isTrue);
      expect(setup.bothPlayersReady, isTrue);
      expect(setup.host.civilizationId, 'civ-host');
      expect(setup.guest.allyIds, ['guest-1', 'guest-2', 'guest-3']);
      expect(setup.host.monumentMaxHealth, 100);
      expect(setup.guest.monumentMaxHealth, 120);
    });

    test('reports partially completed selection accurately', () {
      final setup = OnlineRoomSetup.fromSnapshot({
        'players': {
          'host': {'civilizationId': 'civ-host'},
        },
      });

      expect(setup.bothCivilizationsSelected, isFalse);
      expect(setup.bothPlayersReady, isFalse);
    });

    test('rejects malformed ally data', () {
      expect(
        () => OnlineRoomSetup.fromSnapshot({
          'players': {
            'host': {'allyIds': 'not-a-list'},
          },
        }),
        throwsFormatException,
      );
    });
  });
}
