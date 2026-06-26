import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../protocol/message.dart';

class RoomClient {
  WebSocketChannel? _channel;

  final _messagesController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messages => _messagesController.stream;

  /// Returns null on success, or an error string on failure.
  Future<String?> connect(String ip, String roomCode, String name) async {
    final uri = Uri.parse('ws://$ip:8080');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
    } catch (e) {
      return 'Could not connect: $e';
    }

    _channel!.sink.add(jsonEncode({
      'type': msgTypeJoin,
      'name': name,
      'roomCode': roomCode,
    }));

    final completer = Completer<String?>();

    late StreamSubscription sub;
    sub = _channel!.stream.listen(
      (raw) {
        final Map<String, dynamic> msg;
        try {
          msg = jsonDecode(raw as String) as Map<String, dynamic>;
        } catch (_) {
          return;
        }

        final type = msg['type'] as String?;

        if (!completer.isCompleted) {
          if (type == msgTypeJoinAck) {
            final success = msg['success'] as bool? ?? false;
            if (success) {
              completer.complete(null);
            } else {
              completer.complete(msg['reason'] as String? ?? 'Rejected by host');
            }
          }
          return;
        }

        if (type == msgTypeMessage) {
          _messagesController.add(ChatMessage(
            from: msg['from'] as String? ?? 'Host',
            text: msg['text'] as String? ?? '',
          ));
        } else if (type == msgTypePlayerJoined) {
          _messagesController.add(ChatMessage(
            from: 'System',
            text: '${msg['name']} joined',
            isSystem: true,
          ));
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete('Connection closed');
        _messagesController.add(const ChatMessage(from: 'System', text: 'Disconnected from host', isSystem: true));
      },
      onError: (e) {
        if (!completer.isCompleted) completer.complete('Error: $e');
      },
    );

    final result = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => 'Connection timed out',
    );

    if (result != null) {
      sub.cancel();
      _channel?.sink.close();
      _channel = null;
    }

    return result;
  }

  void sendToHost(String text) {
    _channel?.sink.add(jsonEncode({'type': msgTypeMessage, 'text': text}));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _messagesController.close();
  }
}
