import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../protocol/message.dart';

class ConnectedPlayer {
  final String name;
  final WebSocket socket;
  const ConnectedPlayer({required this.name, required this.socket});
}

class HostServer {
  final String roomCode;
  HttpServer? _server;

  final List<ConnectedPlayer> players = [];

  final _messagesController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messages => _messagesController.stream;

  final _playersController = StreamController<List<ConnectedPlayer>>.broadcast();
  Stream<List<ConnectedPlayer>> get playerUpdates => _playersController.stream;

  HostServer({required this.roomCode});

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    _server!.listen(_handleRequest);
  }

  void _handleRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    final socket = await WebSocketTransformer.upgrade(request);
    _handleSocket(socket);
  }

  void _handleSocket(WebSocket socket) async {
    ConnectedPlayer? player;

    await for (final raw in socket) {
      final Map<String, dynamic> msg;
      try {
        msg = jsonDecode(raw as String) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }

      final type = msg['type'] as String?;

      if (player == null) {
        if (type != msgTypeJoin) continue;

        final code = msg['roomCode'] as String? ?? '';
        final name = msg['name'] as String? ?? 'Unknown';

        if (code != roomCode) {
          sendTo(socket, {'type': msgTypeJoinAck, 'success': false, 'reason': 'Wrong room code'});
          await socket.close();
          return;
        }

        sendTo(socket, {'type': msgTypeJoinAck, 'success': true});
        player = ConnectedPlayer(name: name, socket: socket);
        players.add(player);
        _playersController.add(List.unmodifiable(players));

        broadcast({'type': msgTypePlayerJoined, 'name': name});
        _messagesController.add(ChatMessage(from: 'System', text: '$name joined', isSystem: true));
      } else {
        if (type == msgTypeMessage) {
          final text = msg['text'] as String? ?? '';
          _messagesController.add(ChatMessage(from: player.name, text: text));
        }
      }
    }

    if (player != null) {
      players.remove(player);
      _playersController.add(List.unmodifiable(players));
      _messagesController.add(ChatMessage(from: 'System', text: '${player.name} disconnected', isSystem: true));
    }
  }

  void sendTo(WebSocket socket, Map<String, dynamic> msg) {
    socket.add(jsonEncode(msg));
  }

  void broadcast(Map<String, dynamic> msg) {
    final encoded = jsonEncode(msg);
    for (final p in players) {
      p.socket.add(encoded);
    }
  }

  void stop() {
    _server?.close(force: true);
    _messagesController.close();
    _playersController.close();
  }
}
