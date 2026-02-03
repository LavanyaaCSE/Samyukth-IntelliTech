import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_constants.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: AppConstants.geminiApiKey);
});

class GeminiService {
  final String apiKey;
  late final GenerativeModel model;

  GeminiService({required this.apiKey}) {
    model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> analyzeResume(String resumeText) async {
    final prompt = "Analyze the following resume and provide an ATS score (0-100), key improvements, and keyword suggestions. Format: JSON. Resume: $resumeText";
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? "Error analyzing resume";
  }

  Future<String> generateInterviewQuestion(String mode, String topic) async {
    final prompt = "Generate a $mode interview question about $topic. Provide only the question text.";
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? "Error generating question";
  }

  Future<String> evaluateInterviewResponse(String question, String answer) async {
    final prompt = "Evaluate the following interview response for question: '$question'. Answer: '$answer'. Provide feedback on clarity, technical accuracy, and areas of improvement.";
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? "Error evaluating response";
  }
}
