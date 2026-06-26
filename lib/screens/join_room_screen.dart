import 'dart:async';

import 'package:flutter/material.dart';

import '../client/room_client.dart';
import '../protocol/message.dart';

class JoinRoomScreen extends StatefulWidget {
  final RoomClient client;
  final String roomCode;
  final String playerName;

  const JoinRoomScreen({
    super.key,
    required this.client,
    required this.roomCode,
    required this.playerName,
  });

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final List<ChatMessage> _log = [];
  final _scrollController = ScrollController();
  late final StreamSubscription<ChatMessage> _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.client.messages.listen((msg) {
      setState(() => _log.add(msg));
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    const text = 'Hello Host! This is a test message.';
    widget.client.sendToHost(text);
    setState(() => _log.add(ChatMessage(from: widget.playerName, text: text)));
    _scrollToBottom();
  }

  @override
  void dispose() {
    _sub.cancel();
    widget.client.disconnect();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomCode}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _log.length,
              itemBuilder: (_, i) {
                final msg = _log[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    msg.isSystem ? '— ${msg.text} —' : '[${msg.from}] ${msg.text}',
                    style: TextStyle(
                      color: msg.isSystem ? Colors.grey : null,
                      fontStyle: msg.isSystem ? FontStyle.italic : null,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendMessage,
                child: const Text('Send Message to Host'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
