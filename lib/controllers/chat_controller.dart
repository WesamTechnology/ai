import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
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
  
  // Reply State
  var replyToMessage = Rxn<Message>(); // The message currently being replied to

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
    if (sessions.isEmpty) {
      startNewChat();
    } else {
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
    replyToMessage.value = null;
  }

  void loadSession(ChatSession session) {
    if (messages.isNotEmpty) {
      _saveCurrentSession();
    }
    
    currentSessionId.value = session.id;
    messages.assignAll(session.messages);
    replyToMessage.value = null;
    Get.back();
  }
  
  void _saveCurrentSession() {
    if (messages.isEmpty) return;

    final existingIndex = sessions.indexWhere((s) => s.id == currentSessionId.value);
    
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
    
    _saveSessionsToStorage();
  }

  void deleteSession(String id) {
    sessions.removeWhere((s) => s.id == id);
    _saveSessionsToStorage();
    if (currentSessionId.value == id) {
      startNewChat();
    }
  }

  void setModel(AIModel model) {
    currentModel.value = model;
    Get.back();
    Get.snackbar(
      "Model Changed",
      "Switched to ${model.name}",
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
    );
  }

  // Reply Logic
  void setReplyMessage(Message message) {
    replyToMessage.value = message;
  }

  void cancelReply() {
    replyToMessage.value = null;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Include context if replying
    String finalPrompt = text;
    String? replyContext;
    if (replyToMessage.value != null) {
      replyContext = "Replying to: \"${replyToMessage.value!.text}\"";
      finalPrompt = "Context: I am replying to this message: \"${replyToMessage.value!.text}\".\nMy Reply: $text";
    }

    final userMessage = Message(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      replyToText: replyToMessage.value?.text, // We need to add this field to model
    );
    
    _addMessage(userMessage);
    
    // Clear reply AFTER adding the message
    replyToMessage.value = null;
    
    isLoading.value = true;

    try {
      if (currentModel.value.isImageGenerator) {
        await _generateImage(text);
      } else {
        await _generateText(finalPrompt);
      }
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

  // Utilities
  Future<void> saveImage(String imageUrl) async {
    try {
      // Request storage permission
      if (!await Gal.hasAccess()) {
         await Gal.requestAccess();
      }

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/image_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      // Save to Gallery
      await Gal.putImage(file.path);
      
      Get.snackbar("Success", "Image saved to Gallery!", backgroundColor: Get.theme.colorScheme.secondaryContainer);
    } catch (e) {
      Get.snackbar("Error", "Failed to save image: $e", backgroundColor: Get.theme.colorScheme.errorContainer);
    }
  }

  void copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar("Copied", "Text copied to clipboard", duration: const Duration(seconds: 1));
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
    replyToMessage.value = null;
    _saveCurrentSession();
  }
}
