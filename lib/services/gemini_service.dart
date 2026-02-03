import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_constants.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: AppConstants.geminiApiKey);
});

class GeminiService {
  final String apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  GeminiService({required this.apiKey});

  Future<String> analyzeResume({String? text, List<int>? fileBytes, String? mimeType}) async {
    final promptText = """
    Analyze the following resume and provide a JSON response with the following structure:
    {
      "ats_score": 85, // Integer 0-100
      "key_improvements": ["Tip 1", "Tip 2", "Tip 3"],
      "keyword_suggestions": ["Keyword 1", "Keyword 2"],
      "short_summary": "One sentence summary"
    }
    
    Do not include markdown formatting. Just return the raw JSON string.
    """;

    // List of configuration to try (Prioritizing 2026 models)
    final configs = [
      {'name': 'gemini-2.5-flash-lite', 'version': 'v1beta'},
      {'name': 'gemini-2.5-flash', 'version': 'v1beta'},
      {'name': 'gemini-2.0-flash', 'version': 'v1beta'},
      {'name': 'gemini-2.0-pro', 'version': 'v1beta'},
      {'name': 'gemini-1.5-flash', 'version': 'v1beta'}, // Fallback
    ];

    String lastError = "No models available";

    for (final config in configs) {
      final modelName = config['name']!;
      final version = config['version']!;

      try {
        final url = Uri.parse('https://generativelanguage.googleapis.com/$version/models/$modelName:generateContent?key=$apiKey');
        
        final body = jsonEncode({
          "contents": [{
            "parts": [
              {"text": "$promptText\n\nResume Text:\n$text"}
            ]
          }]
        });

        print("🔄 Trying $modelName ($version)..."); 

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final candidates = jsonResponse['candidates'] as List;
          if (candidates.isNotEmpty) {
            final parts = candidates[0]['content']['parts'] as List;
            if (parts.isNotEmpty) {
              String result = parts[0]['text'];
              final cleanResult = result.replaceAll('```json', '').replaceAll('```', '').trim();
              print("✅ Success with $modelName ($version)");
              return cleanResult;
            }
          }
          return '{"error": "Empty response from AI"}';
        } else if (response.statusCode == 404) {
          print("⚠️ $modelName ($version) 404 Not Found. Checking next...");
          continue; 
        } else {
          lastError = "AI Error ${response.statusCode}: ${response.body}";
          print("❌ $lastError");
          return '{"error": "$lastError"}';
        }
      } catch (e) {
        lastError = "Network Error: $e";
        print("❌ $lastError");
      }
    }

    // If loop finishes without success
    return '{"error": "All endpoints failed (404). This usually means the Generative Language API is not enabled in your Google Cloud Console."}';
  }

  // Placeholder for other methods if needed (kept blank or simple to compile)
  Future<String> generateInterviewQuestion(String mode, String topic) async { return ""; }
  Future<String> evaluateInterviewResponse(String q, String a) async { return ""; }
}
