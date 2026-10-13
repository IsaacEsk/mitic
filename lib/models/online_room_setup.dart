class OnlinePlayerSetup {
  final String? civilizationId;
  final List<String> allyIds;
  final int? monumentMaxHealth;

  const OnlinePlayerSetup({
    required this.civilizationId,
    required this.allyIds,
    this.monumentMaxHealth,
  });

  bool get hasCivilization => civilizationId != null;

  bool get hasAllies => allyIds.length == 3;

  factory OnlinePlayerSetup.fromValue(Object? value) {
    if (value == null) {
      return const OnlinePlayerSetup(civilizationId: null, allyIds: []);
    }
    if (value is! Map) {
      throw const FormatException(
        'Los datos del jugador tienen un formato inválido.',
      );
    }

    final data = Map<Object?, Object?>.from(value);
    final civilizationId = data['civilizationId'];
    final rawAllyIds = data['allyIds'];
    final rawMonumentMaxHealth = data['monumentMaxHealth'];
    if (civilizationId != null && civilizationId is! String) {
      throw const FormatException('La civilización seleccionada no es válida.');
    }
    if (rawMonumentMaxHealth != null && rawMonumentMaxHealth is! num) {
      throw const FormatException('La vida del monumento no es válida.');
    }

    final allyIds = <String>[];
    if (rawAllyIds != null) {
      if (rawAllyIds is! List || rawAllyIds.any((id) => id is! String)) {
        throw const FormatException('La selección de aliados no es válida.');
      }
      allyIds.addAll(rawAllyIds.cast<String>());
    }

    return OnlinePlayerSetup(
      civilizationId: civilizationId as String?,
      allyIds: List.unmodifiable(allyIds),
      monumentMaxHealth: (rawMonumentMaxHealth as num?)?.toInt(),
    );
  }
}

class OnlineRoomSetup {
  final String? guestUid;
  final String? status;
  final String? phase;
  final OnlinePlayerSetup host;
  final OnlinePlayerSetup guest;

  const OnlineRoomSetup({
    required this.guestUid,
    required this.status,
    required this.phase,
    required this.host,
    required this.guest,
  });

  bool get bothCivilizationsSelected =>
      host.hasCivilization && guest.hasCivilization;

  bool get bothPlayersReady => host.hasAllies && guest.hasAllies;

  OnlinePlayerSetup playerForRole(String role) {
    switch (role) {
      case 'host':
        return host;
      case 'guest':
        return guest;
      default:
        throw ArgumentError.value(role, 'role', 'Expected host or guest.');
    }
  }

  factory OnlineRoomSetup.fromSnapshot(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'Los datos de la sala tienen un formato inválido.',
      );
    }

    final room = Map<Object?, Object?>.from(value);
    final playersValue = room['players'];
    if (playersValue != null && playersValue is! Map) {
      throw const FormatException(
        'Los jugadores de la sala tienen un formato inválido.',
      );
    }
    final players =
        playersValue == null
            ? <Object?, Object?>{}
            : Map<Object?, Object?>.from(playersValue as Map);
    final phase = room['phase'];
    if (phase != null && phase is! String) {
      throw const FormatException('La fase de la sala no es válida.');
    }
    final status = room['status'];
    if (status != null && status is! String) {
      throw const FormatException('El estado de la sala no es válido.');
    }
    final guestUid = room['guestUid'];
    if (guestUid != null && guestUid is! String) {
      throw const FormatException('El jugador invitado no es válido.');
    }

    return OnlineRoomSetup(
      guestUid: guestUid as String?,
      status: status as String?,
      phase: phase as String?,
      host: OnlinePlayerSetup.fromValue(players['host']),
      guest: OnlinePlayerSetup.fromValue(players['guest']),
    );
  }
}
