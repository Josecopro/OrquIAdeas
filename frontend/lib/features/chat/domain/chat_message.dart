enum Author { user, assistant }

class ChatMessage {
  ChatMessage({
    required this.author,
    required this.text,
    required this.timestamp,
  });

  final Author author;
  final String text;
  final DateTime timestamp;
}
