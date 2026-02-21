import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import 'weekly_plan_widget.dart';
import '../assessments/assessment_list_screen.dart';
import '../assessments/assessment_history_screen.dart';
import '../assessments/active_assessment_screen.dart';
import '../../models/assessment.dart';
import '../resume/resume_screen.dart';
import '../resume/resume_history_screen.dart';
import '../interviews/interviews_screen.dart';
import '../interviews/interview_history_screen.dart';
import '../../services/resume_service.dart';
import '../../services/interview_service.dart';
import '../../services/assessment_service.dart';
import '../../services/job_service.dart';
import '../../models/assessment_result.dart';
import '../../models/resume_analysis.dart';
import '../../models/interview_session.dart';
import '../../models/upcoming_test.dart';
import '../jobs/job_matches_screen.dart';
import '../jobs/job_search_screen.dart';
import 'profile_screen.dart';



final upcomingTestsProvider = StreamProvider<List<UpcomingTest>>((ref) {
  return ref.watch(assessmentServiceProvider).getUpcomingTests();
});

final interviewScoreProvider = StreamProvider.family<double, String>((ref, userId) {
  return ref.watch(interviewServiceProvider).getOverallAverage(userId);
});

final assessmentScoreProvider = StreamProvider.family<double, String>((ref, userId) {
  return ref.watch(assessmentServiceProvider).getAverageScore(userId);
});

final resumeScoreProvider = StreamProvider.family<double, String>((ref, userId) {
  return ref.watch(resumeServiceProvider).getAverageScore(userId);
});

final assessmentResultsProvider = StreamProvider.family<List<AssessmentResult>, String>((ref, userId) {
  return ref.watch(assessmentServiceProvider).getUserResults(userId);
});

final resumeHistoryProvider = StreamProvider.family<List<ResumeAnalysis>, String>((ref, userId) {
  return ref.watch(resumeServiceProvider).getUserHistory(userId);
});

final interviewHistoryProvider = StreamProvider.family<List<InterviewSession>, String>((ref, userId) {
  return ref.watch(interviewServiceProvider).getUserHistory(userId);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leadingWidth: 80,
            leading: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
              title: Text(
                'IntelliTrain',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.rocket_launch,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000), // Max width for web
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    authState.when(
                      data: (user) => _buildWelcomeSection(
                        user?.displayName ?? user?.email?.split('@')[0] ?? 'User'
                      ),
                      loading: () => _buildWelcomeSection('User'),
                      error: (_, __) => _buildWelcomeSection('User'),
                    ),
                    const SizedBox(height: 32),
                    authState.when(
                      data: (user) => _buildReadinessScore(ref, user?.uid),
                      loading: () => _buildReadinessScore(ref, null),
                      error: (_, __) => _buildReadinessScore(ref, null),
                    ),
                    const SizedBox(height: 32),
                    const WeeklyPlanWidget(),
                    const SizedBox(height: 32),
                    Text(
                      'Your Learning Path',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    authState.when(
                      data: (user) => _buildFeatureGrid(context, ref, user?.uid),
                      loading: () => _buildFeatureGrid(context, ref, null),
                      error: (_, __) => _buildFeatureGrid(context, ref, null),
                    ),
                    const SizedBox(height: 32),
                    _buildUpcomingAssessments(context, ref),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $userName!',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Ready for your placement journey today?',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildReadinessScore(WidgetRef ref, String? userId) {
    if (userId == null) {
      return _readinessScoreContainer(0.0, "Sign in to track your progress");
    }

    final interviewScore = ref.watch(interviewScoreProvider(userId));
    final assessmentScore = ref.watch(assessmentScoreProvider(userId));
    final resumeScore = ref.watch(resumeScoreProvider(userId));

    final iScore = interviewScore.value ?? 0.0; // 0-10
    final aScore = (assessmentScore.value ?? 0.0) / 10; // 0-100 -> 0-10
    final rScore = (resumeScore.value ?? 0.0) / 10; // 0-100 -> 0-10

    double combinedScore = 0.0;
    int activeMetrics = 0;
    String weakestArea = "";
    double lowestScore = 11.0;

    if (iScore > 0) {
      combinedScore += iScore;
      activeMetrics++;
      if (iScore < lowestScore) {
        lowestScore = iScore;
        weakestArea = "Interviews";
      }
    }
    if (aScore > 0) {
      combinedScore += aScore;
      activeMetrics++;
      if (aScore < lowestScore) {
        lowestScore = aScore;
        weakestArea = "Tests";
      }
    }
    if (rScore > 0) {
      combinedScore += rScore;
      activeMetrics++;
      if (rScore < lowestScore) {
        lowestScore = rScore;
        weakestArea = "Resume";
      }
    }

    double finalPercent = activeMetrics > 0 ? (combinedScore / activeMetrics) / 10 : 0.0;
    String message = "Take your first step to see your readiness!";

    if (activeMetrics > 0) {
      if (finalPercent >= 0.8) {
        message = "Excellent! You are top-tier ready.";
      } else if (finalPercent >= 0.6) {
        message = "Good progress! $weakestArea needs more focus.";
      } else {
        message = "Weak at $weakestArea. Practice more to improve.";
      }
    }

    return _readinessScoreContainer(finalPercent, message);
  }

  Widget _readinessScoreContainer(double percent, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 10.0,
            percent: percent.clamp(0.0, 1.0),
            center: Text(
              "${(percent * 100).toInt()}%",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
            progressColor: percent >= 0.7 ? Colors.green : (percent >= 0.4 ? Colors.orange : Colors.red),
            backgroundColor: AppColors.primary.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Readiness Score',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  Widget _buildFeatureGrid(BuildContext context, WidgetRef ref, String? userId) {
    String assessmentsText = '0 Completed';
    String resumeText = 'No Analysis';
    String interviewText = 'Next: HR Interview';
    String jobMatchText = '0 Matches';
    List<Map<String, dynamic>> matchedJobs = [];

    if (userId != null) {
      final assessments = ref.watch(assessmentResultsProvider(userId)).value ?? [];
      final resumes = ref.watch(resumeHistoryProvider(userId)).value ?? [];
      final interviews = ref.watch(interviewHistoryProvider(userId)).value ?? [];
      
      assessmentsText = '${assessments.length} Completed';

      final latestGeneralResume = resumes.where((r) => r.type == 'general').firstOrNull ?? resumes.firstOrNull;
      
      // Resume status text
      final generalResume = resumes.where((r) => r.type == 'general').firstOrNull;
      final jobMatchResume = resumes.where((r) => r.type == 'job_match').firstOrNull;
      List<String> resumeParts = [];
      if (generalResume != null) resumeParts.add('ATS: ${generalResume.score.toInt()}');
      if (jobMatchResume != null) resumeParts.add('Match: ${jobMatchResume.score.toInt()}%');
      if (resumeParts.isNotEmpty) resumeText = resumeParts.join(' | ');

      // Interview status text
      if (interviews.isNotEmpty) {
        final lastSession = interviews.first;
        final modeShort = lastSession.mode.replaceAll(' Interview', '');
        interviewText = '$modeShort: ${lastSession.averageScore.toStringAsFixed(1)}/10';
      }

      // Job Match
      final allJobs = ref.watch(jobsStreamProvider).value ?? [];
      matchedJobs = ref.watch(jobServiceProvider).getMatchedJobs(latestGeneralResume, allJobs);
      final isTrending = matchedJobs.isNotEmpty && (matchedJobs.first['isTrending'] ?? false);
      jobMatchText = isTrending ? '${matchedJobs.length} Suggestions' : '${matchedJobs.length} Matches';
    }


    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    final double spacing = screenWidth > 600 ? 24.0 : 16.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: screenWidth > 600 ? 1.0 : 0.85,
      children: [
        _buildFeatureCard(
          context,
          'Assessments',
          Icons.quiz_outlined,
          AppColors.primary,
          assessmentsText,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AssessmentHistoryScreen())),
        ),
        _buildFeatureCard(
          context,
          'Resume AI',
          Icons.description_outlined,
          AppColors.secondary,
          resumeText,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ResumeHistoryScreen())),
        ),
        _buildFeatureCard(
          context,
          'Mock Interviews',
          Icons.interpreter_mode_outlined,
          AppColors.accent,
          interviewText,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InterviewHistoryScreen())),
        ),
        _buildFeatureCard(
          context,
          'Job Match',
          Icons.work_outline,
          AppColors.info,
          jobMatchText,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const JobMatchesScreen())
          ),
        ),
        _buildFeatureCard(
          context,
          'Browse Jobs',
          Icons.search,
          AppColors.primary,
          'Find New Work',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const JobSearchScreen())
          ),
        ),
      ],

    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15, // Slightly smaller to ensure fit
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildUpcomingAssessments(BuildContext context, WidgetRef ref) {
    final upcomingTestsAsync = ref.watch(upcomingTestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Tests',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),
        upcomingTestsAsync.when(
          data: (tests) {
            if (tests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No scheduled tests found.',
                    style: GoogleFonts.outfit(color: AppColors.textMuted),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (itemContext, index) {
                final test = tests[index];
                return _buildTestItem(context, test); // Use stable context
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Could not load tests: $err',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestItem(BuildContext context, UpcomingTest test) {
    final now = DateTime.now();
    final bool isActive = now.isAfter(test.startTime) && now.isBefore(test.endTime);
    final bool isFuture = now.isBefore(test.startTime);
    
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final timeStr = isFuture 
        ? dateFormat.format(test.startTime)
        : (isActive ? 'Active Now' : 'Expired');

    debugPrint('Building test item: ${test.title}, isActive: $isActive');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary.withOpacity(0.3) : Colors.white.withOpacity(0.05)
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.primary : Colors.white).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              test.category.toLowerCase() == 'technical' ? Icons.code : Icons.quiz_outlined, 
              color: isActive ? AppColors.primary : AppColors.textMuted, 
              size: 24
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$timeStr • ${test.durationMinutes} Mins',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isActive ? () {
              debugPrint('JOIN NOW clicked for ${test.title}');
              _showTestStartDialog(context, test);
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? AppColors.primary : Colors.grey.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              isActive ? 'Join Now' : (isFuture ? 'Locked' : 'Ended'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  void _showTestStartDialog(BuildContext context, UpcomingTest test) {
    debugPrint('Show test dialog called for: ${test.title}');
    debugPrint('Questions count: ${test.questions.length}');
    
    // Convert UpcomingTest to Assessment model for the ActiveAssessmentScreen
    final assessment = Assessment(
      id: test.id,
      title: test.title,
      durationMinutes: test.durationMinutes,
      questions: test.questions,
      category: test.category,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(test.title),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scheduled Test Instructions:'),
            SizedBox(height: 12),
            _Bullet(text: 'This test is available for a limited time.'),
            _Bullet(text: 'Switching apps will auto-submit the test.'),
            _Bullet(text: 'Do not minimize the screen.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ActiveAssessmentScreen(assessment: assessment),
                ),
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
