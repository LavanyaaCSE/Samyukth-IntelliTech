import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assessment.dart';
import '../models/assessment_result.dart';
import '../models/upcoming_test.dart';

final assessmentServiceProvider = Provider<AssessmentService>((ref) {
  return AssessmentService();
});

class AssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'intellitrain',
  );

  CollectionReference get _usersCollection => _firestore.collection('users');

  // Save assessment result
  Future<void> saveResult(AssessmentResult result) async {
    try {
      await _usersCollection
          .doc(result.userId)
          .collection('assessment_history')
          .doc(result.id)
          .set(result.toMap());
    } catch (e) {
      print('Error saving assessment result: $e');
      throw e;
    }
  }

  // Get user assessment history
  Stream<List<AssessmentResult>> getUserResults(String userId, {String? category}) {
    var query = _usersCollection
        .doc(userId)
        .collection('assessment_history')
        .orderBy('timestamp', descending: true);
    
    return query.snapshots().map((snapshot) {
      final results = snapshot.docs.map((doc) {
        return AssessmentResult.fromMap(doc.data(), doc.id);
      }).toList();

      if (category != null && category != 'All') {
        return results.where((r) => r.category == category).toList();
      }
      return results;
    });
  }

  Stream<double> getAverageScore(String userId) {
    return getUserResults(userId).map((results) {
      if (results.isEmpty) return 0.0;
      final total = results.fold<double>(0, (sum, r) => sum + r.scorePercentage);
      return total / results.length;
    });
  }

  // Fetch all assessments from Firestore
  // Questions are managed via the admin panel
  Stream<List<Assessment>> getAssessments() {
    return _firestore.collection('assessments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Parse Questions from the 'questions' list in the document
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

        return Assessment(
          id: doc.id,
          title: data['title'] ?? 'Untitled Test',
          durationMinutes: data['durationMinutes'] ?? 0,
          category: data['category'] ?? 'General',
          questions: questions,
        );
      }).toList();
    });
  }

  // Fetch upcoming scheduled tests
  Stream<List<UpcomingTest>> getUpcomingTests() {
    return _firestore
        .collection('upcoming_tests')
        .snapshots()
        .map((snapshot) {
      final tests = snapshot.docs
          .map((doc) => UpcomingTest.fromMap(doc.data(), doc.id))
          .where((test) => test.isPublished) // Filter in-memory
          .toList();
          
      // Sort in-memory
      tests.sort((a, b) => a.startTime.compareTo(b.startTime));
      return tests;
    });
  }
}
