import 'dart:math';

import 'package:flutter/material.dart';

import '../server/host_server.dart';
import 'host_screen.dart';
import 'join_name_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rng = Random();
    return List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _startHosting(BuildContext context) async {
    final code = _generateRoomCode();
    final server = HostServer(roomCode: code);
    await server.start();
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => HostScreen(server: server)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mafia Local', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),
              SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _startHosting(context),
                  child: const Text('Host', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinNameScreen())),
                  child: const Text('Join', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
