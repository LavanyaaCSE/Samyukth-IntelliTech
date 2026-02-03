import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import 'active_interview_screen.dart';

class InterviewsScreen extends StatelessWidget {
  const InterviewsScreen({super.key});

  void _showInterviewSetup(BuildContext context, String mode) {
    final topicController = TextEditingController();
    final jdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start $mode', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the details below to customize your AI interview session.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Job Role / Topic',
                hintText: 'e.g. Senior Flutter Developer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jdController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Job Description (Optional)',
                hintText: 'Paste the JD here for tailored questions...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (topicController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a Job Role or Topic')),
                );
                return;
              }
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveInterviewScreen(
                    mode: mode,
                    topic: topicController.text.trim(),
                    jobDescription: jdController.text.trim().isEmpty ? null : jdController.text.trim(),
                  ),
                ),
              );
            },
            child: const Text('Start Interview'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Mock Interviews')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice makes perfect',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Select a mode to start your AI-powered interview session.',
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              _buildInterviewModeCard(
                context,
                'HR Interview',
                'Behavioral & Culture Fit',
                Icons.people_outline,
                AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildInterviewModeCard(
                context,
                'Technical Interview',
                'Data Structures, Algorithms & Dev',
                Icons.code,
                AppColors.secondary,
              ),
              const SizedBox(height: 16),
              _buildInterviewModeCard(
                context,
                'Managerial Interview',
                'Problem solving & Leadership',
                Icons.assignment_ind_outlined,
                AppColors.accent,
              ),
              const SizedBox(height: 32),
              _buildRecentFeedback(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewModeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInterviewSetup(context, title),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildRecentFeedback() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Text(
                'Recent Performance',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your communication clarity has improved by 15% in the last 3 sessions. Keep it up!',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
