import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import '../../core/app_colors.dart';
import '../../services/gemini_service.dart';

class ResumeScreen extends ConsumerStatefulWidget {
  const ResumeScreen({super.key});

  @override
  ConsumerState<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends ConsumerState<ResumeScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  String? _fileName;

  Future<void> _pickAndAnalyzeFile() async {
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

        // Call Gemini Service with TEXT
        final jsonString = await ref.read(geminiServiceProvider).analyzeResume(
          text: extractedText,
        );

        if (jsonString.startsWith('{') || jsonString.startsWith('[')) {
          final decoded = jsonDecode(jsonString);
          
          if (decoded is Map && decoded.containsKey('error')) {
            throw decoded['error'];
          }

          setState(() {
            _analysisResult = decoded;
          });
        } else {
          throw 'Invalid response format';
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetAnalysis() {
    setState(() {
      _fileName = null;
      _analysisResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume AI'),
        actions: [
          if (_analysisResult != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAnalysis,
              tooltip: 'Upload New Resume',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_analysisResult == null) ...[
              _buildUploadSection(context),
            ] else ...[
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
            ],
            
            if (_isLoading)
               const Center(
                 child: Padding(
                   padding: EdgeInsets.all(32.0),
                   child: Column(
                     children: [
                       CircularProgressIndicator(),
                       SizedBox(height: 16),
                       Text('Extracting Text & Analyzing...'),
                     ],
                   ),
                 ),
               ),
               
            const SizedBox(height: 32),
            _buildVersionTracking(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(BuildContext context) {
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
            'Upload your Resume',
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
            onPressed: _isLoading ? null : _pickAndAnalyzeFile,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
            ),
            child: const Text('Select PDF File'),
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
                  'ATS Compatibility: ${score > 70 ? 'Good' : (score > 40 ? 'Average' : 'Poor')}',
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
            'Recommended Keywords',
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

  Widget _buildVersionTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildVersionItem('Resume_V2_Final.pdf', '82%', '2 days ago'),
        _buildVersionItem('Resume_V1_Base.pdf', '65%', '1 week ago'),
      ],
    );
  }

  Widget _buildVersionItem(String name, String score, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(date, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                score,
                style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
