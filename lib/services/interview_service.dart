
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interview_session.dart';

final interviewServiceProvider = Provider<InterviewService>((ref) {
  return InterviewService();
});

class InterviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'intellitrain',
  );

  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> saveSession(InterviewSession session) async {
    try {
      await _usersCollection
          .doc(session.userId)
          .collection('interview_history')
          .doc(session.id)
          .set(session.toMap());
    } catch (e) {
      print('Error saving interview session: $e');
      throw e;
    }
  }

  Stream<List<InterviewSession>> getUserHistory(String userId, {bool? isVoice}) {
    return _usersCollection
        .doc(userId)
        .collection('interview_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InterviewSession.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((session) => isVoice == null || session.isVoice == isVoice)
          .toList();
    });
  }

  Stream<Map<String, double>> getAverageScores(String userId, {bool? isVoice}) {
    return getUserHistory(userId).map((sessions) {
      final Map<String, List<double>> scores = {
        'HR Interview': [],
        'Technical Interview': [],
        'Managerial Interview': [],
      };

      for (var session in sessions) {
        // Filter by voice/text type if specified
        if (isVoice != null && session.isVoice != isVoice) {
          continue;
        }

        if (scores.containsKey(session.mode)) {
          scores[session.mode]!.add(session.averageScore);
        } else {
          // Handle custom or legacy modes if any
          scores.putIfAbsent(session.mode, () => []).add(session.averageScore);
        }
      }

      final Map<String, double> averages = {};
      scores.forEach((key, value) {
        if (value.isNotEmpty) {
          averages[key] = value.reduce((a, b) => a + b) / value.length;
        } else {
          averages[key] = 0.0;
        }
      });

      return averages;
    });
  }

  Stream<double> getOverallAverage(String userId) {
    return getAverageScores(userId).map((averages) {
      final validValues = averages.values.where((v) => v > 0).toList();
      if (validValues.isEmpty) return 0.0;
      return validValues.reduce((a, b) => a + b) / validValues.length;
    });
  }
}
