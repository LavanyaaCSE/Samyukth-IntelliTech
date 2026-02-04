
import 'package:cloud_firestore/cloud_firestore.dart';

import 'assessment.dart';

class UpcomingTest {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final List<String> topics;
  final List<Question> questions;
  final bool isPublished;

  UpcomingTest({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.topics,
    required this.questions,
    this.isPublished = true,
  });

  factory UpcomingTest.fromMap(Map<String, dynamic> data, String id) {
    List<Question> questions = [];
    if (data['questions'] != null) {
      questions = (data['questions'] as List).map((q) {
        return Question(
          id: q['id'] ?? '0',
          text: q['text'] ?? '',
          options: List<String>.from(q['options'] ?? []),
          correctOptionIndex: q['correctOptionIndex'] ?? 0,
          concept: q['concept'] ?? '',
          difficulty: q['difficulty'] ?? 'Medium',
          section: q['section'] ?? 'General',
        );
      }).toList();
    }

    return UpcomingTest(
      id: id,
      title: data['title'] ?? 'Scheduled Test',
      category: data['category'] ?? 'General',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 1)),
      durationMinutes: data['durationMinutes'] ?? 30,
      topics: List<String>.from(data['topics'] ?? []),
      questions: questions,
      isPublished: data['isPublished'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'topics': topics,
      'questions': questions.map((q) => {
        'id': q.id,
        'text': q.text,
        'options': q.options,
        'correctOptionIndex': q.correctOptionIndex,
        'concept': q.concept,
        'difficulty': q.difficulty,
        'section': q.section,
      }).toList(),
      'isPublished': isPublished,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}
