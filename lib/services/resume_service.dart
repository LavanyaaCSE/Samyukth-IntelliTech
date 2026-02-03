
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resume_analysis.dart';

final resumeServiceProvider = Provider<ResumeService>((ref) {
  return ResumeService();
});

class ResumeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'intellitrain',
  );

  CollectionReference get _usersCollection => _firestore.collection('users');

  // Save Analysis Result
  Future<void> saveAnalysis({
    required String userId,
    required Map<String, dynamic> analysisData,
    required String fileName,
    required String type,
    String? jobDescription,
  }) async {
    try {
      final analysisDoc = _usersCollection
          .doc(userId)
          .collection('resume_history')
          .doc();

      final analysisModel = ResumeAnalysis(
        id: analysisDoc.id,
        userId: userId,
        fileName: fileName,
        score: (analysisData['ats_score'] ?? 0).toDouble(),
        summary: analysisData['short_summary'] ?? 'No summary provided',
        improvements: List<String>.from(analysisData['key_improvements'] ?? []),
        keywords: List<String>.from(analysisData['keyword_suggestions'] ?? []),
        type: type,
        timestamp: DateTime.now(),
        jobDescription: jobDescription,
      );

      await analysisDoc.set(analysisModel.toMap());
    } catch (e) {
      print('Error saving resume analysis: $e');
      throw e;
    }
  }

  // Get User History
  Stream<List<ResumeAnalysis>> getUserHistory(String userId, {String? type}) {
    return _usersCollection
        .doc(userId)
        .collection('resume_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final allDocs = snapshot.docs.map((doc) {
        return ResumeAnalysis.fromMap(doc.data(), doc.id);
      }).toList();

      if (type != null) {
        return allDocs.where((analysis) => analysis.type == type).toList();
      }
      return allDocs;
    });
  }

  // Delete Analysis
  Future<void> deleteAnalysis(String userId, String analysisId) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('resume_history')
          .doc(analysisId)
          .delete();
    } catch (e) {
      print('Error deleting analysis: $e');
      throw e;
    }
  }
}
