import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/gemini_service.dart';

class ActiveInterviewScreen extends ConsumerStatefulWidget {
  final String mode;
  final String topic;

  const ActiveInterviewScreen({
    super.key,
    required this.mode,
    required this.topic,
  });

  @override
  ConsumerState<ActiveInterviewScreen> createState() => _ActiveInterviewScreenState();
}

class _ActiveInterviewScreenState extends ConsumerState<ActiveInterviewScreen> {
  String? _currentQuestion;
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _feedback;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _feedback = null;
      _answerController.clear();
      _currentQuestion = null;
    });

    try {
      final question = await ref.read(geminiServiceProvider).generateInterviewQuestion(
            widget.mode,
            widget.topic,
          );
      
      if (question.contains('"error"')) {
        throw "Failed to generate question. Please try again.";
      }

      setState(() {
        _currentQuestion = question;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jsonString = await ref.read(geminiServiceProvider).evaluateInterviewResponse(
            _currentQuestion!,
            _answerController.text.trim(),
          );

      if (jsonString.startsWith('{')) {
        final decoded = jsonDecode(jsonString);
        setState(() {
          _feedback = decoded;
        });
      } else {
        throw "Invalid response format from AI";
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = "Evaluation failed: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode} Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

             if (_isLoading && _currentQuestion == null)
               const Center(
                 child: Padding(
                   padding: EdgeInsets.all(48.0),
                   child: Column(
                     children: [
                       CircularProgressIndicator(),
                       SizedBox(height: 16),
                       Text('AI is preparing your question...'),
                     ],
                   ),
                 ),
               ),

            if (_currentQuestion != null) ...[
              Text(
                'Question:',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _currentQuestion!,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 32),
            ],

            if (_currentQuestion != null && _feedback == null) ...[
              TextField(
                controller: _answerController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Answer'),
              ),
            ],

            if (_feedback != null) ...[
              _buildFeedbackCard(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadNextQuestion,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Question'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    final rating = _feedback?['rating'] ?? 0;
    final feedbackText = _feedback?['feedback'] ?? '';
    final improved = _feedback?['improved_answer'] ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Feedback',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (rating >= 7 ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: $rating/10',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rating >= 7 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            feedbackText,
            style: const TextStyle(height: 1.5),
          ),
          if (improved.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Better Answer:',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              improved,
              style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
