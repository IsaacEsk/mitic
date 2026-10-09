import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mitic/models/online_room.dart';
import 'package:mitic/services/online_rooms_service.dart';

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
  StreamSubscription<DatabaseEvent>? _roomSubscription;
  OnlineRoom? _room;
  Object? _error;
  bool _leaving = false;
  bool _navigatedToMatch = false;

  bool get _isEnglish => widget.selectedLanguage == 'en';

  @override
  void initState() {
    super.initState();
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
      if (mounted) setState(() => _error = StateError('La sala ya no existe.'));
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
                (context) =>
                    _OnlineMatchPlaceholder(room: room, isEnglish: _isEnglish),
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
    return Scaffold(
      backgroundColor: Colors.grey[950],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _isEnglish ? 'Room ${widget.room.id}' : 'Sala ${widget.room.id}',
        ),
        leading: IconButton(
          onPressed: _leaving ? null : _leaveRoom,
          icon: const Icon(Icons.arrow_back),
          tooltip: _isEnglish ? 'Leave room' : 'Salir de la sala',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                _room?.guestUid == null
                    ? (_isEnglish
                        ? 'Waiting for another player to join...'
                        : 'Esperando a que se una otro jugador...')
                    : (_isEnglish
                        ? 'Both players are connected!'
                        : '¡Ya están conectados los dos jugadores!'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isEnglish
                    ? 'You are ${isHost ? 'Player 1' : 'Player 2'}.'
                    : 'Eres el jugador ${isHost ? '1' : '2'}.',
                style: const TextStyle(color: Colors.white70),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _leaving ? null : _leaveRoom,
                child: Text(
                  _leaving
                      ? (_isEnglish ? 'Leaving...' : 'Saliendo...')
                      : (_isEnglish ? 'Cancel' : 'Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineMatchPlaceholder extends StatelessWidget {
  final OnlineRoom room;
  final bool isEnglish;

  const _OnlineMatchPlaceholder({required this.room, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isEnglish ? 'Online game' : 'Partida online'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 24),
              Text(
                isEnglish
                    ? 'Room connected successfully!'
                    : '¡La sala se conectó correctamente!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                isEnglish ? 'Room ID: ${room.id}' : 'ID de sala: ${room.id}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed:
                    () => Navigator.popUntil(context, (route) => route.isFirst),
                child: Text(isEnglish ? 'Back to menu' : 'Volver al menú'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
