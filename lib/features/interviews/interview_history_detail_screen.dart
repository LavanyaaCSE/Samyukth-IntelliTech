import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/interview_session.dart';

class InterviewHistoryDetailScreen extends StatelessWidget {
  final InterviewSession session;

  const InterviewHistoryDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Performance Summary',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ).animate().fadeIn().slideY(),
            const SizedBox(height: 8),
            Text(
              '${session.mode} • ${DateFormat('MMM dd, yyyy').format(session.timestamp)}',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 12.0,
              percent: (session.averageScore / 10).clamp(0.0, 1.0),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    session.averageScore.toStringAsFixed(1),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 32),
                  ),
                  const Text("Avg Score"),
                ],
              ),
              progressColor: _getScoreColor(session.averageScore),
              backgroundColor: AppColors.border,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ).animate().scale(),
            
            const SizedBox(height: 32),
            
            _buildInfoCard(),
            
            const SizedBox(height: 32),
            
            _buildQuestionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow(Icons.topic, 'Topic', session.topic),
          const Divider(height: 24),
          _infoRow(
            session.isVoice ? Icons.mic : Icons.chat, 
            'Type', 
            session.isVoice ? 'Voice Interview' : 'Text Interview'
          ),
          const Divider(height: 24),
          _infoRow(Icons.calendar_today, 'Date', DateFormat('MMM dd, yyyy • hh:mm a').format(session.timestamp)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value, 
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Feedback',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...session.questionsAndAnswers.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final score = (data['rating'] ?? 0) as int;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score.toDouble()).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Score: $score/10',
                        style: TextStyle(
                          color: _getScoreColor(score.toDouble()),
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Q:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                Text(data['question'] ?? 'No question text available'),
                const SizedBox(height: 8),
                const Text('A:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text(data['answer'] ?? 'No answer provided'),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  "Analysis: ${data['feedback'] ?? 'No feedback provided'}",
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (100 * index).ms).slideX();
        }),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 7) return Colors.green;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }
}
