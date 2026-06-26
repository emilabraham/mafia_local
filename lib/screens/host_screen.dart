import 'dart:async';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../protocol/message.dart';
import '../server/host_server.dart';

class HostScreen extends StatefulWidget {
  final HostServer server;
  const HostScreen({super.key, required this.server});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  String _localIp = 'Loading…';
  final List<ChatMessage> _log = [];
  List<ConnectedPlayer> _players = [];
  final _scrollController = ScrollController();

  late final StreamSubscription<ChatMessage> _msgSub;
  late final StreamSubscription<List<ConnectedPlayer>> _playerSub;

  @override
  void initState() {
    super.initState();
    _fetchIp();
    _msgSub = widget.server.messages.listen((msg) {
      setState(() => _log.add(msg));
      _scrollToBottom();
    });
    _playerSub = widget.server.playerUpdates.listen((players) {
      setState(() => _players = players);
    });
  }

  Future<void> _fetchIp() async {
    final ip = await NetworkInfo().getWifiIP();
    setState(() => _localIp = ip ?? 'Unavailable');
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

  void _sendTestMessage(ConnectedPlayer player) {
    final text = 'Hello ${player.name}! This is a test message.';
    widget.server.sendTo(player.socket, {'type': msgTypeMessage, 'from': 'Host', 'text': text});
    setState(() => _log.add(ChatMessage(from: 'Host → ${player.name}', text: text)));
    _scrollToBottom();
  }

  void _broadcast() {
    const text = 'Hello everyone! This is a broadcast.';
    widget.server.broadcast({'type': msgTypeMessage, 'from': 'Host', 'text': text});
    setState(() => _log.add(const ChatMessage(from: 'Host (broadcast)', text: text)));
    _scrollToBottom();
  }

  @override
  void dispose() {
    _msgSub.cancel();
    _playerSub.cancel();
    widget.server.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hosting')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  const Text('Room Code', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(widget.server.roomCode, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4)),
                ]),
                Column(children: [
                  const Text('Your IP', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(_localIp, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
          const Divider(),
          if (_players.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Players', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            ..._players.map((p) => ListTile(
              dense: true,
              title: Text(p.name),
              trailing: TextButton(
                onPressed: () => _sendTestMessage(p),
                child: const Text('Send Test Message'),
              ),
            )),
            const Divider(),
          ],
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
                onPressed: _broadcast,
                child: const Text('Broadcast Message'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
