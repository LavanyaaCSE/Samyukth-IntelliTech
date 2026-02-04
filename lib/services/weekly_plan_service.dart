
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'interview_service.dart';
import 'assessment_service.dart';
import 'resume_service.dart';
import 'gemini_service.dart';
import '../models/interview_session.dart';
import '../models/assessment_result.dart';
import '../models/resume_analysis.dart';

final weeklyPlanProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  // Watch streams for real-time updates
  final interviewAsync = ref.watch(interviewHistoryStreamProvider(user.uid));
  final assessmentAsync = ref.watch(assessmentResultsStreamProvider(user.uid));
  final resumeAsync = ref.watch(resumeHistoryStreamProvider(user.uid));

  // Handle loading state
  if (interviewAsync.isLoading || assessmentAsync.isLoading || resumeAsync.isLoading) {
    return []; // Handled by widget's CircularProgressIndicator
  }

  final interviewSessions = interviewAsync.value ?? [];
  final assessmentHistory = assessmentAsync.value ?? [];
  final resumeHistory = resumeAsync.value ?? [];

  // Calculate Real Performance Averages (0.0 to 1.0)
  double interviewAvg = 0.0;
  if (interviewSessions.isNotEmpty) {
    interviewAvg = interviewSessions.fold(0.0, (sum, s) => sum + s.averageScore) / (interviewSessions.length * 10);
  }

  double assessmentAvg = 0.0;
  if (assessmentHistory.isNotEmpty) {
    assessmentAvg = assessmentHistory.fold(0.0, (sum, r) => sum + r.scorePercentage) / (assessmentHistory.length * 100);
  }

  double resumeAvg = 0.0;
  if (resumeHistory.isNotEmpty) {
    resumeAvg = resumeHistory.first.score / 100;
  }

  // Debug logs
  debugPrint('DEBUG: Weekly Plan Calc -> Int: $interviewAvg, Ass: $assessmentAvg, Res: $resumeAvg');

  final isNewUser = interviewSessions.isEmpty && assessmentHistory.isEmpty && resumeHistory.isEmpty;

  try {
    final aiResponse = await ref.read(geminiServiceProvider).generateWeeklyPlan(
      interviewHistory: interviewSessions.take(3).map((s) => {'mode': s.mode, 'score': s.averageScore}).toList(),
      assessmentHistory: assessmentHistory.take(3).map((r) => {'title': r.assessmentTitle, 'score': r.scorePercentage}).toList(),
      resumeAnalyses: resumeHistory.take(1).map((r) => {'score': r.score}).toList(),
      isNewUser: isNewUser,
      currentScores: {
        'interview': interviewAvg,
        'assessment': assessmentAvg,
        'resume': resumeAvg,
      },
    );

    final Map<String, dynamic> decoded = json.decode(aiResponse);
    final List<dynamic> rawPlan = decoded['plan'] ?? [];
    
    // STRICT MAPPING: We take the AI's title/subtitle but FORCE our calculated progress
    final List<Map<String, dynamic>> finalPlan = [];
    
    for (var item in rawPlan) {
      final map = Map<String, dynamic>.from(item);
      final cat = map['category']?.toString().toLowerCase() ?? '';
      
      double progress = 0.0;
      if (cat.contains('behavioral') || cat.contains('interview')) {
        progress = interviewAvg;
      } else if (cat.contains('technical') || cat.contains('assessment') || cat.contains('test')) {
        progress = assessmentAvg;
      } else if (cat.contains('resume') || cat.contains('ats')) {
        progress = resumeAvg;
      }
      
      map['progress'] = progress.clamp(0.0, 1.0);
      if (progress == 0.0) {
        map['subtitle'] = 'Start now to see progress';
      }
      
      finalPlan.add(map);
    }
    
    return finalPlan;
  } catch (e) {
    debugPrint('Weekly Plan AI Error: $e');
    // Enhanced Fallback with real progress
    return [
      {
        'title': 'Interview Prep',
        'subtitle': interviewAvg > 0 ? 'Work on your communication clarity' : 'Start now to see progress',
        'progress': interviewAvg.clamp(0.0, 1.0),
        'category': 'behavioral'
      },
      {
        'title': 'Skill Assessment',
        'subtitle': assessmentAvg > 0 ? 'Master the core technical concepts' : 'Start now to see progress',
        'progress': assessmentAvg.clamp(0.0, 1.0),
        'category': 'technical'
      },
      {
        'title': 'Resume Update',
        'subtitle': resumeAvg > 0 ? 'Keywords matching could be better' : 'Start now to see progress',
        'progress': resumeAvg.clamp(0.0, 1.0),
        'category': 'resume'
      }
    ];
  }
});

final interviewHistoryStreamProvider = StreamProvider.family<List<InterviewSession>, String>((ref, userId) {
  return ref.watch(interviewServiceProvider).getUserHistory(userId);
});

final assessmentResultsStreamProvider = StreamProvider.family<List<AssessmentResult>, String>((ref, userId) {
  return ref.watch(assessmentServiceProvider).getUserResults(userId);
});

final resumeHistoryStreamProvider = StreamProvider.family<List<ResumeAnalysis>, String>((ref, userId) {
  return ref.watch(resumeServiceProvider).getUserHistory(userId);
});
