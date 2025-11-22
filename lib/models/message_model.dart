class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? modelName;
  final String? imageUrl; // New field for generated image URL

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.modelName,
    this.imageUrl,
  });
}
