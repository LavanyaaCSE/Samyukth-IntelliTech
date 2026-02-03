import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import 'weekly_plan_widget.dart';
import '../assessments/assessment_list_screen.dart';
import '../resume/resume_screen.dart';
import '../interviews/interviews_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'IntelliTrain',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
                  _buildReadinessScore(),
                  const SizedBox(height: 32),
                  const WeeklyPlanWidget(),
                  const SizedBox(height: 32),
                  Text(
                    'Your Learning Path',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(context),
                  const SizedBox(height: 32),
                  _buildUpcomingAssessments(),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
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

  Widget _buildReadinessScore() {
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
            percent: 0.75,
            center: Text(
              "75%",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
            progressColor: AppColors.primary,
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
                  'You are doing great! Focus on Technical Interviews to reach 85%.',
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

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildFeatureCard(
          context,
          'Assessments',
          Icons.quiz_outlined,
          AppColors.primary,
          '12 Completed',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AssessmentListScreen())),
        ),
        _buildFeatureCard(
          context,
          'Resume AI',
          Icons.description_outlined,
          AppColors.secondary,
          'ATS Score: 82',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ResumeScreen())),
        ),
        _buildFeatureCard(
          context,
          'Mock Interviews',
          Icons.interpreter_mode_outlined,
          AppColors.accent,
          'Next: Technical',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InterviewsScreen())),
        ),
        _buildFeatureCard(
          context,
          'Job Match',
          Icons.work_outline,
          AppColors.info,
          '5 New Matches',
          onTap: () {},
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
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildUpcomingAssessments() {
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
        _buildTestItem(
          'Aptitude & Logical Reasoning',
          'Tomorrow, 10:00 AM',
          '60 Mins',
          Icons.timer_outlined,
        ),
        const SizedBox(height: 12),
        _buildTestItem(
          'Core Java Assessment',
          '05 Feb, 02:00 PM',
          '45 Mins',
          Icons.code,
        ),
      ],
    );
  }

  Widget _buildTestItem(String title, String time, String duration, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $duration',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
