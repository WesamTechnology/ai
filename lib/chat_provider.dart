import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'message_model.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    // Add user message
    final userMessage = Message(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);
    _setLoading(true);

    try {
      // Using Pollinations.ai API which is free and requires no API key.
      // It usually returns direct text.
      final url = Uri.parse('https://text.pollinations.ai/${Uri.encodeComponent(text)}');
      
      // Adding a timeout to prevent hanging
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final botMessage = Message(
          id: const Uuid().v4(),
          text: response.body,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _addMessage(botMessage);
      } else {
        _addErrorMessage("Received error from server: ${response.statusCode}");
      }
    } catch (e) {
      _addErrorMessage("Could not connect to AI service. Please check your internet.");
    } finally {
      _setLoading(false);
    }
  }

  void _addErrorMessage(String errorText) {
    final errorMessage = Message(
      id: const Uuid().v4(),
      text: errorText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _addMessage(errorMessage);
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
