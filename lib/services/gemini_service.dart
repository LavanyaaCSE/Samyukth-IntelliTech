import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  GeminiService();

  Future<String> _generateContent(String prompt, {String modelName = 'gemini-2.5-flash'}) async {
    try {
      final model = FirebaseVertexAI.instance.generativeModel(
        model: modelName, 
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        return response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      } else {
        return '{"error": "Empty response from AI"}';
      }
    } catch (e) {
      print("Vertex AI Error: $e");
      return '{"error": "AI Service Error: $e"}';
    }
  }

  Future<String> analyzeResume({String? text, List<int>? fileBytes, String? mimeType}) async {
    final prompt = """
    Analyze the following resume and provide a JSON response with the following structure:
    {
      "ats_score": 85, // Integer 0-100
      "key_improvements": ["Tip 1", "Tip 2", "Tip 3"],
      "keyword_suggestions": ["Keyword 1", "Keyword 2"],
      "short_summary": "One sentence summary"
    }
    
    Resume Text:
    $text
    """;
    return _generateContent(prompt);
  }

  Future<String> analyzeResumeWithJobDescription({required String resumeText, required String jobDescription}) async {
    final prompt = """
    Analyze the following resume against the provided Job Description (JD). 
    Provide a JSON response with the following structure:
    {
      "ats_score": 85, // Integer 0-100, representing the match percentage
      "key_improvements": ["Tip 1", "Tip 2"], // Specific suggestions to better match the JD
      "keyword_suggestions": ["Missing Keyword 1", "Missing Keyword 2"], // Keywords from JD missing in Resume
      "short_summary": "Brief assessment of the fit."
    }
    
    Job Description:
    $jobDescription

    Resume Text:
    $resumeText
    """;
    return _generateContent(prompt);
  }

  Future<String> generateInterviewQuestion(String mode, String topic, {String? jobDescription}) async {
    try {
      final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.5-flash');
      
      String prompt = "Generate a single professional and challenging interview question for a $mode interview context. The specific topic/role is $topic.";
      
      if (jobDescription != null && jobDescription.isNotEmpty) {
        prompt += "\n\nUse the following Job Description to tailor the question:\n$jobDescription";
      }
      
      prompt += "\n\nReturn ONLY the question text without any markdown or quotes.";
      
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "Could not generate question.";
    } catch (e) {
      return "Error generating question: $e";
    }
  }

  Future<String> evaluateInterviewResponse(String question, String answer) async {
    final prompt = """
    You are an expert interviewer. Evaluate the candidate's answer to the following question.
    
    Question: $question
    Answer: $answer
    
    Provide the response in raw JSON format with the following structure:
    {
      "rating": 7, // Integer 1-10
      "feedback": "Constructive feedback on what was good and what was missing.",
      "improved_answer": "An example of a stronger answer."
    }
    """;
    return _generateContent(prompt);
  }
}
