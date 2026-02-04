
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../services/gemini_service.dart';

class JobRoadmapScreen extends ConsumerStatefulWidget {
  final String jobTitle;
  final List<String> jobSkills;

  const JobRoadmapScreen({
    super.key,
    required this.jobTitle,
    required this.jobSkills,
  });

  @override
  ConsumerState<JobRoadmapScreen> createState() => _JobRoadmapScreenState();
}

class _JobRoadmapScreenState extends ConsumerState<JobRoadmapScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _roadmapData;

  @override
  void initState() {
    super.initState();
    _fetchRoadmap();
  }

  Future<void> _fetchRoadmap() async {
    try {
      final jsonString = await ref.read(geminiServiceProvider).generateJobRoadmap(
        jobTitle: widget.jobTitle,
        jobSkills: widget.jobSkills,
      );

      final decoded = jsonDecode(jsonString);
      if (decoded is Map && decoded.containsKey('error')) throw decoded['error'];

      setState(() {
        _roadmapData = decoded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Roadmap: ${widget.jobTitle}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildRoadmap(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Creating your path to success...',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is designing a personalized roadmap.',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to generate roadmap', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchRoadmap();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmap() {
    final milestones = List<dynamic>.from(_roadmapData?['milestones'] ?? []);
    final timeline = _roadmapData?['estimated_timeline'] ?? 'Varies';
    final proTip = _roadmapData?['pro_tip'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(timeline),
        const SizedBox(height: 32),
        ...milestones.asMap().entries.map((entry) {
          return _buildMilestoneStep(entry.key, entry.value, entry.key == milestones.length - 1);
        }),
        const SizedBox(height: 16),
        if (proTip.isNotEmpty) _buildProTip(proTip),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildHeader(String timeline) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed, color: AppColors.primary, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estimated Timeline',
                  style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                ),
                Text(
                  timeline,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildMilestoneStep(int index, Map<String, dynamic> milestone, bool isLast) {
    final tasks = List<String>.from(milestone['tasks'] ?? []);
    final resources = List<String>.from(milestone['resources'] ?? []);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primary.withOpacity(0.2),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone['title'] ?? 'Milestone',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task,
                            style: GoogleFonts.outfit(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (resources.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: resources.map((res) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          res,
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 150).ms).slideY(begin: 0.1);
  }

  Widget _buildProTip(String tip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                'PRO TIP',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tip,
            style: GoogleFonts.outfit(fontStyle: FontStyle.italic, fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).scale();
  }
}
