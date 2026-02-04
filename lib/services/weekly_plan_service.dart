
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'interview_service.dart';
import 'assessment_service.dart';
import 'resume_service.dart';
import 'gemini_service.dart';

final weeklyPlanProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return [];

  // Fetch recent data for analysis
  final interviewSessions = await ref.read(interviewServiceProvider).getUserHistory(user.uid).first;
  final assessmentHistory = await ref.read(assessmentServiceProvider).getUserResults(user.uid).first;
  final resumeHistory = await ref.read(resumeServiceProvider).getUserHistory(user.uid).first;

  // Prepare Granular Interview Data
  final recentInterviews = interviewSessions.take(3).map((s) => {
    'mode': s.mode,
    'type': s.isVoice ? 'Voice' : 'Text',
    'score': s.averageScore,
    'timestamp': s.timestamp.toIso8601String(),
    // Include last feedback for context if available
    'feedback': s.questionsAndAnswers.isNotEmpty 
        ? s.questionsAndAnswers.last['feedback'] 
        : 'No specific feedback yet'
  }).toList();

  // Prepare Granular Assessment Data
  final recentAssessments = assessmentHistory.take(3).map((r) => {
    'title': r.assessmentTitle,
    'category': r.category,
    'score': r.scorePercentage,
    'total': r.totalQuestions,
    'correct': r.correctCount
  }).toList();

  // Prepare Granular Resume Data
  final recentResumes = resumeHistory.take(1).map((r) => {
    'score': r.score,
    'missingKeywords': r.keywords,
    'topImprovements': r.improvements.take(3).toList(),
    'type': r.type
  }).toList();

  final isNewUser = recentInterviews.isEmpty && recentAssessments.isEmpty && recentResumes.isEmpty;

  try {
    final aiResponse = await ref.read(geminiServiceProvider).generateWeeklyPlan(
      interviewHistory: recentInterviews,
      assessmentHistory: recentAssessments,
      resumeAnalyses: recentResumes,
      isNewUser: isNewUser,
    );

    final decoded = json.decode(aiResponse);
    return List<Map<String, dynamic>>.from(decoded['plan'] ?? []);
  } catch (e) {
    print('Error generating weekly plan: $e');
    // Fallback static plan if AI fails
    return [
      {
        'title': 'Interview Prep',
        'subtitle': 'Complete one mock technical interview',
        'progress': 0.4,
        'category': 'behavioral'
      },
      {
        'title': 'Skill Assessment',
        'subtitle': 'Take a Quant/Logical assessment',
        'progress': 0.6,
        'category': 'technical'
      },
      {
        'title': 'Resume Update',
        'subtitle': 'Improve keywords matching your target role',
        'progress': 0.8,
        'category': 'resume'
      }
    ];
  }
});
