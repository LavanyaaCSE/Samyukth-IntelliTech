import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_colors.dart';
import '../../services/interview_service.dart';
import '../../services/auth_service.dart';
import '../../models/interview_session.dart';

class InterviewSummaryScreen extends ConsumerStatefulWidget {
  final String mode;
  final String topic;
  final List<Map<String, dynamic>> sessionData; // Contains {question, answer, feedback, rating}
  final bool isVoice;

  const InterviewSummaryScreen({
    super.key,
    required this.mode,
    required this.topic,
    required this.sessionData,
    this.isVoice = false,
  });

  @override
  ConsumerState<InterviewSummaryScreen> createState() => _InterviewSummaryScreenState();
}

class _InterviewSummaryScreenState extends ConsumerState<InterviewSummaryScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _saveSession();
  }

  Future<void> _saveSession() async {
    if (widget.sessionData.isEmpty) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return; // Should navigate to login if critical, but for now just return

    setState(() => _isSaving = true);

    try {
      final totalScore = widget.sessionData.fold(0, (sum, item) => sum + (item['rating'] as int));
      final avgScore = totalScore / widget.sessionData.length;

      final session = InterviewSession(
        id: const Uuid().v4(),
        userId: user.uid,
        mode: widget.mode,
        topic: widget.topic,
        averageScore: avgScore,
        questionsAndAnswers: widget.sessionData,
        timestamp: DateTime.now(),
        isVoice: widget.isVoice,
      );

      await ref.read(interviewServiceProvider).saveSession(session);
      print("Interview session saved successfully.");
    } catch (e) {
      print("Error saving session: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Failed to save result: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
         setState(() => _isSaving = false);
      }
    }
  }

  double get _averageScore {
    if (widget.sessionData.isEmpty) return 0.0;
    final total = widget.sessionData.fold(0, (sum, item) => sum + (item['rating'] as int));
    return total / widget.sessionData.length;
  }

  @override
  Widget build(BuildContext context) {
    final avgScore = _averageScore;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             if (_isSaving)
               const LinearProgressIndicator(),
             Text(
              'Interview Complete!',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
             ).animate().fadeIn().slideY(),
             const SizedBox(height: 8),
             Text(
              '${widget.mode} - ${widget.topic}',
              style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary),
             ),
             const SizedBox(height: 32),
             
             CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 12.0,
                percent: (avgScore / 10).clamp(0.0, 1.0),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      avgScore.toStringAsFixed(1),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 32),
                    ),
                    const Text("Avg Score"),
                  ],
                ),
                progressColor: avgScore >= 7 ? Colors.green : (avgScore >= 4 ? Colors.orange : Colors.red),
                backgroundColor: AppColors.border,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
             ).animate().scale(),
             
             const SizedBox(height: 32),
             
             _buildFeedbackList(),
             
             const SizedBox(height: 32),
             
             ElevatedButton(
               onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
               style: ElevatedButton.styleFrom(
                 minimumSize: const Size(double.infinity, 56),
               ),
               child: const Text('Back to Home'),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Breakdown',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...widget.sessionData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final score = data['rating'] as int;
          
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
                        color: (score >= 7 ? Colors.green : Colors.orange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Score: $score/10',
                        style: TextStyle(
                          color: score >= 7 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data['question'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  "Analysis: ${data['feedback']}",
                   style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (200 * index).ms).slideX();
        }),
      ],
    );
  }
}
