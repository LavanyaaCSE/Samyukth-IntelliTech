import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../resume/resume_screen.dart';
import '../interviews/interviews_screen.dart';
import '../institution/institution_dashboard.dart';
import '../assessments/assessment_list_screen.dart';
import 'profile_screen.dart';
import '../../core/app_colors.dart';
import '../../models/user_model.dart';

class MainScreen extends StatefulWidget {
  final UserRole role;
  const MainScreen({super.key, this.role = UserRole.student});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens {
    if (widget.role == UserRole.student) {
      return [
        const DashboardScreen(),
        const AssessmentListScreen(),
        const ResumeScreen(),
        const InterviewsScreen(),
        const ProfileScreen(),
      ];
    } else {
      return [
        const InstitutionDashboard(),
        const Center(child: Text('Batch Reports')),
        const Center(child: Text('AI Analytics')),
        const ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    if (widget.role == UserRole.student) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), activeIcon: Icon(Icons.quiz), label: 'Tests'),
        BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Resume'),
        BottomNavigationBarItem(icon: Icon(Icons.interpreter_mode_outlined), activeIcon: Icon(Icons.interpreter_mode), label: 'Interviews'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }
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
          onTap: (index) => setState(() => _selectedIndex = index),
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
