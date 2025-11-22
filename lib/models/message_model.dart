class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? modelName; // To show which AI answered

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.modelName,
  });
}
