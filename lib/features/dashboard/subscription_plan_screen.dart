import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';

class SubscriptionPlanScreen extends StatelessWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Your Plan'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Choose the perfect plan for your career growth.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 40),
            
            _buildPlanCard(
              context,
              'FREE',
              '0',
              'Perfect for getting started',
              [
                '5 AI Resume Scans / month',
                '2 Mock Interviews / month',
                'Basic Placement Tests',
              ],
              Colors.blueGrey,
              false,
            ),
            const SizedBox(height: 24),
            
            _buildPlanCard(
              context,
              'PRO',
              '29',
              'Best for active job seekers',
              [
                'Unlimited AI Resume Scans',
                'Unlimited AI Mock Interviews',
                'Advanced Depth Analysis',
                'Priority AI Generation',
              ],
              AppColors.primary,
              true,
            ),
            const SizedBox(height: 24),
            
            _buildPlanCard(
              context,
              'INSTITUTION',
              '99',
              'For colleges & universities',
              [
                'Everything in Pro',
                'Batch Performance Analytics',
                'Skill Gap Visualizations',
                'Downloadable Student Reports',
              ],
              AppColors.secondary,
              false,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    String title,
    String price,
    String subtitle,
    List<String> features,
    Color color,
    bool isPopular,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? color : Colors.white.withOpacity(0.05),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular 
          ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]
          : [],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              right: 20,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$$price',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '/month',
                      style: GoogleFonts.outfit(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? color : Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    side: isPopular ? null : BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(price == '0' ? 'Get Started' : 'Upgrade Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
