import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'message_model.dart';

class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  bool _isLoading = false;
  GenerativeModel? _model;
  final String _apiKey = ""; // TODO: Add your API Key here or use a mechanism to input it

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  void initModel(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (_model == null) {
      _addMessage(Message(
        id: const Uuid().v4(),
        text: "Please set your API Key first.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    final userMessage = Message(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);
    _setLoading(true);

    try {
      final content = [Content.text(text)];
      final response = await _model!.generateContent(content);

      final botMessage = Message(
        id: const Uuid().v4(),
        text: response.text ?? "No response from AI.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _addMessage(botMessage);
    } catch (e) {
      final errorMessage = Message(
        id: const Uuid().v4(),
        text: "Error: ${e.toString()}",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _addMessage(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  void _addMessage(Message message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
