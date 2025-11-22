import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';
import '../models/ai_model.dart';
import '../models/chat_session.dart';
import '../services/ai_service.dart';

class ChatController extends GetxController {
  // Current Chat State
  var messages = <Message>[].obs;
  var isLoading = false.obs;
  var isListening = false.obs;
  var currentModel = AIModels.availableModels.first.obs;
  var currentSessionId = "".obs;

  // Sessions History
  var sessions = <ChatSession>[].obs;
  
  // Local Storage
  final storage = GetStorage();
  late stt.SpeechToText _speech;

  @override
  void onInit() {
    super.onInit();
    _speech = stt.SpeechToText();
    _loadSessionsFromStorage();
    
    // If no sessions exist, start a new one.
    // Otherwise, don't auto-load (or load the last one if you prefer).
    if (sessions.isEmpty) {
      startNewChat();
    } else {
      // Start a new chat by default so user sees a fresh screen,
      // but history is available in the drawer.
      startNewChat();
    }
  }

  void _loadSessionsFromStorage() {
    List<dynamic>? storedSessions = storage.read<List<dynamic>>('sessions');
    if (storedSessions != null) {
      sessions.value = storedSessions
          .map((e) => ChatSession.fromJson(e))
          .toList();
    }
  }

  void _saveSessionsToStorage() {
    storage.write('sessions', sessions.map((e) => e.toJson()).toList());
  }

  void startNewChat() {
    if (messages.isNotEmpty && currentSessionId.isNotEmpty) {
      _saveCurrentSession();
    }
    
    currentSessionId.value = const Uuid().v4();
    messages.clear();
  }

  void loadSession(ChatSession session) {
    if (messages.isNotEmpty) {
      _saveCurrentSession();
    }
    
    currentSessionId.value = session.id;
    messages.assignAll(session.messages);
    Get.back(); // Close drawer
  }
  
  void _saveCurrentSession() {
    if (messages.isEmpty) return;

    final existingIndex = sessions.indexWhere((s) => s.id == currentSessionId.value);
    
    // Generate a simple title from the first user message
    String title = "New Chat";
    final firstUserMsg = messages.firstWhereOrNull((m) => m.isUser);
    if (firstUserMsg != null) {
      title = firstUserMsg.text.length > 20 
          ? "${firstUserMsg.text.substring(0, 20)}..." 
          : firstUserMsg.text;
    }

    final session = ChatSession(
      id: currentSessionId.value,
      title: title,
      messages: List.from(messages),
      lastModified: DateTime.now(),
    );

    if (existingIndex >= 0) {
      sessions[existingIndex] = session;
    } else {
      sessions.insert(0, session);
    }
    
    // Persist to storage
    _saveSessionsToStorage();
  }

  void deleteSession(String id) {
    sessions.removeWhere((s) => s.id == id);
    _saveSessionsToStorage(); // Update storage
    
    if (currentSessionId.value == id) {
      startNewChat();
    }
  }

  void setModel(AIModel model) {
    currentModel.value = model;
    Get.back(); // Close bottom sheet
    Get.snackbar(
      "Model Changed",
      "Switched to ${model.name}",
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);
    isLoading.value = true;

    try {
      if (currentModel.value.isImageGenerator) {
        await _generateImage(text);
      } else {
        await _generateText(text);
      }
      // Auto-save session after each exchange
      _saveCurrentSession();
    } catch (e) {
      _addErrorMessage("Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _generateText(String prompt) async {
    final responseText = await AIService.generateResponse(prompt, currentModel.value.id);
    final botMessage = Message(
      id: const Uuid().v4(),
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      modelName: currentModel.value.name,
    );
    _addMessage(botMessage);
  }

  Future<void> _generateImage(String prompt) async {
    final imageUrl = AIService.generateImageUrl(prompt);
    final botMessage = Message(
      id: const Uuid().v4(),
      text: "Here is your image for: \"$prompt\"",
      isUser: false,
      timestamp: DateTime.now(),
      modelName: currentModel.value.name,
      imageUrl: imageUrl,
    );
    _addMessage(botMessage);
  }

  Future<void> startListening(Function(String) onResult) async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
       Get.snackbar("Permission Denied", "Microphone access is required.");
       return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') isListening.value = false;
      },
      onError: (errorNotification) {
        isListening.value = false;
        // Get.snackbar("Voice Error", errorNotification.errorMsg);
      },
    );

    if (available) {
      isListening.value = true;
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            isListening.value = false;
            onResult(result.recognizedWords);
          }
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
    isListening.value = false;
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
    messages.insert(0, message);
  }
  
  void clearChat() {
    messages.clear();
    _saveCurrentSession(); // Updates the session to empty
  }
}
