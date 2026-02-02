import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/app_colors.dart';
import '../../models/assessment.dart';

class AssessmentResultScreen extends StatelessWidget {
  final Assessment assessment;
  final Map<int, int> userAnswers;

  const AssessmentResultScreen({
    super.key,
    required this.assessment,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    int correctCount = 0;
    userAnswers.forEach((qIndex, aIndex) {
      if (assessment.questions[qIndex].correctOptionIndex == aIndex) {
        correctCount++;
      }
    });

    final totalQuestions = assessment.questions.length;
    final scorePercentage = (correctCount / totalQuestions) * 100;
    final isPassed = scorePercentage >= 70;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            automaticallyImplyLeading: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPassed 
                        ? [AppColors.secondary, AppColors.secondary.withOpacity(0.7)] 
                        : [AppColors.error, AppColors.error.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      isPassed ? Icons.emoji_events_outlined : Icons.sentiment_dissatisfied_outlined,
                      size: 80,
                      color: Colors.white,
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(
                      isPassed ? 'Test Passed!' : 'Test Not Cleared',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Score: ${scorePercentage.toInt()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(correctCount, totalQuestions),
                  const SizedBox(height: 32),
                  Text(
                    'Performance Analysis',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionAnalysis(),
                  const SizedBox(height: 32),
                  Text(
                    'Question Breakdown',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildQuestionList(),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Back to Dashboard'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int correct, int total) {
    return Row(
      children: [
        _buildStatCard('Correct', '$correct', Colors.green),
        const SizedBox(width: 16),
        _buildStatCard('Incorrect', '${total - correct}', Colors.red),
        const SizedBox(width: 16),
        _buildStatCard('Accuracy', '${((correct / total) * 100).toInt()}%', Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSectionAnalysis() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        series: <CartesianSeries>[
          BarSeries<_SectionData, String>(
            dataSource: [
              _SectionData('Quant', 80),
              _SectionData('Verbal', 65),
              _SectionData('Logical', 90),
            ],
            xValueMapper: (data, _) => data.section,
            yValueMapper: (data, _) => data.score,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assessment.questions.length,
      itemBuilder: (context, index) {
        final q = assessment.questions[index];
        final userAns = userAnswers[index];
        final isCorrect = q.correctOptionIndex == userAns;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Q${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(q.text, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                'Correct Answer: ${q.options[q.correctOptionIndex]}',
                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (!isCorrect)
                Text(
                  'Your Answer: ${userAns != null ? q.options[userAns] : "Not Answered"}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionData {
  final String section;
  final double score;
  _SectionData(this.section, this.score);
}
