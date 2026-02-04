
import 'package:cloud_firestore/cloud_firestore.dart';

class ResumeAnalysis {
  final String id;
  final String userId;
  final String fileName;
  final double score;
  final String summary;
  final List<String> improvements;
  final List<String> keywords;
  final List<String> extractedSkills;
  final String type; // 'general' or 'job_match'
  final DateTime timestamp;
  final String? jobDescription;

  ResumeAnalysis({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.score,
    required this.summary,
    required this.improvements,
    required this.keywords,
    required this.extractedSkills,
    required this.type,
    required this.timestamp,
    this.jobDescription,
  });

  factory ResumeAnalysis.fromMap(Map<String, dynamic> data, String documentId) {
    return ResumeAnalysis(
      id: documentId,
      userId: data['userId'] ?? '',
      fileName: data['fileName'] ?? 'Unknown File',
      score: (data['ats_score'] ?? 0).toDouble(),
      summary: data['short_summary'] ?? '',
      improvements: List<String>.from(data['key_improvements'] ?? []),
      keywords: List<String>.from(data['keyword_suggestions'] ?? []),
      extractedSkills: List<String>.from(data['extracted_skills'] ?? []),
      type: data['type'] ?? 'general',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      jobDescription: data['jobDescription'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fileName': fileName,
      'ats_score': score,
      'short_summary': summary,
      'key_improvements': improvements,
      'keyword_suggestions': keywords,
      'extracted_skills': extractedSkills,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'jobDescription': jobDescription,
    };
  }
}
