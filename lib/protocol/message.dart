class ChatMessage {
  final String from;
  final String text;
  final bool isSystem;

  const ChatMessage({required this.from, required this.text, this.isSystem = false});
}

const String msgTypeJoin = 'join';
const String msgTypeJoinAck = 'join_ack';
const String msgTypeMessage = 'message';
const String msgTypePlayerJoined = 'player_joined';
