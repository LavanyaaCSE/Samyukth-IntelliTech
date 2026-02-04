import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/interview_service.dart';
import '../../services/assessment_service.dart';
import '../../services/resume_service.dart';
import '../../models/interview_session.dart';
import '../../models/assessment_result.dart';
import '../../models/resume_analysis.dart';
import '../interviews/interview_history_detail_screen.dart';
import '../assessments/assessment_history_detail_screen.dart';
import '../resume/resume_history_detail_screen.dart';

class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).value?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view history')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Activity History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Interviews'),
            Tab(text: 'Assessments'),
            Tab(text: 'Resumes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InterviewHistoryList(userId: userId),
          _AssessmentHistoryList(userId: userId),
          _ResumeHistoryList(userId: userId),
        ],
      ),
    );
  }
}

class _InterviewHistoryList extends ConsumerWidget {
  final String userId;
  const _InterviewHistoryList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interviewService = ref.watch(interviewServiceProvider);

    return StreamBuilder<List<InterviewSession>>(
      stream: interviewService.getUserHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return _buildEmptyState(Icons.chat_bubble_outline, 'No interviews yet', 'Take your first mock interview to see it here!');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _HistoryCard(
              title: session.mode,
              subtitle: 'Score: ${session.averageScore.toStringAsFixed(1)}/10',
              date: session.timestamp,
              icon: session.isVoice ? Icons.mic : Icons.keyboard,
              color: Colors.blue,
              trailing: '${session.questionsAndAnswers.length} Questions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InterviewHistoryDetailScreen(session: session)),
                );
              },
            ).animate().fadeIn(delay: (index * 50).ms).slideX();
          },
        );
      },
    );
  }
}

class _AssessmentHistoryList extends ConsumerWidget {
  final String userId;
  const _AssessmentHistoryList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentService = ref.watch(assessmentServiceProvider);

    return StreamBuilder<List<AssessmentResult>>(
      stream: assessmentService.getUserResults(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return _buildEmptyState(Icons.assignment_outlined, 'No assessments yet', 'Complete an assessment to track your progress!');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final result = results[index];
            return _HistoryCard(
              title: result.category,
              subtitle: 'Score: ${result.scorePercentage.toStringAsFixed(0)}%',
              date: result.timestamp,
              icon: Icons.assignment_turned_in,
              color: Colors.green,
              trailing: '${result.correctCount}/${result.totalQuestions}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssessmentHistoryDetailScreen(result: result)),
                );
              },
            ).animate().fadeIn(delay: (index * 50).ms).slideX();
          },
        );
      },
    );
  }
}

class _ResumeHistoryList extends ConsumerWidget {
  final String userId;
  const _ResumeHistoryList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeService = ref.watch(resumeServiceProvider);

    return StreamBuilder<List<ResumeAnalysis>>(
      stream: resumeService.getUserHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return _buildEmptyState(Icons.description_outlined, 'No resume analysis yet', 'Analyze your resume to get insights!');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final analysis = history[index];
            return _HistoryCard(
              title: analysis.fileName,
              subtitle: 'ATS Score: ${analysis.score.toStringAsFixed(0)}%',
              date: analysis.timestamp,
              icon: Icons.article,
              color: Colors.orange,
              trailing: analysis.type.toUpperCase(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResumeHistoryDetailScreen(analysis: analysis)),
                );
              },
            ).animate().fadeIn(delay: (index * 50).ms).slideX();
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String trailing;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                        style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trailing,
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildEmptyState(IconData icon, String title, String subtitle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey[500]),
          ),
        ],
      ),
    ),
  );
}
