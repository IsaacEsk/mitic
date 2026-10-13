import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mitic/models/online_room.dart';
import 'package:mitic/screens/online_match_screen.dart';
import 'package:mitic/services/online_rooms_service.dart';
import 'package:mitic/services/realtime_database_service.dart';
import 'package:mitic/services/translationService.dart';

class OnlineRoomsScreen extends StatefulWidget {
  final String selectedLanguage;

  const OnlineRoomsScreen({super.key, required this.selectedLanguage});

  @override
  State<OnlineRoomsScreen> createState() => _OnlineRoomsScreenState();
}

class _OnlineRoomsScreenState extends State<OnlineRoomsScreen> {
  static const _navy = Color(0xFF172554);
  static const _pageBackground = Color(0xFFF3F5F9);
  static const _mutedText = Color(0xFF5B6475);

  late final Future<User> _userFuture;
  Map<String, String> _translations = {};
  bool _creatingRoom = false;
  String? _joiningRoomId;
  String? _errorMessage;

  bool get _isEnglish => widget.selectedLanguage == 'en';

  String _text(String key, String spanish, String english) =>
      _translations[key] ?? (_isEnglish ? english : spanish);

  String _roomTitle(String roomId) => _text(
    'online_room_title',
    'Sala {id}',
    'Room {id}',
  ).replaceAll('{id}', roomId);

  @override
  void initState() {
    super.initState();
    _userFuture = RealtimeDatabaseService.ensureSignedIn();
    TranslationService.loadTranslations(widget.selectedLanguage).then((
      translations,
    ) {
      if (mounted) setState(() => _translations = translations);
    });
  }

  Future<void> _createRoom(User user) async {
    setState(() {
      _creatingRoom = true;
      _errorMessage = null;
    });

    try {
      final room = await OnlineRoomsService.createRoom(user.uid);
      if (!mounted) return;
      await _openRoom(room, user);
    } on FirebaseException catch (error) {
      _showError(error.message ?? error.code);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _creatingRoom = false);
    }
  }

  Future<void> _joinRoom(OnlineRoom room, User user) async {
    setState(() {
      _joiningRoomId = room.id;
      _errorMessage = null;
    });

    try {
      final joined = await OnlineRoomsService.joinRoom(room.id, user.uid);
      if (!mounted) return;
      if (!joined) {
        _showError(
          _text(
            'online_room_unavailable',
            'Esa sala ya no está disponible.',
            'That room is no longer available.',
          ),
        );
        return;
      }
      await _openRoom(room, user);
    } on FirebaseException catch (error) {
      _showError(error.message ?? error.code);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _joiningRoomId = null);
    }
  }

  Future<void> _openRoom(OnlineRoom room, User user) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (context) => OnlineMatchScreen(
              room: room,
              uid: user.uid,
              selectedLanguage: widget.selectedLanguage,
            ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[900]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: Text(
          _text('online_rooms_title', 'Salas online', 'Online rooms'),
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return _buildMessage(
              _text(
                'online_auth_error',
                'No se pudo conectar con Firebase Authentication.',
                'Could not connect to Firebase Authentication.',
              ),
              details: userSnapshot.error.toString(),
              icon: Icons.cloud_off_outlined,
            );
          }
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: _navy));
          }

          final user = userSnapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Colors.amber, size: 34),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(
                              'online_play_together',
                              'Juega con alguien',
                              'Play together',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _text(
                              'online_create_or_join_hint',
                              'Crea una sala o únete a una partida abierta.',
                              'Create a room or join an open game.',
                            ),
                            style: const TextStyle(
                              color: Color(0xFFE0E7FF),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E7EF)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(
                          'online_start_game',
                          'Inicia una partida',
                          'Start a game',
                        ),
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _text(
                          'online_create_room_wait',
                          'Crea una sala y espera a que se una otro jugador.',
                          'Create a room and wait for another player.',
                        ),
                        style: const TextStyle(color: _mutedText, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _creatingRoom ? null : () => _createRoom(user),
                          icon:
                              _creatingRoom
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _navy,
                                    ),
                                  )
                                  : const Icon(Icons.add),
                          label: Text(
                            _creatingRoom
                                ? _text(
                                  'online_creating_room',
                                  'Creando...',
                                  'Creating...',
                                )
                                : _text(
                                  'online_create_room',
                                  'Crear sala',
                                  'Create room',
                                ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC857),
                            foregroundColor: _navy,
                            disabledBackgroundColor: const Color(0xFFFFE5A6),
                            disabledForegroundColor: _navy,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildInlineError(_errorMessage!),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.meeting_room_outlined, color: _navy),
                  const SizedBox(width: 8),
                  Text(
                    _text(
                      'online_available_rooms',
                      'Salas disponibles',
                      'Available rooms',
                    ),
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<OnlineRoom>>(
                stream: OnlineRoomsService.watchWaitingRooms(),
                builder: (context, roomsSnapshot) {
                  if (roomsSnapshot.hasError) {
                    return _buildMessage(
                      _text(
                        'online_database_error',
                        'No se pudieron cargar las salas de Realtime Database.',
                        'Could not load rooms from Realtime Database.',
                      ),
                      details: roomsSnapshot.error.toString(),
                      icon: Icons.cloud_off_outlined,
                    );
                  }
                  if (!roomsSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: CircularProgressIndicator(color: _navy),
                      ),
                    );
                  }

                  final rooms = roomsSnapshot.data!;
                  if (rooms.isEmpty) {
                    return _buildMessage(
                      _text(
                        'online_no_open_rooms',
                        'Todavía no hay salas abiertas.',
                        'No open rooms yet.',
                      ),
                      subtitle: _text(
                        'online_empty_rooms_hint',
                        'Crea una sala y aparecerá aquí para que otros puedan unirse.',
                        'Create a room and it will appear here for other players.',
                      ),
                      icon: Icons.sports_esports_outlined,
                    );
                  }

                  return Column(
                    children:
                        rooms.map((room) {
                          final isJoining = _joiningRoomId == room.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: Colors.white,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0xFFE2E7EF),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EEFF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.meeting_room,
                                    color: _navy,
                                  ),
                                ),
                                title: Text(
                                  _roomTitle(room.id),
                                  style: const TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  _text(
                                    'online_room_waiting_status',
                                    'Esperando a otro jugador',
                                    'Waiting for a player',
                                  ),
                                  style: const TextStyle(color: _mutedText),
                                ),
                                trailing: FilledButton(
                                  onPressed:
                                      isJoining || _joiningRoomId != null
                                          ? null
                                          : () => _joinRoom(room, user),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _navy,
                                    foregroundColor: Colors.white,
                                  ),
                                  child:
                                      isJoining
                                          ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : Text(
                                            _text(
                                              'online_join_room',
                                              'Unirse',
                                              'Join',
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessage(
    String message, {
    String? subtitle,
    String? details,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _navy, size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedText, fontSize: 14),
            ),
          ],
          if (details != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              details,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9B1C31), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2B8BE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF9B1C31)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF821629)),
            ),
          ),
        ],
      ),
    );
  }
}
