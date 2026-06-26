import 'package:flutter/material.dart';

import 'join_connect_screen.dart';

class JoinNameScreen extends StatefulWidget {
  const JoinNameScreen({super.key});

  @override
  State<JoinNameScreen> createState() => _JoinNameScreenState();
}

class _JoinNameScreenState extends State<JoinNameScreen> {
  final _controller = TextEditingController();

  void _next() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => JoinConnectScreen(playerName: name)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join — Your Name')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder()),
              onSubmitted: (_) => _next(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _next, child: const Text('Next')),
            ),
          ],
        ),
      ),
    );
  }
}
