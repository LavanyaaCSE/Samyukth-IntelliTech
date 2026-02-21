
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/app_colors.dart';
import '../../services/gemini_service.dart';
import '../../services/resume_service.dart';
import '../../services/job_service.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart'; // To access resumeHistoryProvider

import '../../models/job.dart';
import 'job_roadmap_screen.dart';


class JobMatchesScreen extends ConsumerStatefulWidget {
  const JobMatchesScreen({super.key});

  @override
  ConsumerState<JobMatchesScreen> createState() => _JobMatchesScreenState();
}

class _JobMatchesScreenState extends ConsumerState<JobMatchesScreen> {
  bool _isAnalyzing = false;

  Future<void> _pickAndAnalyzeResume() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() => _isAnalyzing = true);

        final fileName = result.files.single.name;
        String? extractedText;
        List<int>? fileBytes = result.files.single.bytes;
        
        // 1. Extract text (Non-web only)
        if (!kIsWeb && result.files.single.path != null) {
          try {
            extractedText = await ReadPdfText.getPDFtext(result.files.single.path!);
          } catch (e) {
            print('Local text extraction failed: $e');
          }
        }

        // 2. AI Analysis (Supporting direct PDF upload)
        String jsonString = await ref.read(geminiServiceProvider).analyzeResume(
          text: extractedText,
          fileBytes: fileBytes,
          mimeType: 'application/pdf',
        );

        final decoded = jsonDecode(jsonString);
        if (decoded is Map && decoded.containsKey('error')) throw decoded['error'];

        // 3. Save Analysis
        await ref.read(resumeServiceProvider).saveAnalysis(
          userId: user.uid,
          analysisData: decoded as Map<String, dynamic>,
          fileName: fileName,
          type: 'general',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume updated! Finding best matches...'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text("Please login to see matches")));


    final resumes = ref.watch(resumeHistoryProvider(user.uid)).value ?? [];
    final latestGeneralResume = resumes.where((r) => r.type == 'general').firstOrNull ?? resumes.firstOrNull;
    final allJobs = ref.watch(jobsStreamProvider).value ?? [];
    final matchedJobs = ref.watch(jobServiceProvider).getMatchedJobs(latestGeneralResume, allJobs);
    final bool isTrendingOnly = matchedJobs.any((j) => j['isTrending'] == true);


    return Scaffold(
      appBar: AppBar(
        title: Text('Job Matches', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (isTrendingOnly && !_isAnalyzing)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Showing trending jobs. Upload your resume for personalized 1-on-1 matches!',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickAndAnalyzeResume,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Analyze My Resume'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),
              
              if (!isTrendingOnly && !_isAnalyzing)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Perfect Matches for You',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _pickAndAnalyzeResume,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Update Resume', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: matchedJobs.isEmpty && !_isAnalyzing
                    ? Center(child: Text('No jobs found.', style: GoogleFonts.outfit()))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: matchedJobs.length,
                        itemBuilder: (context, index) {
                          final matchedData = matchedJobs[index];
                          final bool isTrending = matchedData['isTrending'] ?? false;
                          final double score = matchedData['matchScore'] ?? 0.0;
                          
                          return _buildJobCard(matchedData, isTrending, score, index);

                        },
                      ),
              ),
            ],
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'AI is Analyzing your Resume...',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Extracting skills to find the perfect job.',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> matchedData, bool isTrending, double score, int index) {
    final job = matchedData['job'] as Job;
    final skills = matchedData['skills'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTrending ? AppColors.accent.withOpacity(0.3) : AppColors.border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isTrending ? AppColors.accent : AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTrending ? 'Trending' : '${score.toInt()}% Match',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isTrending ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          if (matchedData['recommendationReason'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.stars, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    matchedData['recommendationReason'],
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          Text(
            'Core Skills:',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                skill,
                style: GoogleFonts.outfit(fontSize: 12),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobRoadmapScreen(
                      jobTitle: job.title,
                      jobSkills: skills.map((s) => s.toString()).toList(),
                    ),
                  ),

                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isTrending ? AppColors.accent : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Learn More'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }
}
