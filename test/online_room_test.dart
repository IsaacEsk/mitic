import 'package:flutter_test/flutter_test.dart';
import 'package:mitic/models/online_room.dart';

void main() {
  group('OnlineRoom.fromSnapshot', () {
    test('parses an open room without a guest', () {
      final room = OnlineRoom.fromSnapshot('room-1', {
        'hostUid': 'host-uid',
        'status': 'waiting',
        'createdAt': 123,
      });

      expect(room.id, 'room-1');
      expect(room.hostUid, 'host-uid');
      expect(room.guestUid, isNull);
      expect(room.status, 'waiting');
      expect(room.createdAt, 123);
    });

    test('parses a room after a guest has joined', () {
      final room = OnlineRoom.fromSnapshot('room-2', {
        'hostUid': 'host-uid',
        'guestUid': 'guest-uid',
        'status': 'ready',
        'createdAt': 456,
      });

      expect(room.guestUid, 'guest-uid');
      expect(room.status, 'ready');
    });

    test('rejects incomplete room data', () {
      expect(
        () => OnlineRoom.fromSnapshot('room-3', {'hostUid': 'host-uid'}),
        throwsFormatException,
      );
    });
  });
}
