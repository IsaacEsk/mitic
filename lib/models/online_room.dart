class OnlineRoom {
  final String id;
  final String hostUid;
  final String? guestUid;
  final String status;
  final int createdAt;

  const OnlineRoom({
    required this.id,
    required this.hostUid,
    required this.guestUid,
    required this.status,
    required this.createdAt,
  });

  factory OnlineRoom.fromSnapshot(String id, Object? value) {
    if (value is! Map) {
      throw FormatException('La sala $id tiene un formato inválido.');
    }

    final data = Map<Object?, Object?>.from(value);
    final hostUid = data['hostUid'];
    final guestUid = data['guestUid'];
    final status = data['status'];
    final createdAt = data['createdAt'];

    if (hostUid is! String || status is! String || createdAt is! num) {
      throw FormatException('La sala $id tiene datos incompletos.');
    }

    return OnlineRoom(
      id: id,
      hostUid: hostUid,
      guestUid: guestUid is String ? guestUid : null,
      status: status,
      createdAt: createdAt.toInt(),
    );
  }
}
