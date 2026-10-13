class OnlineGamePlayer {
  final String uid;
  final String civilizationId;
  final int monumentHealth;
  final int accumulatedPoints;
  final List<String> warriorIds;
  final Map<String, OnlineBoardPiece> board;

  const OnlineGamePlayer({
    required this.uid,
    required this.civilizationId,
    required this.monumentHealth,
    required this.accumulatedPoints,
    required this.warriorIds,
    required this.board,
  });

  List<String> availableVillagerMoveCoordinates() {
    return _availableMoveCoordinates();
  }

  List<String> availableWarriorMoveCoordinates() {
    return _availableMoveCoordinates();
  }

  List<String> _availableMoveCoordinates() {
    final coordinates = <String>[];
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 5; column++) {
        if ((row == 3 && column == 2) || board.containsKey('r${row}c$column')) {
          continue;
        }
        coordinates.add('r${row}c$column');
      }
    }
    return List.unmodifiable(coordinates);
  }

  factory OnlineGamePlayer.fromValue(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'Los datos del jugador online no son válidos.',
      );
    }
    final data = Map<Object?, Object?>.from(value);
    final uid = data['uid'];
    final civilizationId = data['civilizationId'];
    final monumentHealth = data['monumentHealth'];
    final accumulatedPoints = data['accumulatedPoints'];
    final rawWarriorIds = data['warriorIds'];
    final rawBoard = data['board'];
    if (uid is! String ||
        civilizationId is! String ||
        monumentHealth is! num ||
        monumentHealth < 0 ||
        accumulatedPoints is! num ||
        accumulatedPoints < 0 ||
        rawWarriorIds is! List ||
        rawWarriorIds.any((id) => id is! String) ||
        (rawBoard != null && rawBoard is! Map)) {
      throw const FormatException(
        'Faltan datos del jugador, su monumento o sus puntos.',
      );
    }
    final board = <String, OnlineBoardPiece>{};
    if (rawBoard is Map) {
      for (final entry in rawBoard.entries) {
        final coordinate = entry.key;
        if (coordinate is! String) {
          throw const FormatException(
            'Las coordenadas de una pieza no son válidas.',
          );
        }
        board[coordinate] = OnlineBoardPiece.fromValue(entry.value);
      }
    }
    return OnlineGamePlayer(
      uid: uid,
      civilizationId: civilizationId,
      monumentHealth: monumentHealth.toInt(),
      accumulatedPoints: accumulatedPoints.toInt(),
      warriorIds: List.unmodifiable(rawWarriorIds.cast<String>()),
      board: Map.unmodifiable(board),
    );
  }
}

class OnlineBoardPiece {
  final String type;
  final String id;
  final int health;
  final int primaryStat;
  final int? warriorAttackedTurn;

  const OnlineBoardPiece({
    required this.type,
    required this.id,
    required this.health,
    required this.primaryStat,
    this.warriorAttackedTurn,
  });

  factory OnlineBoardPiece.fromValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Los datos de una pieza no son válidos.');
    }
    final data = Map<Object?, Object?>.from(value);
    final type = data['type'];
    final id = data['id'];
    final health = data['health'];
    final primaryStat = data['primaryStat'];
    final warriorAttackedTurn = data['warriorAttackedTurn'];
    if (!const {
          'warrior',
          'tower',
          'hospital',
          'crop',
          'villager',
        }.contains(type) ||
        id is! String ||
        health is! num ||
        health <= 0 ||
        primaryStat is! num ||
        primaryStat < 0 ||
        (warriorAttackedTurn != null &&
            (type != 'warrior' ||
                warriorAttackedTurn is! num ||
                warriorAttackedTurn < 0))) {
      throw const FormatException('Los datos de una pieza no son válidos.');
    }
    return OnlineBoardPiece(
      type: type as String,
      id: id,
      health: health.toInt(),
      primaryStat: primaryStat.toInt(),
      warriorAttackedTurn: (warriorAttackedTurn as num?)?.toInt(),
    );
  }

  Map<String, Object> toValue() => {
    'type': type,
    'id': id,
    'health': health,
    'primaryStat': primaryStat,
    if (warriorAttackedTurn != null)
      'warriorAttackedTurn': warriorAttackedTurn!,
  };
}

class OnlineHarvestResult {
  final int turn;
  final String playerRole;
  final int totalPoints;
  final Map<String, int> cropPoints;

  const OnlineHarvestResult({
    required this.turn,
    required this.playerRole,
    required this.totalPoints,
    required this.cropPoints,
  });

  factory OnlineHarvestResult.fromValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Los datos de cosecha no son válidos.');
    }
    final data = Map<Object?, Object?>.from(value);
    final turn = data['turn'];
    final playerRole = data['playerRole'];
    final totalPoints = data['totalPoints'];
    final rawCropPoints = data['cropPoints'];
    if (turn is! num ||
        turn < 0 ||
        (playerRole != 'host' && playerRole != 'guest') ||
        totalPoints is! num ||
        totalPoints < 0 ||
        (rawCropPoints != null && rawCropPoints is! Map)) {
      throw const FormatException('Los datos de cosecha no son válidos.');
    }

    final cropPoints = <String, int>{};
    var calculatedTotal = 0;
    if (rawCropPoints is Map) {
      for (final entry in rawCropPoints.entries) {
        if (entry.key is! String || entry.value is! num || entry.value < 0) {
          throw const FormatException(
            'Los puntos de un cultivo no son válidos.',
          );
        }
        final points = (entry.value as num).toInt();
        cropPoints[entry.key as String] = points;
        calculatedTotal += points;
      }
    }
    if (calculatedTotal != totalPoints.toInt()) {
      throw const FormatException('El total de cosecha no coincide.');
    }

    return OnlineHarvestResult(
      turn: turn.toInt(),
      playerRole: playerRole as String,
      totalPoints: totalPoints.toInt(),
      cropPoints: Map.unmodifiable(cropPoints),
    );
  }
}

class OnlineEarthquakeEvent {
  final int turn;
  final String playerRole;
  final int damage;
  final int affectedStructures;
  final bool monumentDestroyed;

  const OnlineEarthquakeEvent({
    required this.turn,
    required this.playerRole,
    required this.damage,
    required this.affectedStructures,
    required this.monumentDestroyed,
  });

  factory OnlineEarthquakeEvent.fromValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Los datos del terremoto no son válidos.');
    }
    final data = Map<Object?, Object?>.from(value);
    final turn = data['turn'];
    final playerRole = data['playerRole'];
    final damage = data['damage'];
    final affectedStructures = data['affectedStructures'];
    final monumentDestroyed = data['monumentDestroyed'];
    if (turn is! num ||
        turn < 0 ||
        turn != turn.toInt() ||
        (playerRole != 'host' && playerRole != 'guest') ||
        damage is! num ||
        damage < 0 ||
        damage != damage.toInt() ||
        affectedStructures is! num ||
        affectedStructures < 0 ||
        affectedStructures != affectedStructures.toInt() ||
        monumentDestroyed is! bool) {
      throw const FormatException('Los datos del terremoto no son válidos.');
    }
    return OnlineEarthquakeEvent(
      turn: turn.toInt(),
      playerRole: playerRole as String,
      damage: damage.toInt(),
      affectedStructures: affectedStructures.toInt(),
      monumentDestroyed: monumentDestroyed,
    );
  }

  Map<String, Object> toValue() => {
    'turn': turn,
    'playerRole': playerRole,
    'damage': damage,
    'affectedStructures': affectedStructures,
    'monumentDestroyed': monumentDestroyed,
  };
}

class OnlineDisasterEvent {
  final int turn;
  final String playerRole;
  final int damage;
  final int affectedPieces;
  final int destroyedPieces;

  const OnlineDisasterEvent({
    required this.turn,
    required this.playerRole,
    required this.damage,
    required this.affectedPieces,
    required this.destroyedPieces,
  });

  factory OnlineDisasterEvent.fromValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Los datos del desastre no son válidos.');
    }
    final data = Map<Object?, Object?>.from(value);
    final turn = data['turn'];
    final playerRole = data['playerRole'];
    final damage = data['damage'];
    final affectedPieces = data['affectedPieces'];
    final destroyedPieces = data['destroyedPieces'];
    if (turn is! num ||
        turn < 0 ||
        turn != turn.toInt() ||
        (playerRole != 'host' && playerRole != 'guest') ||
        damage is! num ||
        damage < 0 ||
        damage != damage.toInt() ||
        affectedPieces is! num ||
        affectedPieces < 0 ||
        affectedPieces != affectedPieces.toInt() ||
        destroyedPieces is! num ||
        destroyedPieces < 0 ||
        destroyedPieces != destroyedPieces.toInt() ||
        destroyedPieces > affectedPieces) {
      throw const FormatException('Los datos del desastre no son válidos.');
    }
    return OnlineDisasterEvent(
      turn: turn.toInt(),
      playerRole: playerRole as String,
      damage: damage.toInt(),
      affectedPieces: affectedPieces.toInt(),
      destroyedPieces: destroyedPieces.toInt(),
    );
  }

  Map<String, Object> toValue() => {
    'turn': turn,
    'playerRole': playerRole,
    'damage': damage,
    'affectedPieces': affectedPieces,
    'destroyedPieces': destroyedPieces,
  };
}

class OnlineHospitalHealingResult {
  final int turn;
  final String playerRole;
  final List<String> hospitalCoordinates;
  final Map<String, int> healedUnits;

  const OnlineHospitalHealingResult({
    required this.turn,
    required this.playerRole,
    required this.hospitalCoordinates,
    required this.healedUnits,
  });

  factory OnlineHospitalHealingResult.fromValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Los datos de curación no son válidos.');
    }
    final data = Map<Object?, Object?>.from(value);
    final turn = data['turn'];
    final playerRole = data['playerRole'];
    final rawHospitals = data['hospitalCoordinates'];
    final rawHealedUnits = data['healedUnits'];
    final hospitalCoordinates = switch (rawHospitals) {
      null => <Object?>[],
      List value => value,
      Map value => _orderedIndexedValues(value),
      _ => null,
    };
    final healedUnitsValue = rawHealedUnits ?? const <Object?, Object?>{};
    bool isBoardCoordinate(Object? coordinate) =>
        coordinate is String && RegExp(r'^r[0-3]c[0-4]$').hasMatch(coordinate);
    if (turn is! num ||
        turn < 0 ||
        (playerRole != 'host' && playerRole != 'guest') ||
        hospitalCoordinates == null ||
        hospitalCoordinates.any(
          (coordinate) => !isBoardCoordinate(coordinate),
        ) ||
        hospitalCoordinates.toSet().length != hospitalCoordinates.length ||
        healedUnitsValue is! Map) {
      throw const FormatException('Los datos de curación no son válidos.');
    }

    final healedUnits = <String, int>{};
    for (final entry in healedUnitsValue.entries) {
      if (!isBoardCoordinate(entry.key) ||
          entry.value is! num ||
          entry.value <= 0 ||
          entry.value != (entry.value as num).toInt()) {
        throw const FormatException(
          'Los puntos de curación de una unidad no son válidos.',
        );
      }
      healedUnits[entry.key as String] = (entry.value as num).toInt();
    }
    return OnlineHospitalHealingResult(
      turn: turn.toInt(),
      playerRole: playerRole as String,
      hospitalCoordinates: List.unmodifiable(
        hospitalCoordinates.cast<String>(),
      ),
      healedUnits: Map.unmodifiable(healedUnits),
    );
  }

  static List<Object?>? _orderedIndexedValues(Map values) {
    final indexedValues = <int, Object?>{};
    for (final entry in values.entries) {
      final index =
          entry.key is int
              ? entry.key as int
              : entry.key is String
              ? int.tryParse(entry.key as String)
              : null;
      if (index == null || index < 0 || indexedValues.containsKey(index)) {
        return null;
      }
      indexedValues[index] = entry.value;
    }
    final indexes = indexedValues.keys.toList()..sort();
    for (var index = 0; index < indexes.length; index++) {
      if (indexes[index] != index) return null;
    }
    return indexes.map((index) => indexedValues[index]).toList();
  }

  factory OnlineHospitalHealingResult.calculate({
    required int turn,
    required String playerRole,
    required Map<String, OnlineBoardPiece> board,
    required bool isMayan,
  }) {
    final hospitals = <String>[];
    final healedUnits = <String, int>{};
    final coordinates = <String, (int, int)>{};
    final coordinatePattern = RegExp(r'^r([0-3])c([0-4])$');

    for (final entry in board.entries) {
      final match = coordinatePattern.firstMatch(entry.key);
      if (match == null) {
        throw FormatException('Coordenada de pieza inválida: ${entry.key}');
      }
      coordinates[entry.key] = (
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
      );
      if (entry.value.type == 'hospital') hospitals.add(entry.key);
    }

    for (final hospitalCoordinate in hospitals) {
      final (hospitalRow, hospitalColumn) = coordinates[hospitalCoordinate]!;
      final hospital = board[hospitalCoordinate]!;
      final healingPower = hospital.primaryStat * (isMayan ? 2 : 1);
      if (healingPower == 0) continue;

      for (final entry in board.entries) {
        if (entry.value.type != 'warrior' && entry.value.type != 'villager') {
          continue;
        }
        final (row, column) = coordinates[entry.key]!;
        if (row == hospitalRow || column == hospitalColumn) {
          healedUnits.update(
            entry.key,
            (total) => total + healingPower,
            ifAbsent: () => healingPower,
          );
        }
      }
    }

    return OnlineHospitalHealingResult(
      turn: turn,
      playerRole: playerRole,
      hospitalCoordinates: List.unmodifiable(hospitals),
      healedUnits: Map.unmodifiable(healedUnits),
    );
  }

  Map<String, Object> toValue() => {
    'turn': turn,
    'playerRole': playerRole,
    'hospitalCoordinates': hospitalCoordinates,
    'healedUnits': healedUnits,
  };
}

class OnlineVillagerRepairResult {
  final int turn;
  final String playerRole;
  final List<String> villagerCoordinates;
  final Map<String, int> repairedBuildings;
  final int monumentRepair;

  const OnlineVillagerRepairResult({
    required this.turn,
    required this.playerRole,
    required this.villagerCoordinates,
    required this.repairedBuildings,
    required this.monumentRepair,
  });

  factory OnlineVillagerRepairResult.fromValue(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'Los datos de reconstrucción no son válidos.',
      );
    }
    final data = Map<Object?, Object?>.from(value);
    final turn = data['turn'];
    final playerRole = data['playerRole'];
    final rawVillagers = data['villagerCoordinates'];
    final rawBuildings = data['repairedBuildings'];
    final rawMonumentRepair = data['monumentRepair'] ?? 0;
    final villagerCoordinates = switch (rawVillagers) {
      null => <Object?>[],
      List value => value,
      Map value => _orderedIndexedValues(value),
      _ => null,
    };
    final repairedBuildings = rawBuildings ?? const <Object?, Object?>{};
    if (turn is! num ||
        turn < 0 ||
        (playerRole != 'host' && playerRole != 'guest') ||
        villagerCoordinates == null ||
        villagerCoordinates.any(
          (coordinate) => !_isBoardCoordinate(coordinate),
        ) ||
        villagerCoordinates.toSet().length != villagerCoordinates.length ||
        repairedBuildings is! Map ||
        rawMonumentRepair is! num ||
        rawMonumentRepair < 0 ||
        rawMonumentRepair != rawMonumentRepair.toInt()) {
      throw const FormatException(
        'Los datos de reconstrucción no son válidos.',
      );
    }

    final buildingPoints = <String, int>{};
    for (final entry in repairedBuildings.entries) {
      if (!_isBoardCoordinate(entry.key) ||
          entry.value is! num ||
          entry.value <= 0 ||
          entry.value != (entry.value as num).toInt()) {
        throw const FormatException(
          'Los puntos de reconstrucción de un edificio no son válidos.',
        );
      }
      buildingPoints[entry.key as String] = (entry.value as num).toInt();
    }

    return OnlineVillagerRepairResult(
      turn: turn.toInt(),
      playerRole: playerRole as String,
      villagerCoordinates: List.unmodifiable(
        villagerCoordinates.cast<String>(),
      ),
      repairedBuildings: Map.unmodifiable(buildingPoints),
      monumentRepair: rawMonumentRepair.toInt(),
    );
  }

  factory OnlineVillagerRepairResult.calculate({
    required int turn,
    required String playerRole,
    required Map<String, OnlineBoardPiece> board,
  }) {
    final villagers = <String>[];
    final repairedBuildings = <String, int>{};
    var monumentRepair = 0;
    final coordinates = <String, (int, int)>{};
    final coordinatePattern = RegExp(r'^r([0-3])c([0-4])$');

    for (final entry in board.entries) {
      final match = coordinatePattern.firstMatch(entry.key);
      if (match == null) {
        throw FormatException('Coordenada de pieza inválida: ${entry.key}');
      }
      coordinates[entry.key] = (
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
      );
      if (entry.value.type == 'villager') villagers.add(entry.key);
    }

    for (final villagerCoordinate in villagers) {
      final (villagerRow, villagerColumn) = coordinates[villagerCoordinate]!;
      final repairPower = board[villagerCoordinate]!.primaryStat;
      if (villagerRow == 3 || villagerColumn == 2) {
        monumentRepair += repairPower;
      }

      for (final entry in board.entries) {
        if (entry.value.type != 'tower' &&
            entry.value.type != 'hospital' &&
            entry.value.type != 'crop') {
          continue;
        }
        final (row, column) = coordinates[entry.key]!;
        if (row == villagerRow || column == villagerColumn) {
          repairedBuildings.update(
            entry.key,
            (total) => total + repairPower,
            ifAbsent: () => repairPower,
          );
        }
      }
    }

    return OnlineVillagerRepairResult(
      turn: turn,
      playerRole: playerRole,
      villagerCoordinates: List.unmodifiable(villagers),
      repairedBuildings: Map.unmodifiable(repairedBuildings),
      monumentRepair: monumentRepair,
    );
  }

  static bool _isBoardCoordinate(Object? value) =>
      value is String && RegExp(r'^r[0-3]c[0-4]$').hasMatch(value);

  static List<Object?>? _orderedIndexedValues(Map values) {
    final indexedValues = <int, Object?>{};
    for (final entry in values.entries) {
      final index =
          entry.key is int
              ? entry.key as int
              : entry.key is String
              ? int.tryParse(entry.key as String)
              : null;
      if (index == null || index < 0 || indexedValues.containsKey(index)) {
        return null;
      }
      indexedValues[index] = entry.value;
    }
    final indexes = indexedValues.keys.toList()..sort();
    for (var index = 0; index < indexes.length; index++) {
      if (indexes[index] != index) return null;
    }
    return indexes.map((index) => indexedValues[index]).toList();
  }

  Map<String, Object> toValue() => {
    'turn': turn,
    'playerRole': playerRole,
    'villagerCoordinates': villagerCoordinates,
    'repairedBuildings': repairedBuildings,
    'monumentRepair': monumentRepair,
  };
}

class OnlineTowerAttackEvent {
  final int turn;
  final int index;
  final String playerRole;
  final String towerCoordinate;
  final String targetRole;
  final String? targetCoordinate;
  final String targetType;
  final int damage;
  final int targetHealthAfter;
  final bool targetDestroyed;
  final OnlineBoardPiece? destroyedTargetPiece;

  const OnlineTowerAttackEvent({
    required this.turn,
    required this.index,
    required this.playerRole,
    required this.towerCoordinate,
    required this.targetRole,
    required this.targetCoordinate,
    required this.targetType,
    required this.damage,
    required this.targetHealthAfter,
    required this.targetDestroyed,
    this.destroyedTargetPiece,
  });

  factory OnlineTowerAttackEvent.fromValue(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'Los datos del ataque de torre no son válidos.',
      );
    }
    final data = Map<Object?, Object?>.from(value);
    final turn = data['turn'];
    final index = data['index'];
    final playerRole = data['playerRole'];
    final towerCoordinate = data['towerCoordinate'];
    final targetRole = data['targetRole'];
    final targetCoordinate = data['targetCoordinate'];
    final targetType = data['targetType'];
    final damage = data['damage'];
    final targetHealthAfter = data['targetHealthAfter'];
    final targetDestroyed = data['targetDestroyed'];
    final rawDestroyedTargetPiece = data['destroyedTargetPiece'];
    OnlineBoardPiece? destroyedTargetPiece;
    if (rawDestroyedTargetPiece != null) {
      destroyedTargetPiece = OnlineBoardPiece.fromValue(
        rawDestroyedTargetPiece,
      );
    }
    if (turn is! num ||
        turn < 0 ||
        index is! num ||
        index < 0 ||
        (playerRole != 'host' && playerRole != 'guest') ||
        !_isBoardCoordinate(towerCoordinate) ||
        (targetRole != 'host' && targetRole != 'guest') ||
        targetRole == playerRole ||
        (targetCoordinate != null && !_isBoardCoordinate(targetCoordinate)) ||
        (targetType != 'warrior' &&
            targetType != 'tower' &&
            targetType != 'hospital' &&
            targetType != 'crop' &&
            targetType != 'villager' &&
            targetType != 'monument') ||
        (targetType == 'monument' && targetCoordinate != null) ||
        (targetType != 'monument' && targetCoordinate == null) ||
        damage is! num ||
        damage <= 0 ||
        targetHealthAfter is! num ||
        targetDestroyed is! bool ||
        (targetType == 'monument' && targetDestroyed) ||
        (targetType != 'monument' &&
            targetDestroyed != (targetHealthAfter <= 0)) ||
        (destroyedTargetPiece != null &&
            (!targetDestroyed || destroyedTargetPiece.type != targetType))) {
      throw const FormatException(
        'Los datos del ataque de torre no son válidos.',
      );
    }
    return OnlineTowerAttackEvent(
      turn: turn.toInt(),
      index: index.toInt(),
      playerRole: playerRole as String,
      towerCoordinate: towerCoordinate as String,
      targetRole: targetRole as String,
      targetCoordinate: targetCoordinate as String?,
      targetType: targetType as String,
      damage: damage.toInt(),
      targetHealthAfter: targetHealthAfter.toInt(),
      targetDestroyed: targetDestroyed,
      destroyedTargetPiece: destroyedTargetPiece,
    );
  }

  static bool _isBoardCoordinate(Object? value) =>
      value is String && RegExp(r'^r[0-3]c[0-4]$').hasMatch(value);

  static List<Object?>? parseCoordinateList(Object? value) => switch (value) {
    null => <Object?>[],
    List coordinates => coordinates,
    Map coordinates => OnlineHospitalHealingResult._orderedIndexedValues(
      coordinates,
    ),
    _ => null,
  };

  static List<String> orderedTowerCoordinates(
    Map<String, OnlineBoardPiece> board,
  ) {
    final priority = {0: 0, 1: 1, 3: 2, 4: 3, 2: 4};
    final coordinates = <String>[];
    for (final coordinate in board.keys) {
      final match = RegExp(r'^r([0-3])c([0-4])$').firstMatch(coordinate);
      if (match == null) {
        throw FormatException('Coordenada de pieza inválida: $coordinate');
      }
      if (board[coordinate]!.type == 'tower') coordinates.add(coordinate);
    }
    coordinates.sort((first, second) {
      final firstMatch = RegExp(r'^r([0-3])c([0-4])$').firstMatch(first)!;
      final secondMatch = RegExp(r'^r([0-3])c([0-4])$').firstMatch(second)!;
      final firstColumn = int.parse(firstMatch.group(2)!);
      final secondColumn = int.parse(secondMatch.group(2)!);
      final columnOrder = priority[firstColumn]!.compareTo(
        priority[secondColumn]!,
      );
      if (columnOrder != 0) return columnOrder;
      return int.parse(
        firstMatch.group(1)!,
      ).compareTo(int.parse(secondMatch.group(1)!));
    });
    return List.unmodifiable(coordinates);
  }

  static String? frontTargetCoordinate({
    required Map<String, OnlineBoardPiece> board,
    required int column,
    required String attackerRole,
  }) {
    if (column < 0 ||
        column > 4 ||
        (attackerRole != 'host' && attackerRole != 'guest')) {
      throw ArgumentError('La columna o el jugador atacante no son válidos.');
    }
    // Online board rows are stored from each owner's perspective: row 0 is
    // always the edge closest to the opponent, even when rendered mirrored.
    for (final row in const [0, 1, 2, 3]) {
      final coordinate = 'r${row}c$column';
      if (board.containsKey(coordinate)) return coordinate;
    }
    return null;
  }

  Map<String, Object?> toValue() => {
    'turn': turn,
    'index': index,
    'playerRole': playerRole,
    'towerCoordinate': towerCoordinate,
    'targetRole': targetRole,
    'targetCoordinate': targetCoordinate,
    'targetType': targetType,
    'damage': damage,
    'targetHealthAfter': targetHealthAfter,
    'targetDestroyed': targetDestroyed,
    if (destroyedTargetPiece != null)
      'destroyedTargetPiece': destroyedTargetPiece!.toValue(),
  };
}

class OnlineGameState {
  final String currentPlayer;
  final int turn;
  final int? diceRolledTurn;
  final String? diceRolledBy;
  final int? firstDie;
  final int? secondDie;
  final int? lastRollTotal;
  final int? harvestedTurn;
  final OnlineHarvestResult? lastHarvest;
  final OnlineHospitalHealingResult? lastHospitalHealing;
  final OnlineVillagerRepairResult? lastVillagerRepair;
  final int? towerAttackTurn;
  final String? towerAttackRole;
  final List<String> towerCoordinates;
  final int towerAttackIndex;
  final bool towerAttacksComplete;
  final int? towerAttacksTurn;
  final OnlineTowerAttackEvent? lastTowerAttack;
  final int? earthquakeCountdown;
  final int? earthquakeProcessedTurn;
  final OnlineEarthquakeEvent? lastEarthquake;
  final int? plagueCountdown;
  final int? plagueProcessedTurn;
  final OnlineDisasterEvent? lastPlague;
  final int? epidemicCountdown;
  final int? epidemicProcessedTurn;
  final OnlineDisasterEvent? lastEpidemic;
  final String? winner;
  final OnlineGamePlayer host;
  final OnlineGamePlayer guest;

  const OnlineGameState({
    required this.currentPlayer,
    required this.turn,
    required this.diceRolledTurn,
    required this.diceRolledBy,
    required this.firstDie,
    required this.secondDie,
    required this.lastRollTotal,
    required this.harvestedTurn,
    required this.lastHarvest,
    required this.lastHospitalHealing,
    required this.lastVillagerRepair,
    required this.towerAttackTurn,
    required this.towerAttackRole,
    required this.towerCoordinates,
    required this.towerAttackIndex,
    required this.towerAttacksComplete,
    required this.towerAttacksTurn,
    required this.lastTowerAttack,
    required this.earthquakeCountdown,
    required this.earthquakeProcessedTurn,
    required this.lastEarthquake,
    required this.plagueCountdown,
    required this.plagueProcessedTurn,
    required this.lastPlague,
    required this.epidemicCountdown,
    required this.epidemicProcessedTurn,
    required this.lastEpidemic,
    required this.winner,
    required this.host,
    required this.guest,
  });

  factory OnlineGameState.fromRoomSnapshot(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'Los datos de la sala tienen un formato inválido.',
      );
    }
    final room = Map<Object?, Object?>.from(value);
    if (room['phase'] != 'gameReady') {
      throw const FormatException('La partida todavía no está lista.');
    }
    final rawGame = room['game'];
    if (rawGame is! Map) {
      throw const FormatException('No se encontró el estado de la partida.');
    }
    final game = Map<Object?, Object?>.from(rawGame);
    final status = game['status'];
    final currentPlayer = game['currentPlayer'];
    final turn = game['turn'];
    final rawDiceRolledTurn = game['diceRolledTurn'];
    final rawLastRoll = game['lastRoll'];
    final rawHarvestedTurn = game['harvestedTurn'];
    final rawLastHarvest = game['lastHarvest'];
    final rawLastHospitalHealing = game['lastHospitalHealing'];
    final rawLastVillagerRepair = game['lastVillagerRepair'];
    final rawTowerAttackTurn = game['towerAttackTurn'];
    final towerAttackRole = game['towerAttackRole'];
    final rawTowerCoordinates = game['towerCoordinates'];
    final rawTowerAttackIndex = game['towerAttackIndex'] ?? 0;
    final rawTowerAttacksComplete = game['towerAttacksComplete'] ?? false;
    final rawTowerAttacksTurn = game['towerAttacksTurn'];
    final rawLastTowerAttack = game['lastTowerAttack'];
    final rawEarthquakeCountdown = game['earthquakeCountdown'];
    final rawEarthquakeProcessedTurn = game['earthquakeProcessedTurn'];
    final rawLastEarthquake = game['lastEarthquake'];
    final rawPlagueCountdown = game['plagueCountdown'];
    final rawPlagueProcessedTurn = game['plagueProcessedTurn'];
    final rawLastPlague = game['lastPlague'];
    final rawEpidemicCountdown = game['epidemicCountdown'];
    final rawEpidemicProcessedTurn = game['epidemicProcessedTurn'];
    final rawLastEpidemic = game['lastEpidemic'];
    final winner = game['winner'];
    final rawPlayers = game['players'];
    if ((status != 'ready' && status != 'finished') ||
        (currentPlayer != 'host' && currentPlayer != 'guest') ||
        (winner != null && winner != 'host' && winner != 'guest') ||
        (status == 'finished' && winner == null) ||
        (status == 'ready' && winner != null) ||
        turn is! num ||
        turn < 0 ||
        rawPlayers is! Map) {
      throw const FormatException(
        'El estado actual de la partida no es válido.',
      );
    }
    if (rawDiceRolledTurn != null &&
        (rawDiceRolledTurn is! num || rawDiceRolledTurn < 0)) {
      throw const FormatException('El turno de los dados no es válido.');
    }
    if (rawHarvestedTurn != null &&
        (rawHarvestedTurn is! num || rawHarvestedTurn < 0)) {
      throw const FormatException('El turno de cosecha no es válido.');
    }

    int? lastRollTotal;
    int? firstDieValue;
    int? secondDieValue;
    String? diceRolledBy;
    if (rawLastRoll != null) {
      if (rawLastRoll is! Map) {
        throw const FormatException('El resultado de los dados no es válido.');
      }
      final lastRoll = Map<Object?, Object?>.from(rawLastRoll);
      final rollTurn = lastRoll['turn'];
      final firstDie = lastRoll['firstDie'];
      final secondDie = lastRoll['secondDie'];
      final total = lastRoll['total'];
      final rollerRole = lastRoll['rollerRole'];
      if (rollTurn is! num ||
          rawDiceRolledTurn is! num ||
          rollTurn != rawDiceRolledTurn ||
          (rollerRole != null &&
              rollerRole != 'host' &&
              rollerRole != 'guest') ||
          firstDie is! num ||
          secondDie is! num ||
          total is! num ||
          firstDie < 1 ||
          firstDie > 6 ||
          secondDie < 1 ||
          secondDie > 6 ||
          total != firstDie + secondDie) {
        throw const FormatException('El resultado de los dados no es válido.');
      }
      lastRollTotal = total.toInt();
      firstDieValue = firstDie.toInt();
      secondDieValue = secondDie.toInt();
      diceRolledBy = rollerRole as String? ?? currentPlayer as String;
    }
    final lastHarvest =
        rawLastHarvest == null
            ? null
            : OnlineHarvestResult.fromValue(rawLastHarvest);
    if (lastHarvest != null &&
        (rawHarvestedTurn is! num ||
            lastHarvest.turn != rawHarvestedTurn.toInt())) {
      throw const FormatException('El turno de cosecha no coincide.');
    }
    final lastHospitalHealing =
        rawLastHospitalHealing == null
            ? null
            : OnlineHospitalHealingResult.fromValue(rawLastHospitalHealing);
    if (lastHospitalHealing != null &&
        (lastHospitalHealing.turn != turn.toInt() ||
            lastHospitalHealing.playerRole != currentPlayer)) {
      throw const FormatException('El turno de curación no coincide.');
    }
    final lastVillagerRepair =
        rawLastVillagerRepair == null
            ? null
            : OnlineVillagerRepairResult.fromValue(rawLastVillagerRepair);
    if (lastVillagerRepair != null &&
        (lastVillagerRepair.turn != turn.toInt() ||
            lastVillagerRepair.playerRole != currentPlayer)) {
      throw const FormatException('El turno de reconstrucción no coincide.');
    }
    final towerCoordinates = OnlineTowerAttackEvent.parseCoordinateList(
      rawTowerCoordinates,
    );
    if (towerCoordinates == null ||
        towerCoordinates.any(
          (coordinate) =>
              coordinate is! String ||
              !RegExp(r'^r[0-3]c[0-4]$').hasMatch(coordinate),
        ) ||
        rawTowerAttackIndex is! num ||
        rawTowerAttackIndex < 0 ||
        rawTowerAttackIndex != rawTowerAttackIndex.toInt() ||
        rawTowerAttacksComplete is! bool ||
        (rawTowerAttackTurn != null &&
            (rawTowerAttackTurn is! num || rawTowerAttackTurn < 0)) ||
        (towerAttackRole != null &&
            towerAttackRole != 'host' &&
            towerAttackRole != 'guest') ||
        (rawTowerAttacksTurn != null &&
            (rawTowerAttacksTurn is! num || rawTowerAttacksTurn < 0))) {
      throw const FormatException(
        'El orden de ataque de las torres no es válido.',
      );
    }
    final lastTowerAttack =
        rawLastTowerAttack == null
            ? null
            : OnlineTowerAttackEvent.fromValue(rawLastTowerAttack);
    if (lastTowerAttack != null &&
        (rawTowerAttackTurn is! num ||
            lastTowerAttack.turn != rawTowerAttackTurn.toInt() ||
            lastTowerAttack.playerRole != towerAttackRole)) {
      throw const FormatException(
        'El ataque de torre no coincide con el turno.',
      );
    }
    if ((rawEarthquakeCountdown != null &&
            (rawEarthquakeCountdown is! num ||
                rawEarthquakeCountdown < 0 ||
                rawEarthquakeCountdown != rawEarthquakeCountdown.toInt())) ||
        (rawEarthquakeProcessedTurn != null &&
            (rawEarthquakeProcessedTurn is! num ||
                rawEarthquakeProcessedTurn < 0 ||
                rawEarthquakeProcessedTurn !=
                    rawEarthquakeProcessedTurn.toInt() ||
                rawEarthquakeProcessedTurn > turn))) {
      throw const FormatException(
        'El contador de terremoto no es válido.',
      );
    }
    final lastEarthquake =
        rawLastEarthquake == null
            ? null
            : OnlineEarthquakeEvent.fromValue(rawLastEarthquake);
    if (lastEarthquake != null && lastEarthquake.turn > turn.toInt()) {
      throw const FormatException(
        'El evento de terremoto no coincide con el turno.',
      );
    }
    int? parseDisasterCountdown(Object? value) {
      if (value == null) return null;
      if (value is! num || value < 0 || value != value.toInt()) {
        throw const FormatException(
          'El contador de desastre no es válido.',
        );
      }
      return value.toInt();
    }

    int? parseDisasterProcessedTurn(Object? value) {
      if (value == null) return null;
      if (value is! num ||
          value < 0 ||
          value != value.toInt() ||
          value > turn) {
        throw const FormatException(
          'El turno del desastre no es válido.',
        );
      }
      return value.toInt();
    }

    OnlineDisasterEvent? parseDisasterEvent(Object? value) {
      if (value == null) return null;
      final event = OnlineDisasterEvent.fromValue(value);
      if (event.turn > turn.toInt()) {
        throw const FormatException(
          'El evento de desastre no coincide con el turno.',
        );
      }
      return event;
    }

    final plagueCountdown = parseDisasterCountdown(rawPlagueCountdown);
    final plagueProcessedTurn = parseDisasterProcessedTurn(
      rawPlagueProcessedTurn,
    );
    final lastPlague = parseDisasterEvent(rawLastPlague);
    final epidemicCountdown = parseDisasterCountdown(rawEpidemicCountdown);
    final epidemicProcessedTurn = parseDisasterProcessedTurn(
      rawEpidemicProcessedTurn,
    );
    final lastEpidemic = parseDisasterEvent(rawLastEpidemic);
    final players = Map<Object?, Object?>.from(rawPlayers);
    return OnlineGameState(
      currentPlayer: currentPlayer as String,
      turn: turn.toInt(),
      diceRolledTurn: (rawDiceRolledTurn as num?)?.toInt(),
      diceRolledBy: diceRolledBy,
      firstDie: firstDieValue,
      secondDie: secondDieValue,
      lastRollTotal: lastRollTotal,
      harvestedTurn: (rawHarvestedTurn as num?)?.toInt(),
      lastHarvest: lastHarvest,
      lastHospitalHealing: lastHospitalHealing,
      lastVillagerRepair: lastVillagerRepair,
      towerAttackTurn: (rawTowerAttackTurn as num?)?.toInt(),
      towerAttackRole: towerAttackRole as String?,
      towerCoordinates: List.unmodifiable(towerCoordinates.cast<String>()),
      towerAttackIndex: rawTowerAttackIndex.toInt(),
      towerAttacksComplete: rawTowerAttacksComplete,
      towerAttacksTurn: (rawTowerAttacksTurn as num?)?.toInt(),
      lastTowerAttack: lastTowerAttack,
      earthquakeCountdown: (rawEarthquakeCountdown as num?)?.toInt(),
      earthquakeProcessedTurn: (rawEarthquakeProcessedTurn as num?)?.toInt(),
      lastEarthquake: lastEarthquake,
      plagueCountdown: plagueCountdown,
      plagueProcessedTurn: plagueProcessedTurn,
      lastPlague: lastPlague,
      epidemicCountdown: epidemicCountdown,
      epidemicProcessedTurn: epidemicProcessedTurn,
      lastEpidemic: lastEpidemic,
      winner: winner as String?,
      host: OnlineGamePlayer.fromValue(players['host']),
      guest: OnlineGamePlayer.fromValue(players['guest']),
    );
  }

  OnlineGamePlayer playerForRole(String role) => switch (role) {
    'host' => host,
    'guest' => guest,
    _ => throw ArgumentError.value(role, 'role', 'Jugador inválido.'),
  };

  OnlineGamePlayer opponentForRole(String role) => switch (role) {
    'host' => guest,
    'guest' => host,
    _ => throw ArgumentError.value(role, 'role', 'Jugador inválido.'),
  };

  bool hasWarriorAttacked(String role, String coordinate) {
    if (role != 'host' && role != 'guest') {
      throw ArgumentError.value(role, 'role', 'Jugador inválido.');
    }
    final warrior = playerForRole(role).board[coordinate];
    return warrior?.type == 'warrior' &&
        warrior!.warriorAttackedTurn == turn;
  }

  bool canWarriorAttack(String role, String coordinate) {
    if ((role != 'host' && role != 'guest') ||
        !_isBoardCoordinate(coordinate) ||
        winner != null) {
      return false;
    }
    final player = playerForRole(role);
    final warrior = player.board[coordinate];
    if (warrior == null ||
        warrior.type != 'warrior' ||
        warrior.primaryStat <= 0 ||
        warrior.warriorAttackedTurn == turn) {
      return false;
    }

    final opponent = opponentForRole(role);
    if (opponent.board.isEmpty) return opponent.monumentHealth > 0;
    final column = int.parse(coordinate[3]);
    return OnlineTowerAttackEvent.frontTargetCoordinate(
          board: opponent.board,
          column: column,
          attackerRole: role,
        ) !=
        null;
  }

  static bool _isBoardCoordinate(String value) =>
      RegExp(r'^r[0-3]c[0-4]$').hasMatch(value);
}
