import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/interview_service.dart';
import '../../services/auth_service.dart';
import '../../models/interview_session.dart';
import 'interview_history_detail_screen.dart';

class InterviewHistoryScreen extends ConsumerWidget {
  final bool? isVoice;
  const InterviewHistoryScreen({super.key, this.isVoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view history')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isVoice == null 
            ? 'Interview History' 
            : (isVoice! ? 'Voice Interview History' : 'Text Interview History')),
      ),
      body: StreamBuilder<List<InterviewSession>>(
        stream: ref.watch(interviewServiceProvider).getUserHistory(user.uid, isVoice: isVoice),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No interview history yet',
                    style: GoogleFonts.outfit(fontSize: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _HistoryCard(session: session);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final InterviewSession session;

  const _HistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(session.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InterviewHistoryDetailScreen(session: session),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (session.isVoice ? AppColors.secondary : AppColors.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    session.isVoice ? Icons.mic : Icons.chat_bubble_outline,
                    color: session.isVoice ? AppColors.secondary : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.mode,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        session.topic,
                        style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(session.averageScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${session.averageScore.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      color: _getScoreColor(session.averageScore),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 50.ms).slideX();
  }

  Color _getScoreColor(double score) {
    if (score >= 7) return Colors.green;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }
}
