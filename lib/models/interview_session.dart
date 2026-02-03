
import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewSession {
  final String id;
  final String userId;
  final String mode; // HR, Technical, Managerial
  final String topic;
  final double averageScore;
  final List<Map<String, dynamic>> questionsAndAnswers;
  final DateTime timestamp;
  final bool isVoice;

  InterviewSession({
    required this.id,
    required this.userId,
    required this.mode,
    required this.topic,
    required this.averageScore,
    required this.questionsAndAnswers,
    required this.timestamp,
    this.isVoice = false,
  });

  factory InterviewSession.fromMap(Map<String, dynamic> data, String documentId) {
    return InterviewSession(
      id: documentId,
      userId: data['userId'] ?? '',
      mode: data['mode'] ?? 'Unknown',
      topic: data['topic'] ?? 'General',
      averageScore: (data['averageScore'] ?? 0).toDouble(),
      questionsAndAnswers: List<Map<String, dynamic>>.from(data['questionsAndAnswers'] ?? []),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVoice: data['isVoice'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mode': mode,
      'topic': topic,
      'averageScore': averageScore,
      'questionsAndAnswers': questionsAndAnswers,
      'timestamp': Timestamp.fromDate(timestamp),
      'isVoice': isVoice,
    };
  }
}
