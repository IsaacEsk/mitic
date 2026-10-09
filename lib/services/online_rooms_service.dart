import 'package:firebase_database/firebase_database.dart';
import 'package:mitic/models/online_room.dart';
import 'package:mitic/services/realtime_database_service.dart';

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
      room['status'] = 'ready';
      return Transaction.success(room);
    });

    return result.committed;
  }

  static DatabaseReference roomRef(String roomId) => _roomsRef.child(roomId);

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
      currentRoom['status'] = 'waiting';
      return Transaction.success(currentRoom);
    });
  }
}
