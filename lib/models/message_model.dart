class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? modelName;
  final String? imageUrl;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.modelName,
    this.imageUrl,
  });

  // JSON Serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'modelName': modelName,
    'imageUrl': imageUrl,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    modelName: json['modelName'],
    imageUrl: json['imageUrl'],
  );
}
