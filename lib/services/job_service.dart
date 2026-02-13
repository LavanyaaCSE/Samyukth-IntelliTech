

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job.dart';
import '../models/resume_analysis.dart';

final jobServiceProvider = Provider((ref) => JobService());

final jobsStreamProvider = StreamProvider<List<Job>>((ref) {
  return ref.watch(jobServiceProvider).getJobs();
});

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'intellitrain',
  );

  Stream<List<Job>> getJobs() {
    return _db
        .collection('jobs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList());
  }

  // Matching logic (keeping it for existing compatibility if needed, 
  // but updated to handle the new Job model if we want to use it for matching too)
  List<Map<String, dynamic>> getMatchedJobs(ResumeAnalysis? latestResume, List<Job> allJobs) {
    if (latestResume == null) {
      return allJobs.take(3).map((j) => {
        'title': j.title,
        'company': j.company,
        'skills': [], // New model doesn't explicitly have skills list in snippet, but we can extract from description
        'isTrending': true,
        'matchScore': 0.0,
        'job': j,
      }).toList();
    }
    
    final resumeSkills = latestResume.extractedSkills.map((k) => k.toLowerCase()).toList();
    final fallbackKeywords = latestResume.keywords.map((k) => k.toLowerCase()).toList();
    final allSearchTerms = [...resumeSkills, ...fallbackKeywords];
    
    List<Map<String, dynamic>> results = [];

    for (var job in allJobs) {
      // Basic matching in description and title
      int matches = 0;
      final textToSearch = "${job.title} ${job.description}".toLowerCase();
      
      for (var term in allSearchTerms) {
        if (textToSearch.contains(term)) {
          matches++;
        }
      }

      double matchScore = allSearchTerms.isNotEmpty ? (matches / allSearchTerms.length) * 100 : 0;
      
      if (matchScore >= 10) { // Lowered threshold for text-based matching
        results.add({
          'title': job.title,
          'company': job.company,
          'isTrending': false,
          'matchScore': matchScore,
          'job': job,
        });
      }
    }

    results.sort((a, b) => (b['matchScore'] as double).compareTo(a['matchScore'] as double));

    if (results.isEmpty) {
      return allJobs.take(3).map((j) => {
        'title': j.title,
        'company': j.company,
        'isTrending': true, 
        'matchScore': 0.0,
        'recommendationReason': 'Trending in your region',
        'job': j,
      }).toList();
    }

    return results;
  }
}

