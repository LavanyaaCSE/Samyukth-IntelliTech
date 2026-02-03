import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import 'active_interview_screen.dart';
import 'voice_interview_screen.dart'; // Will create this next

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key});

  @override
  State<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInterviewSetup(BuildContext context, String mode, {bool isVoice = false}) {
    final topicController = TextEditingController();
    final jdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${isVoice ? 'Voice ' : ''}$mode', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVoice 
                  ? 'Speak your answers in this real-time voice interview simulation.'
                  : 'Enter the details below to customize your AI interview session.',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Job Role / Topic',
                hintText: 'e.g. Senior Flutter Developer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jdController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Job Description (Optional)',
                hintText: 'Paste the JD here for tailored questions...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (topicController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a Job Role or Topic')),
                );
                return;
              }
              Navigator.pop(context);
              
              if (isVoice) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceInterviewScreen(
                      mode: mode,
                      topic: topicController.text.trim(),
                      jobDescription: jdController.text.trim().isEmpty ? null : jdController.text.trim(),
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveInterviewScreen(
                      mode: mode,
                      topic: topicController.text.trim(),
                      jobDescription: jdController.text.trim().isEmpty ? null : jdController.text.trim(),
                    ),
                  ),
                );
              }
            },
            child: const Text('Start Interview'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mock Interviews'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Text Interview', icon: Icon(Icons.chat_bubble_outline)),
            Tab(text: 'Voice Interview', icon: Icon(Icons.mic_none)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInterviewList(isVoice: false),
          _buildInterviewList(isVoice: true),
        ],
      ),
    );
  }

  Widget _buildInterviewList({required bool isVoice}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVoice ? 'Speak with AI' : 'Practice makes perfect',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isVoice 
                  ? 'Experience a real-time conversational interview.'
                  : 'Select a mode to start your text-based interview session.',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildInterviewModeCard(
              context,
              'HR Interview',
              'Behavioral & Culture Fit',
              Icons.people_outline,
              AppColors.primary,
              isVoice: isVoice,
            ),
            const SizedBox(height: 16),
            _buildInterviewModeCard(
              context,
              'Technical Interview',
              'Data Structures, Algorithms & Dev',
              Icons.code,
              AppColors.secondary,
              isVoice: isVoice,
            ),
            const SizedBox(height: 16),
            _buildInterviewModeCard(
              context,
              'Managerial Interview',
              'Problem solving & Leadership',
              Icons.assignment_ind_outlined,
              AppColors.accent,
              isVoice: isVoice,
            ),
            const SizedBox(height: 32),
            _buildRecentFeedback(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewModeCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    {required bool isVoice}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInterviewSetup(context, title, isVoice: isVoice),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(isVoice ? Icons.mic : icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildRecentFeedback() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Text(
                'Recent Performance',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your communication clarity has improved by 15% in the last 3 sessions. Keep it up!',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
