import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/gemini_service.dart';
import '../../services/auth_service.dart';
import '../../services/interview_service.dart';
import '../../services/assessment_service.dart';
import '../../services/resume_service.dart';

class WeeklyPlanDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;

  const WeeklyPlanDetailScreen({super.key, required this.item});

  @override
  ConsumerState<WeeklyPlanDetailScreen> createState() => _WeeklyPlanDetailScreenState();
}

class _WeeklyPlanDetailScreenState extends ConsumerState<WeeklyPlanDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analysis;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      // Fetch some context data to help Gemini analyze the weakness
      final interviewSessions = await ref.read(interviewServiceProvider).getUserHistory(user.uid).first;
      final assessmentHistory = await ref.read(assessmentServiceProvider).getUserResults(user.uid).first;
      
      final contextData = "Interviews: ${interviewSessions.take(3).map((s) => s.averageScore).toList()}, Assessments: ${assessmentHistory.take(3).map((a) => a.scorePercentage).toList()}";

      final response = await ref.read(geminiServiceProvider).generatePlanDeepDive(
        title: widget.item['title'],
        subtitle: widget.item['subtitle'],
        category: widget.item['category'],
        contextData: contextData,
      );

      if (mounted) {
        setState(() {
          _analysis = json.decode(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(widget.item['category']);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item['title']),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(color),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Weakness Analysis'),
                      const SizedBox(height: 12),
                      _buildAnalysisCard(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('How to Improve'),
                      const SizedBox(height: 12),
                      ...(_analysis?['how_to_improve'] as List).map((step) => _buildStepItem(step)),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Recommended Resources'),
                      const SizedBox(height: 12),
                      _buildResourcesList(),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: color,
                        ),
                        child: const Text('Got it, I\'ll work on it!'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.item['category'].toString().toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Goal', 
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.item['subtitle'],
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 16),
          if (_analysis?['estimated_time'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: color),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Time: ${_analysis!['estimated_time']}',
                      style: GoogleFonts.outfit(
                        fontSize: 13, 
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: _buildFormattedText(
        _analysis?['weakness_analysis'] ?? '',
        style: GoogleFonts.outfit(height: 1.5, color: AppColors.textSecondary, fontSize: 14),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStepItem(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFormattedText(
              step,
              style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildResourcesList() {
    final resources = _analysis?['recommended_resources'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: resources.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_stories_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  r,
                  style: GoogleFonts.outfit(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildFormattedText(String text, {required TextStyle style}) {
    final List<TextSpan> spans = [];
    final parts = text.split('**');
    
    for (int i = 0; i < parts.length; i++) {
        spans.add(TextSpan(
            text: parts[i],
            style: i.isOdd 
                ? style.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary) 
                : style,
        ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'technical':
        return AppColors.primary;
      case 'behavioral':
        return AppColors.accent;
      case 'resume':
        return AppColors.secondary;
      default:
        return AppColors.info;
    }
  }
}
