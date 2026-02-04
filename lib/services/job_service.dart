
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resume_analysis.dart';

final jobServiceProvider = Provider((ref) => JobService());

class JobService {
  // Mock job list representing available opportunities
  final List<Map<String, dynamic>> _mockJobs = [
    {
      'title': 'Flutter Developer', 
      'skills': ['flutter', 'dart', 'firebase', 'mobile'],
      'company': 'TechFlow'
    },
    {
      'title': 'Java Backend Engineer', 
      'skills': ['java', 'spring boot', 'mysql', 'microservices'],
      'company': 'CloudScale'
    },
    {
      'title': 'Frontend Developer', 
      'skills': ['react', 'javascript', 'typescript', 'css', 'html'],
      'company': 'WebLabs'
    },
    {
      'title': 'Python Data Analyst', 
      'skills': ['python', 'pandas', 'sql', 'tableau', 'machine learning'],
      'company': 'DataInsight'
    },
    {
      'title': 'DevOps Engineer', 
      'skills': ['docker', 'kubernetes', 'aws', 'ci/cd', 'linux'],
      'company': 'OpsMaster'
    },
    {
      'title': 'Full Stack Developer', 
      'skills': ['node.js', 'react', 'mongodb', 'express', 'javascript'],
      'company': 'CodeSync'
    },
    {
      'title': 'QA Automation Engineer', 
      'skills': ['selenium', 'testing', 'automation', 'java', 'python'],
      'company': 'QualityFirst'
    },
  ];

  List<Map<String, dynamic>> getMatchedJobs(ResumeAnalysis? latestResume) {
    // If no resume, return top trending jobs
    if (latestResume == null) {
      return _mockJobs.take(3).map((j) => {...j, 'isTrending': true, 'matchScore': 0.0}).toList();
    }
    
    final resumeSkills = latestResume.extractedSkills.map((k) => k.toLowerCase()).toList();
    final fallbackKeywords = latestResume.keywords.map((k) => k.toLowerCase()).toList();
    
    // Combine for maximum matching potential
    final allSearchTerms = [...resumeSkills, ...fallbackKeywords];
    List<Map<String, dynamic>> results = [];

    for (var job in _mockJobs) {
      final jobSkills = (job['skills'] as List<dynamic>).map((s) => s.toString().toLowerCase()).toList();
      
      int matchedCount = 0;
      for (var skill in jobSkills) {
        if (allSearchTerms.any((term) => term.contains(skill) || skill.contains(term))) {
          matchedCount++;
        }
      }

      double matchScore = jobSkills.isNotEmpty ? (matchedCount / jobSkills.length) * 100 : 0;
      
      if (matchScore >= 25) { // Threshold for a "match"
        results.add({
          ...job,
          'isTrending': false,
          'matchScore': matchScore,
        });
      }
    }

    // Sort matches by score
    results.sort((a, b) => (b['matchScore'] as double).compareTo(a['matchScore'] as double));

    // If no quality matches, provide trending recommendations
    if (results.isEmpty) {
      return _mockJobs.take(3).map((j) => {
        ...j, 
        'isTrending': true, 
        'matchScore': 0.0,
        'recommendationReason': 'Trending in your region'
      }).toList();
    }

    return results;
  }
}
