import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../models/assessment.dart';
import 'active_assessment_screen.dart';
import '../../services/assessment_service.dart';

class AssessmentListScreen extends ConsumerWidget {
  const AssessmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We instantiate logic here or ideally via a provider
    final assessmentService = AssessmentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessments'),
        // PRODUCTION NOTE: Questions are managed via the Admin Panel
        // End users can only view and take assessments
      ),
      body: StreamBuilder<List<Assessment>>(
        stream: assessmentService.getAssessments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error loading tests: ${snapshot.error}'));
          }
          
          final assessments = snapshot.data ?? [];

          if (assessments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No assessments found in database.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please add assessments via the admin panel.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: assessments.length,
            itemBuilder: (context, index) {
              final test = assessments[index];
              return _buildTestCard(context, test);
            },
          );
        },
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, Assessment test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => _showStartDialog(context, test),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      test.category,
                      style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${test.durationMinutes} Mins', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                test.title,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${test.questions.length} Questions • Pattern: Mixed',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                   const Text('Required Score: 70%', style: TextStyle(fontSize: 12, color: Colors.grey)),
                   const Spacer(),
                   Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * (double.tryParse(test.id) ?? 1)).ms).slideX();
  }

  void _showStartDialog(BuildContext context, Assessment test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(test.title),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Important Instructions:'),
            SizedBox(height: 12),
            _Bullet(text: 'Switching apps will auto-submit the test.'),
            _Bullet(text: 'Do not minimize the screen.'),
            _Bullet(text: 'Back button is disabled.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ActiveAssessmentScreen(assessment: test)),
              );
            },
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
