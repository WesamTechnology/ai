import 'package:http/http.dart' as http;

class AIService {
  /// Sends a prompt to the Pollinations AI API with the specified model.
  /// Returns the generated text response.
  static Future<String> generateResponse(String prompt, String modelId) async {
    try {
      // Construct the URL with the model parameter
      // Pollinations supports model selection via URL parameter ?model=
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
}
