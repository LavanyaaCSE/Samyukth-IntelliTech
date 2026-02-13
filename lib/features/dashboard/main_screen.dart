import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import '../resume/resume_screen.dart';
import '../interviews/interviews_screen.dart';
import '../assessments/assessment_list_screen.dart';
import '../jobs/job_search_screen.dart';
import 'profile_screen.dart';
import 'security_privacy_screen.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class MainScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const MainScreen({super.key, this.role = UserRole.student});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Check for profile completeness after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileCompleteness();
    });
  }

  Future<void> _checkProfileCompleteness() async {
    try {
      // Small delay to ensure Firestore state is settled
      await Future.delayed(const Duration(milliseconds: 500));
      
      final profile = await ref.read(authServiceProvider).getFullProfile();
      debugPrint('DEBUG: Checking profile for Security PIN. Profile exists: ${profile != null}');
      
      // 1. Check for Recovery PIN (CRITICAL for security)
      final bool hasPin = profile != null && 
                         profile['recoveryPin'] != null && 
                         profile['recoveryPin'].toString().isNotEmpty;

      debugPrint('DEBUG: Has Recovery PIN: $hasPin');

      if (!hasPin && mounted && _selectedIndex == 0) {
        debugPrint('DEBUG: Showing Recovery PIN Dialog');
        _showRecoveryPinDialog();
        return; 
      }

      // 2. Check for general profile details
      final List<String> requiredFields = [
        'college', 'degree', 'currentYear', 'passedOutYear', 'phoneNumber', 'address'
      ];

      bool isIncomplete = false;
      
      if (profile == null) {
        isIncomplete = true;
      } else {
        for (var field in requiredFields) {
          if (profile[field] == null || profile[field].toString().trim().isEmpty) {
            isIncomplete = true;
            break;
          }
        }
      }

      if (isIncomplete && mounted && _selectedIndex == 0) {
        debugPrint('DEBUG: Showing Incomplete Profile Dialog');
        _showIncompleteProfileDialog();
      }
    } catch (e) {
      debugPrint('Error in completeness check: $e');
    }
  }

  void _showRecoveryPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.security, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Setup Recovery PIN', 
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)
              ),
            ),
          ],
        ),
        content: Text(
          'You haven\'t set a Recovery PIN yet. This PIN is required to reset your password if you ever forget it. Set it up now to secure your account!',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: GoogleFonts.outfit(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SecurityPrivacyScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Setup PIN', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _showIncompleteProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('Complete Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Your profile is incomplete. Complete your academic and contact details to get better job matches and analysis!',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: GoogleFonts.outfit(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to profile settings
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SecurityPrivacyScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Complete Now', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  List<Widget> get _screens {
    return [
      const DashboardScreen(),
      const AssessmentListScreen(),
      const ResumeScreen(),
      const JobSearchScreen(),
      const InterviewsScreen(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), activeIcon: Icon(Icons.quiz), label: 'Tests'),
      BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Resume'),
      BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Jobs'),
      BottomNavigationBarItem(icon: Icon(Icons.interpreter_mode_outlined), activeIcon: Icon(Icons.interpreter_mode), label: 'Interviews'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 0) {
              _checkProfileCompleteness();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: _navItems,
        ),
      ),
    );
  }
}
