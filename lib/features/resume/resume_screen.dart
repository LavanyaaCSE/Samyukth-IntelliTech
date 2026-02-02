import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/app_colors.dart';

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume AI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadSection(context),
            const SizedBox(height: 32),
            _buildJDHighlight(),
            const SizedBox(height: 32),
            Text(
              'Latest Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildATSScoreCard(),
            const SizedBox(height: 16),
            _buildImprovementTips(),
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
            'Support PDF, DOCX (Max 5MB)',
            style: GoogleFonts.outfit(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
            ),
            child: const Text('Select File'),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildJDHighlight() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_outlined, color: AppColors.accent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JD-Resume Match',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Paste a Job Description to see how well you fit.',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Try Now')),
        ],
      ),
    );
  }

  Widget _buildATSScoreCard() {
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
            percent: 0.82,
            center: const Text(
              "82",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            progressColor: AppColors.secondary,
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
                  'ATS Compatibility: Good',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your resume is well-structured for automated systems.',
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
        _buildTipItem('Add more keywords related to Cloud Computing.', Icons.lightbulb_outline, AppColors.accent),
        const SizedBox(height: 8),
        _buildTipItem('Quantify your achievements in the Experience section.', Icons.trending_up, AppColors.primary),
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
        const SizedBox(height: 8),
        _buildVersionItem('Resume_V1_Base.pdf', '65%', '1 week ago'),
      ],
    );
  }

  Widget _buildVersionItem(String name, String score, String date) {
    return Container(
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
    );
  }
}
