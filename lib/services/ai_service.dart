import 'package:http/http.dart' as http;
import 'dart:math';

class AIService {
  /// Sends a prompt to the Pollinations AI API with the specified model.
  /// Returns the generated text response.
  static Future<String> generateResponse(String prompt, String modelId) async {
    try {
      final uri = Uri.parse('https://text.pollinations.ai/${Uri.encodeComponent(prompt)}?model=$modelId');
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to load response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to AI service: $e');
    }
  }

  /// Generates an image URL using Pollinations AI.
  /// Pollinations returns the image directly when accessing the URL.
  static String generateImageUrl(String prompt) {
    // Use a random seed to ensure unique images for the same prompt if retried
    final seed = Random().nextInt(1000000);
    final encodedPrompt = Uri.encodeComponent(prompt);
    // width and height can be adjusted, using 1024x1024 for high quality
    return 'https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&seed=$seed&nologo=true';
  }
}
