import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mitic/models/online_room.dart';
import 'package:mitic/screens/selectCivScreen.dart';
import 'package:mitic/services/online_rooms_service.dart';
import 'package:mitic/services/translationService.dart';

class OnlineMatchScreen extends StatefulWidget {
  final OnlineRoom room;
  final String uid;
  final String selectedLanguage;

  const OnlineMatchScreen({
    super.key,
    required this.room,
    required this.uid,
    required this.selectedLanguage,
  });

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen> {
  static const _navy = Color(0xFF172554);
  static const _pageBackground = Color(0xFFF3F5F9);
  static const _mutedText = Color(0xFF5B6475);

  StreamSubscription<DatabaseEvent>? _roomSubscription;
  OnlineRoom? _room;
  Map<String, String> _translations = {};
  Object? _error;
  bool _leaving = false;
  bool _navigatedToMatch = false;

  String _text(String key, String spanish, String english) =>
      _translations[key] ??
      (widget.selectedLanguage == 'en' ? english : spanish);

  String get _roomTitle =>
      _text('online_room_title', 'Sala {id}', 'Room {id}')
          .replaceAll('{id}', widget.room.id);

  @override
  void initState() {
    super.initState();
    TranslationService.loadTranslations(widget.selectedLanguage).then((
      translations,
    ) {
      if (mounted) setState(() => _translations = translations);
    });
    _roomSubscription = OnlineRoomsService.roomRef(
      widget.room.id,
    ).onValue.listen(
      _handleRoomEvent,
      onError: (Object error) {
        if (mounted) setState(() => _error = error);
      },
    );
  }

  void _handleRoomEvent(DatabaseEvent event) {
    final value = event.snapshot.value;
    if (value == null) {
      if (mounted) {
        setState(
          () => _error = StateError(
            _text(
              'online_room_missing',
              'La sala ya no existe.',
              'The room no longer exists.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final room = OnlineRoom.fromSnapshot(widget.room.id, value);
      if (!mounted) return;
      setState(() => _room = room);

      if (room.status == 'ready' &&
          room.guestUid != null &&
          !_navigatedToMatch) {
        _navigatedToMatch = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => SelectCivScreen(
                  selectedLanguage: widget.selectedLanguage,
                  onlineRoom: room,
                  uid: widget.uid,
                ),
          ),
        );
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _leaveRoom() async {
    final room = _room ?? widget.room;
    setState(() => _leaving = true);
    try {
      await OnlineRoomsService.leaveRoom(room: room, uid: widget.uid);
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? error.code),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHost = widget.room.hostUid == widget.uid;
    final guestJoined = _room?.guestUid != null;
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(
          _roomTitle,
        ),
        leading: IconButton(
          onPressed: _leaving ? null : _leaveRoom,
          icon: const Icon(Icons.arrow_back),
          tooltip: _text('online_leave_room', 'Salir de la sala', 'Leave room'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFE2E7EF)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        guestJoined
                            ? Icons.groups_rounded
                            : Icons.hourglass_top_rounded,
                        color: _navy,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      guestJoined
                          ? _text(
                            'online_both_players_connected',
                            '¡Ya están conectados los dos jugadores!',
                            'Both players are connected!',
                          )
                          : _text(
                            'online_room_ready_title',
                            'Tu sala está lista',
                            'Your room is ready',
                          ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      guestJoined
                          ? _text(
                            'online_preparing_game',
                            'Preparando la partida...',
                            'Getting the game ready...',
                          )
                          : _text(
                            'online_room_wait_instructions',
                            'Comparte el número de sala o espera a que se una otro jugador.',
                            'Share the room number or wait for another player to join.',
                          ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PlayerStatusTile(
                      number: 1,
                      label: _text('online_player_one', 'Jugador 1', 'Player 1'),
                      isReady: isHost || guestJoined,
                      isCurrentPlayer: isHost,
                      youLabel: _text('online_you', 'Tú', 'You'),
                      readyLabel: _text('online_status_ready', 'Listo', 'Ready'),
                      waitingLabel: _text(
                        'online_status_waiting',
                        'En espera',
                        'Waiting',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PlayerStatusTile(
                      number: 2,
                      label: _text('online_player_two', 'Jugador 2', 'Player 2'),
                      isReady: guestJoined,
                      isCurrentPlayer: !isHost,
                      youLabel: _text('online_you', 'Tú', 'You'),
                      readyLabel: _text('online_status_ready', 'Listo', 'Ready'),
                      waitingLabel: _text(
                        'online_status_waiting',
                        'En espera',
                        'Waiting',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _text(
                              'online_room_number',
                              'NÚMERO DE SALA',
                              'ROOM NUMBER',
                            ),
                            style: const TextStyle(
                              color: _mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SelectableText(
                            widget.room.id,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!guestJoined) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _navy,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _text(
                              'online_waiting_for_player',
                              'Esperando a otro jugador...',
                              'Waiting for a player...',
                            ),
                            style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF2B8BE)),
                        ),
                        child: Text(
                          _error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF821629),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    OutlinedButton.icon(
                      onPressed: _leaving ? null : _leaveRoom,
                      icon:
                          _leaving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.logout_rounded),
                      label: Text(
                        _leaving
                            ? _text('online_leaving', 'Saliendo...', 'Leaving...')
                            : _text(
                              'online_leave_room',
                              'Salir de la sala',
                              'Leave room',
                            ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        side: const BorderSide(color: Color(0xFFD4DCE8)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerStatusTile extends StatelessWidget {
  final int number;
  final String label;
  final bool isReady;
  final bool isCurrentPlayer;
  final String youLabel;
  final String readyLabel;
  final String waitingLabel;

  const _PlayerStatusTile({
    required this.number,
    required this.label,
    required this.isReady,
    required this.isCurrentPlayer,
    required this.youLabel,
    required this.readyLabel,
    required this.waitingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isReady ? const Color(0xFF18794E) : const Color(0xFF8A5A00);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isReady ? const Color(0xFFEAF7F0) : const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady ? const Color(0xFFC8E8D5) : const Color(0xFFF2DEB2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isReady ? const Color(0xFFD3EFDF) : Colors.white,
            child: Text(
              '$number',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _OnlineMatchScreenState._navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isCurrentPlayer)
                  Text(
                    youLabel,
                    style: const TextStyle(
                      color: _OnlineMatchScreenState._mutedText,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            isReady ? Icons.check_circle : Icons.schedule_rounded,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            isReady ? readyLabel : waitingLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class OnlineGameReadyScreen extends StatefulWidget {
  final OnlineRoom room;
  final String uid;
  final String selectedLanguage;

  const OnlineGameReadyScreen({
    super.key,
    required this.room,
    required this.uid,
    required this.selectedLanguage,
  });

  @override
  State<OnlineGameReadyScreen> createState() => _OnlineGameReadyScreenState();
}

class _OnlineGameReadyScreenState extends State<OnlineGameReadyScreen> {
  StreamSubscription<DatabaseEvent>? _roomSubscription;
  Map<String, String> _translations = {};
  bool _leaving = false;

  String _text(String key, String spanish, String english) =>
      _translations[key] ??
      (widget.selectedLanguage == 'en' ? english : spanish);

  @override
  void initState() {
    super.initState();
    TranslationService.loadTranslations(widget.selectedLanguage).then((
      translations,
    ) {
      if (mounted) setState(() => _translations = translations);
    });
    _roomSubscription = OnlineRoomsService.roomRef(
      widget.room.id,
    ).onValue.listen(
      _handleRoomEvent,
      onError: (Object error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red[900],
            ),
          );
        }
      },
    );
  }

  void _handleRoomEvent(DatabaseEvent event) {
    if (!mounted) return;
    final value = event.snapshot.value;
    if (value == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'online_room_missing',
              'La sala ya no existe.',
              'The room no longer exists.',
            ),
          ),
        ),
      );
      Navigator.pop(context);
      return;
    }
    try {
      final currentRoom = OnlineRoom.fromSnapshot(widget.room.id, value);
      final playerWasRemoved =
          widget.uid == widget.room.hostUid
              ? currentRoom.guestUid == null
              : currentRoom.guestUid != widget.uid;
      if (playerWasRemoved) Navigator.pop(context);
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  Future<void> _leaveRoom() async {
    setState(() => _leaving = true);
    try {
      await OnlineRoomsService.leaveRoom(room: widget.room, uid: widget.uid);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? error.code),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF172554),
        foregroundColor: Colors.white,
        title: Text(
          _text('online_game_title', 'Partida online', 'Online game'),
        ),
        leading: IconButton(
          onPressed: _leaving ? null : _leaveRoom,
          icon: const Icon(Icons.logout_rounded),
          tooltip: _text('online_leave_room', 'Salir de la sala', 'Leave room'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFE2E7EF)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF18794E),
                      size: 68,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _text(
                        'online_both_players_ready',
                        '¡Ambos jugadores están listos!',
                        'Both players are ready!',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF172554),
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _text(
                        'online_selections_saved',
                        'Sus selecciones están guardadas. La configuración compartida de la partida está lista.',
                        'Your selections have been saved. The shared game setup is ready.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5B6475),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SelectableText(
                        _text(
                          'online_room_id',
                          'ID de sala: {id}',
                          'Room ID: {id}',
                        ).replaceAll('{id}', widget.room.id),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF172554),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _text(
                        'online_board_next_step',
                        'El tablero online y la sincronización de turnos serán el siguiente paso de desarrollo.',
                        'The online board and synchronized turns are the next development step.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5B6475),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _leaving ? null : _leaveRoom,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        _text(
                          'online_back_to_menu',
                          'Volver al menú',
                          'Back to menu',
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF172554),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
