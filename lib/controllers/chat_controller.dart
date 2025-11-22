import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';
import '../models/ai_model.dart';
import '../services/ai_service.dart';

class ChatController extends GetxController {
  var messages = <Message>[].obs;
  var isLoading = false.obs;
  var isListening = false.obs;
  var currentModel = AIModels.availableModels.first.obs;
  
  late stt.SpeechToText _speech;

  @override
  void onInit() {
    super.onInit();
    _speech = stt.SpeechToText();
  }

  void setModel(AIModel model) {
    currentModel.value = model;
    // Show a snackbar using Get
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
    // Pollinations image generation is URL-based, so we assume success if we build the URL.
    // In a real app, you might want to pre-fetch to check validity, but for now we display directly.
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
       Get.snackbar("Permission Denied", "Microphone access is required for voice input.");
       return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') isListening.value = false;
      },
      onError: (errorNotification) {
        isListening.value = false;
        Get.snackbar("Voice Error", errorNotification.errorMsg);
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
  }
}
