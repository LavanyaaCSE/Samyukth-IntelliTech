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
      "keyword_suggestions": ["Keyword to ADD 1", "Keyword to ADD 2"],
      "extracted_skills": ["Actual Skill 1", "Actual Skill 2"],
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
      "keyword_suggestions": ["Missing Keyword from JD 1"], // Keywords from JD missing in Resume
      "extracted_skills": ["Actual Skill Found 1", "Actual Skill Found 2"], // Core skills found in resume
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

  Future<String> generateWeeklyPlan({
    required List<Map<String, dynamic>> interviewHistory,
    required List<Map<String, dynamic>> assessmentHistory,
    required List<Map<String, dynamic>> resumeAnalyses,
    bool isNewUser = false,
  }) async {
    final prompt = """
    You are a career coach. Create a personalized weekly improvement plan for a job candidate.

    DETERMINING PROGRESS:
    - If isNewUser is true: The user has no history. Assign a baseline progress of 15% (0.15) for all items to reflect that they are starting their preparation journey.
    - If history is available: Calculate progress (0.0 to 1.0) based on their average scores and feedback.

    Plan Requirements:
    - Exactly 3 items (Mock Interviews, Test Assessments, Resume Improvement).
    - Very short, crisp titles (2-3 words).
    
    Data Inputs:
    - isNewUser: $isNewUser
    - Interview Data: $interviewHistory
    - Assessment Data: $assessmentHistory
    - Resume Data: $resumeAnalyses

    INSTRUCTIONS:
    - Item 1 (Category: 'behavioral'): Focus on feedback from recent interviews.
    - Item 2 (Category: 'technical'): Focus on low assessment categories or technical gaps.
    - Item 3 (Category: 'resume'): Focus on missing keywords or resume improvements.
    - PROGRESS CALCULATION: If the user has NO history in a category, start them at 10% (0.1) progress. If they have some history but need improvement, set progress between 30% (0.3) and 60% (0.6). Only set >80% if they are performing exceptionally well.
    
    Provide the response in raw JSON format:
    {
      "plan": [
        {
          "title": "Interview Skills",
          "subtitle": "Specific task based on interview feedback",
          "progress": 0.15, // Example: Starting progress for a new goal
          "category": "behavioral"
        },
        ...
      ]
    }
    """;
    return _generateContent(prompt);
  }

  Future<String> generatePlanDeepDive({
    required String title,
    required String subtitle,
    required String category,
    required String contextData,
  }) async {
    final prompt = """
    You are a career coach. Provide a detailed deep-dive for this specific improvement goal:
    Goal: $title
    Current Focus: $subtitle
    Category: $category

    Historical Context:
    $contextData

    INSTRUCTIONS:
    - Use markdown **bolding** for key terms or topics to make them stand out.
    
    Provide a JSON response with:
    {
      "weakness_analysis": "A detailed explanation of why this is a weakness based on the data.",
      "how_to_improve": ["Step 1...", "Step 2...", "Step 3..."],
      "recommended_resources": ["Resource 1", "Resource 2"],
      "estimated_time": "e.g., 2 hours"
    }
    """;
    return _generateContent(prompt);
  }

  Future<String> generateJobRoadmap({required String jobTitle, required List<String> jobSkills}) async {
    final prompt = """
    You are a career consultant. Create a detailed preparation roadmap for someone aiming to become a $jobTitle.
    The core skills required for this role are: ${jobSkills.join(', ')}.

    Provide a JSON response with the following structure:
    {
      "milestones": [
        {
          "title": "Phase 1: Fundamentals",
          "tasks": ["Master Skill X", "Learn Concept Y"],
          "resources": ["Resource 1", "Resource 2"]
        },
        ...
      ],
      "estimated_timeline": "e.g., 3-6 months",
      "pro_tip": "A specific piece of advice for this role"
    }
    
    Ensure the roadmap is action-oriented and structured sequentially.
    """;
    return _generateContent(prompt);
  }
}
