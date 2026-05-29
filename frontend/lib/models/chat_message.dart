class ChatMessage {
  final String text;
  final bool isUser;
  final bool isFallback;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isFallback = false,
  });
}