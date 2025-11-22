import 'message_model.dart';

class ChatSession {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime lastModified;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.lastModified,
  });

  // JSON Serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'lastModified': lastModified.toIso8601String(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'],
    title: json['title'],
    messages: (json['messages'] as List).map((m) => Message.fromJson(m)).toList(),
    lastModified: DateTime.parse(json['lastModified']),
  );
}
