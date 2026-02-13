import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../../models/user_model.dart';
import '../../auth_wrapper.dart';
import 'subscription_plan_screen.dart';
import 'activity_history_screen.dart';
import 'security_privacy_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentPlanAsync = ref.watch(userSubscriptionProvider);
    
    return authState.when(
      data: (user) {
        final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
        final email = user?.email ?? 'No email';
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null 
                    ? Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    : null,
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                currentPlanAsync.when(
                  data: (plan) => _buildSubscriptionCard(context, plan),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                _buildSettingsList(context, ref),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionPlan plan) {
    final bool isFree = plan == SubscriptionPlan.free;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFree 
            ? [Colors.blueGrey.shade700, Colors.blueGrey.shade900]
            : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isFree ? [] : [
          BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${plan.name.toUpperCase()} PLAN',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Icon(isFree ? Icons.person_outline : Icons.workspace_premium, color: Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isFree 
              ? 'Basic access to assessments and limited AI features.'
              : 'Unlimited AI Mock Interviews &\nATS Analysis included.',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SubscriptionPlanScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isFree ? Colors.blueGrey.shade900 : Colors.orange.shade800,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(isFree ? 'Upgrade to Pro @ ₹599' : 'Manage Subscription'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildSettingTile(Icons.history, 'Activity History', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()),
          );
        }),
        _buildSettingTile(Icons.security, 'Security & Privacy', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityPrivacyScreen()),
          );
        }),
        _buildSettingTile(Icons.help_outline, 'Help & Support', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
          );
        }),
        _buildSettingTile(
          Icons.logout, 
          'Logout', 
          () => _showLogoutConfirmation(context, ref),
          color: AppColors.error,
        ),
      ],
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await ref.read(authServiceProvider).signOut();
        
        if (context.mounted) {
          // Close loading dialog and clear all navigation stack
          // Close loading dialog and clear all navigation stack, restarting at AuthWrapper
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
