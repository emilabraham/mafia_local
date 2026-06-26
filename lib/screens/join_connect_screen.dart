import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../client/room_client.dart';
import 'join_room_screen.dart';

class JoinConnectScreen extends StatefulWidget {
  final String playerName;
  const JoinConnectScreen({super.key, required this.playerName});

  @override
  State<JoinConnectScreen> createState() => _JoinConnectScreenState();
}

class _JoinConnectScreenState extends State<JoinConnectScreen> {
  final _ipController = TextEditingController();
  final _codeController = TextEditingController();
  bool _connecting = false;

  Future<void> _join() async {
    final ip = _ipController.text.trim();
    final code = _codeController.text.trim().toUpperCase();

    if (ip.isEmpty || code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid IP and 4-letter room code')),
      );
      return;
    }

    setState(() => _connecting = true);

    final client = RoomClient();
    final error = await client.connect(ip, code, widget.playerName);

    if (!mounted) return;
    setState(() => _connecting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinRoomScreen(client: client, roomCode: code, playerName: widget.playerName),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join — Connect')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Host IP address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                _UpperCaseFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'Room code (4 letters)', border: OutlineInputBorder()),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _connecting ? null : _join,
                child: _connecting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
