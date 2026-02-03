
import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentResult {
  final String id;
  final String userId;
  final String assessmentId;
  final String assessmentTitle;
  final String category;
  final int correctCount;
  final int totalQuestions;
  final double scorePercentage;
  final Map<int, int> userAnswers; // questionIndex -> answerIndex
  final List<Map<String, dynamic>> questions; // Store question text and options for history
  final DateTime timestamp;

  AssessmentResult({
    required this.id,
    required this.userId,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.category,
    required this.correctCount,
    required this.totalQuestions,
    required this.scorePercentage,
    required this.userAnswers,
    required this.questions,
    required this.timestamp,
  });

  factory AssessmentResult.fromMap(Map<String, dynamic> data, String documentId) {
    final rawAnswers = data['userAnswers'] as Map<String, dynamic>? ?? {};
    final Map<int, int> convertedAnswers = {};
    rawAnswers.forEach((key, value) {
      convertedAnswers[int.parse(key)] = value as int;
    });

    return AssessmentResult(
      id: documentId,
      userId: data['userId'] ?? '',
      assessmentId: data['assessmentId'] ?? '',
      assessmentTitle: data['assessmentTitle'] ?? 'Unknown Test',
      category: data['category'] ?? 'General',
      correctCount: data['correctCount'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      scorePercentage: (data['scorePercentage'] ?? 0).toDouble(),
      userAnswers: convertedAnswers,
      questions: List<Map<String, dynamic>>.from(data['questions'] ?? []),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, int> stringAnswers = {};
    userAnswers.forEach((key, value) {
      stringAnswers[key.toString()] = value;
    });

    return {
      'userId': userId,
      'assessmentId': assessmentId,
      'assessmentTitle': assessmentTitle,
      'category': category,
      'correctCount': correctCount,
      'totalQuestions': totalQuestions,
      'scorePercentage': scorePercentage,
      'userAnswers': stringAnswers,
      'questions': questions,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
