import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/assessment.dart';

class AssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'intellitrain',
  );

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
}
