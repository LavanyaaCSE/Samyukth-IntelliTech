import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/gemini_service.dart';
import '../../services/resume_service.dart';
import '../../services/auth_service.dart';
import '../../models/resume_analysis.dart';
import 'resume_history_detail_screen.dart';

class ResumeScreen extends ConsumerStatefulWidget {
  const ResumeScreen({super.key});

  @override
  ConsumerState<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends ConsumerState<ResumeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  String? _fileName;
  final TextEditingController _jdController = TextEditingController();
  bool _isJdAnalysis = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _resetAnalysis();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jdController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyzeFile() async {
    // Validate JD if in Job Match mode
    if (_tabController.index == 1 && _jdController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a Job Description first.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _fileName = result.files.single.name;
        });

        final filePath = result.files.single.path!;
        
        // Extract text from PDF
        String extractedText = "";
        try {
          extractedText = await ReadPdfText.getPDFtext(filePath);
        } catch (e) {
          throw 'Failed to read PDF text. Make sure it is not password protected.';
        }

        if (extractedText.isEmpty) {
           throw 'Could not extract text from this PDF.';
        }

        // Call Gemini Service based on Tab Index
        String jsonString;
        final isJobMatch = _tabController.index == 1;
        if (isJobMatch) {
           // Job Match Mode
           jsonString = await ref.read(geminiServiceProvider).analyzeResumeWithJobDescription(
            resumeText: extractedText,
            jobDescription: _jdController.text.trim(),
          );
          _isJdAnalysis = true;
        } else {
           // General Mode
           jsonString = await ref.read(geminiServiceProvider).analyzeResume(
            text: extractedText,
          );
          _isJdAnalysis = false;
        }

        if (jsonString.startsWith('{') || jsonString.startsWith('[')) {
          final decoded = jsonDecode(jsonString);
          
          if (decoded is Map && decoded.containsKey('error')) {
            throw decoded['error'];
          }

          setState(() {
            _analysisResult = decoded;
          });

          // Save to Firestore
          final user = ref.read(authServiceProvider).currentUser;
          if (user != null) {
              await ref.read(resumeServiceProvider).saveAnalysis(
                userId: user.uid,
                analysisData: decoded as Map<String, dynamic>,
                fileName: _fileName ?? 'Unknown Resume',
                type: isJobMatch ? 'job_match' : 'general',
                jobDescription: isJobMatch ? _jdController.text.trim() : null,
              );
          }

        } else {
          throw 'Invalid response format';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'), backgroundColor: Colors.red),
        );
        _resetAnalysis(); // Reset on failure to allow retry
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetAnalysis() {
    if (mounted) {
      setState(() {
        _fileName = null;
        _analysisResult = null;
        // Do not clear JD controller so user doesn't have to re-paste
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume AI'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'General ATS Scan'),
            Tab(text: 'Job Description Match'),
          ],
        ),
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAnalysis,
              tooltip: 'Scan New Resume',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: General
          _buildTabContent(isJobMatch: false),
          // Tab 2: Job Match
          _buildTabContent(isJobMatch: true),
        ],
      ),
    );
  }

  Widget _buildTabContent({required bool isJobMatch}) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Extracting Text & Analyzing...'),
            ],
          ),
        ),
      );
    }

    if (_analysisResult != null) {
      // Ensure we are showing the result meant for this tab
      // (Though _resetAnalysis clears it on tab switch, this is a safety check)
      if (isJobMatch == _isJdAnalysis) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Results for $_fileName',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildATSScoreCard(),
              const SizedBox(height: 16),
              _buildImprovementTips(),
              const SizedBox(height: 16),
              _buildKeywordsSection(),
              const SizedBox(height: 32),
              _buildVersionTracking(isJobMatch),
            ],
          ),
        );
      } else {
         return Center(child: Text("Switch to ${isJobMatch ? 'General' : 'Job Match'} tab to view results."));
      }
    }

    // Default: Show Upload View
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (isJobMatch) ...[
            _buildJDInputSection(),
            const SizedBox(height: 24),
          ],
          _buildUploadBox(isJobMatch),
          const SizedBox(height: 32),
           // Show version history on main screen too if desired, or just keep it simple
           _buildVersionTracking(isJobMatch),
        ],
      ),
    );
  }

  Widget _buildJDInputSection() {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
           'Target Job Description',
           style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
         ),
         const SizedBox(height: 8),
         Container(
            child: TextField(
              controller: _jdController,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Paste the Job Description here...',
                hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),
       ],
     );
  }

  Widget _buildUploadBox(bool isJobMatch) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            isJobMatch ? 'Upload Resume to Match' : 'Upload your Resume',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Support PDF (Max 5MB)',
            style: GoogleFonts.outfit(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _pickAndAnalyzeFile,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
            ),
            child: const Text('Select PDF & Analyze'),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildATSScoreCard() {
    final score = _analysisResult?['ats_score'] ?? 0;
    final summary = _analysisResult?['short_summary'] ?? 'No summary available.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 8.0,
            percent: (score / 100).clamp(0.0, 1.0),
            center: Text(
              "$score",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            progressColor: score > 70 ? Colors.green : (score > 40 ? Colors.orange : Colors.red),
            backgroundColor: AppColors.secondary.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isJdAnalysis 
                      ? 'Job Match Score: ${score > 70 ? 'Excellent' : (score > 40 ? 'Moderate' : 'Low')}'
                      : 'ATS Compatibility: ${score > 70 ? 'Good' : (score > 40 ? 'Average' : 'Poor')}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX();
  }

  Widget _buildImprovementTips() {
    final tips = List<String>.from(_analysisResult?['key_improvements'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Key Improvements',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        if (tips.isEmpty)
          const Text('No specific improvements found.'),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildTipItem(tip, Icons.lightbulb_outline, AppColors.accent),
        )),
      ],
    );
  }
  
  Widget _buildKeywordsSection() {
    final keywords = List<String>.from(_analysisResult?['keyword_suggestions'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Missing Keywords',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.map((k) => Chip(
            label: Text(k),
            backgroundColor: AppColors.secondary.withOpacity(0.1),
            labelStyle: const TextStyle(color: AppColors.secondary, fontSize: 12),
          )).toList(),
        )
      ],
    );
  }

  Widget _buildTipItem(String tip, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.outfit(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionTracking(bool isJobMatch) {
    final user = ref.watch(authServiceProvider).currentUser;
    // If no user logic handling is preferred here, we can show a login prompt or just empty.
    if (user == null) {
      return const SizedBox.shrink(); 
    }
    
    final type = isJobMatch ? 'job_match' : 'general';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isJobMatch ? 'Job Match History' : 'General Analysis History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ResumeAnalysis>>(
            stream: ref.watch(resumeServiceProvider).getUserHistory(user.uid, type: type),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ));
              }
              if (snapshot.hasError) {
                return Text('Error loading history', style: TextStyle(color: Colors.red[300]));
              }
              
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No previous analyses found.'),
                );
              }

              // Limit to last 5 for cleanliness if list gets long, 
              // but for now scrolling column inside parent scroll view might be tricky 
              // if not handled carefully. Since the parent is SingleChildScrollView, 
              // we can just list them.
              return Column(
                children: history.map((item) => _buildVersionItem(item)).toList(),
              );
            },
        ),
      ],
    );
  }

  Widget _buildVersionItem(ResumeAnalysis item) {
    final dateFormat = DateFormat.yMMMd().add_jm(); // e.g. Sep 10, 2024 5:30 PM
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResumeHistoryDetailScreen(analysis: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                item.type == 'job_match' ? Icons.work_outline : Icons.description_outlined, 
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName, 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dateFormat.format(item.timestamp), 
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(item.score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.score.toInt()}%',
                  style: TextStyle(
                    color: _getScoreColor(item.score), 
                    fontWeight: FontWeight.bold,
                    fontSize: 13
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                onPressed: () async {
                   // Confirm delete
                   final confirm = await showDialog<bool>(
                     context: context, 
                     builder: (c) => AlertDialog(
                       title: const Text('Delete Record?'),
                       content: const Text('This action cannot be undone.'),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                         TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                       ],
                     )
                   );
                   
                   if (confirm == true) {
                     await ref.read(resumeServiceProvider).deleteAnalysis(item.userId, item.id);
                   }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score > 70) return Colors.green;
    if (score > 40) return Colors.orange;
    return Colors.red;
  }
}
