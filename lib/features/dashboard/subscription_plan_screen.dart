import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/subscription_service.dart';
import 'payment_screen.dart';

class SubscriptionPlanScreen extends ConsumerWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlanAsync = ref.watch(userSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Your Plan'),
        backgroundColor: Colors.transparent,
      ),
      body: currentPlanAsync.when(
        data: (currentPlan) => _buildContent(context, ref, currentPlan),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SubscriptionPlan currentPlan) {
    return SingleChildScrollView(
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
            ref,
            SubscriptionPlan.free,
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
            currentPlan == SubscriptionPlan.free,
          ),
          const SizedBox(height: 24),
          
          _buildPlanCard(
            context,
            ref,
            SubscriptionPlan.pro,
            'PRO',
            '599',
            'Best for active job seekers',
            [
              'Unlimited AI Resume Scans',
              'Unlimited AI Mock Interviews',
              'Advanced Depth Analysis',
              'Priority AI Generation',
            ],
            AppColors.primary,
            true,
            currentPlan == SubscriptionPlan.pro,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
    String title,
    String price,
    String subtitle,
    List<String> features,
    Color color,
    bool isPopular,
    bool isCurrent,
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
                      '₹$price',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '/month',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary),
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
                  onPressed: isCurrent 
                    ? null 
                    : () {
                        if (price == '0') return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              targetPlan: plan,
                              amount: double.parse(price),
                            ),
                          ),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent 
                        ? Colors.grey.withOpacity(0.1) 
                        : (isPopular ? color : Colors.white.withOpacity(0.05)),
                    foregroundColor: Colors.white,
                    side: isPopular ? null : BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    isCurrent 
                      ? 'Current Plan' 
                      : (price == '0' ? 'Get Started' : 'Upgrade Now')
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
