import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/resume_analysis.dart';

class ResumeHistoryDetailScreen extends StatelessWidget {
  final ResumeAnalysis analysis;

  const ResumeHistoryDetailScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'ATS Score',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                  ).animate().fadeIn().slideY(),
                  const SizedBox(height: 16),
                  CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 12.0,
                    percent: (analysis.score / 100).clamp(0.0, 1.0),
                    center: Text(
                      "${analysis.score.toInt()}",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 32),
                    ),
                    progressColor: _getScoreColor(analysis.score),
                    backgroundColor: AppColors.border,
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                  ).animate().scale(),
                  const SizedBox(height: 24),
                  Text(
                    analysis.fileName,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(analysis.timestamp),
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Summary'),
            const SizedBox(height: 12),
            _buildInfoCard(analysis.summary),
            
            if (analysis.jobDescription != null && analysis.jobDescription!.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('Target Job Description'),
              const SizedBox(height: 12),
              _buildInfoCard(analysis.jobDescription!, maxLines: 5),
            ],

            const SizedBox(height: 32),
            _buildSectionHeader('Key Improvements'),
            const SizedBox(height: 12),
            if (analysis.improvements.isEmpty)
              const Text('No improvements suggested.')
            else
              ...analysis.improvements.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPointItem(tip, Icons.lightbulb_outline, AppColors.accent),
              )),

            const SizedBox(height: 32),
            _buildSectionHeader('Missing Keywords'),
            const SizedBox(height: 12),
            if (analysis.keywords.isEmpty)
              const Text('No missing keywords identified.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: analysis.keywords.map((k) => Chip(
                  label: Text(k),
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.secondary, fontSize: 12),
                  side: BorderSide(color: AppColors.secondary.withOpacity(0.2)),
                )).toList(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(String text, {int? maxLines}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }

  Widget _buildPointItem(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 14),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Color _getScoreColor(double score) {
    if (score > 70) return Colors.green;
    if (score > 40) return Colors.orange;
    return Colors.red;
  }
}
