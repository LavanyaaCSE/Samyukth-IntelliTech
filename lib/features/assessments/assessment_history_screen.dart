import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/assessment_service.dart';
import '../../services/auth_service.dart';
import '../../models/assessment_result.dart';
import 'assessment_history_detail_screen.dart';

class AssessmentHistoryScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const AssessmentHistoryScreen({super.key, this.initialCategory});

  @override
  ConsumerState<AssessmentHistoryScreen> createState() => _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState extends ConsumerState<AssessmentHistoryScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History'),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<List<AssessmentResult>>(
              stream: ref.watch(assessmentServiceProvider).getUserResults(user.uid, category: _selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final results = snapshot.data ?? [];

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No test history found for $_selectedCategory',
                          style: GoogleFonts.outfit(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return _HistoryCard(result: result);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Aptitude', 'Technical', 'General'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategory = cat);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AssessmentResult result;
  const _HistoryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isPassed = result.scorePercentage >= 70;
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(result.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AssessmentHistoryDetailScreen(result: result)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isPassed ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPassed ? Icons.check_circle_outline : Icons.error_outline,
                    color: isPassed ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.assessmentTitle,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Category: ${result.category}',
                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${result.scorePercentage.toInt()}%',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isPassed ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '${result.correctCount}/${result.totalQuestions}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }
}
