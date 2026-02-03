import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/assessment_result.dart';

class AssessmentHistoryDetailScreen extends StatelessWidget {
  final AssessmentResult result;

  const AssessmentHistoryDetailScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isPassed = result.scorePercentage >= 70;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                result.assessmentTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
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
                    const SizedBox(height: 20),
                    Icon(
                      isPassed ? Icons.stars : Icons.assignment_late,
                      size: 64,
                      color: Colors.white,
                    ).animate().scale(),
                    const SizedBox(height: 12),
                    Text(
                      'Score: ${result.scorePercentage.toInt()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(result.timestamp),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
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
                  _buildSummaryCards(),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildStatCard('Correct', '${result.correctCount}', Colors.green),
        const SizedBox(width: 16),
        _buildStatCard('Incorrect', '${result.totalQuestions - result.correctCount}', Colors.red),
        const SizedBox(width: 16),
        _buildStatCard('Category', result.category, Colors.blue),
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
            Text(
              value, 
              style: GoogleFonts.outfit(
                fontSize: value.length > 8 ? 16 : 22, 
                fontWeight: FontWeight.bold, 
                color: color
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSectionAnalysis() {
    final Map<String, List<bool>> sectionResults = {};
    for (int i = 0; i < result.questions.length; i++) {
        final q = result.questions[i];
        final section = q['section'] ?? 'General';
        final correctIdx = q['correctOptionIndex'] as int;
        final userAns = result.userAnswers[i];
        sectionResults.putIfAbsent(section, () => []).add(correctIdx == userAns);
    }

    final List<_SectionData> plotData = sectionResults.entries.map((e) {
        final total = e.value.length;
        final corrects = e.value.where((v) => v).length;
        return _SectionData(e.key, (corrects / total) * 100);
    }).toList();

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
            dataSource: plotData,
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
      itemCount: result.questions.length,
      itemBuilder: (context, index) {
        final q = result.questions[index];
        final userAns = result.userAnswers[index];
        final correctIdx = q['correctOptionIndex'] as int;
        final isCorrect = correctIdx == userAns;
        final options = List<String>.from(q['options'] ?? []);

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
              Text(q['text'] ?? '', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                'Correct Answer: ${correctIdx < options.length ? options[correctIdx] : "N/A"}',
                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (!isCorrect)
                Text(
                  'Your Answer: ${userAns != null && userAns < options.length ? options[userAns] : "Not Answered"}',
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
