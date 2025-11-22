import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/ai_model.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;
  AIModel _currentModel = AIModels.availableModels.first; // Default to GPT-4o

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  AIModel get currentModel => _currentModel;

  void setModel(AIModel model) {
    _currentModel = model;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final userMessage = Message(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);
    _setLoading(true);

    try {
      final responseText = await AIService.generateResponse(text, _currentModel.id);
      
      final botMessage = Message(
        id: const Uuid().v4(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        modelName: _currentModel.name,
      );
      _addMessage(botMessage);
    } catch (e) {
      _addErrorMessage("Error: ${e.toString()}");
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
