import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../models/assessment.dart';
import 'assessment_result_screen.dart';

class ActiveAssessmentScreen extends StatefulWidget {
  final Assessment assessment;
  const ActiveAssessmentScreen({super.key, required this.assessment});

  @override
  State<ActiveAssessmentScreen> createState() => _ActiveAssessmentScreenState();
}

class _ActiveAssessmentScreenState extends State<ActiveAssessmentScreen> with WidgetsBindingObserver {
  late Timer _timer;
  int _secondsRemaining = 0;
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {};
  bool _isFinished = false;
  bool _isEvaluating = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsRemaining = widget.assessment.durationMinutes * 60;
    _startTimer();
    
    // Anti-cheat: Lock orientation (In real app)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Anti-cheat: Screenshot detection (Removed)
    // _initScreenshotDetection();
  }



  @override
  void dispose() {
    _timer.cancel();

    WidgetsBinding.instance.removeObserver(this);
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) && !_isFinished && !_isEvaluating) {
      // Anti-cheat: Auto-submit on background or losing focus
      _autoSubmit(reason: "App background or multitasking detected. Test ended for security.");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _autoSubmit(reason: "Time's up! Your answers have been saved.");
      }
    });
  }

  void _autoSubmit({required String reason}) {
    if (_isFinished || _isEvaluating) return;
    _timer.cancel();
    _submitAssessment(auto: true, reason: reason);
  }

  Future<void> _submitAssessment({bool auto = false, String? reason}) async {
    if (_isEvaluating) return;

    if (!auto) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Submission'),
          content: const Text('Are you sure you want to finish the test? Your answers will be locked.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _isEvaluating = true;
    });

    // Simulate backend evaluation
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isFinished = true;
        _isEvaluating = false;
      });
      
      _showResultDialog(reason);
    }
  }

  void _showResultDialog(String? reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason ?? 'Your assessment has been successfully submitted and is under evaluation.'),
            const SizedBox(height: 16),
            const Text('Final evaluation will be available on your dashboard shortly.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AssessmentResultScreen(
                    assessment: widget.assessment,
                    userAnswers: _selectedAnswers,
                  ),
                ),
              );
            },
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isEvaluating) {
      return _buildEvaluationScreen();
    }

    final question = widget.assessment.questions[_currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _autoSubmit(reason: "Back navigation detected. Test auto-submitted for security.");
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        drawer: _buildQuestionDrawer(),
        body: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: _buildQuestionArea(question),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActions(),
      ),
    ).animate().fadeIn();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.grid_view),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.assessment.title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(
            widget.assessment.questions[_currentQuestionIndex].section,
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        _buildTimer(),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Warning: Multiple browser tabs or app switches will lead to auto-submission.')),
            );
          },
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    final isLowTime = _secondsRemaining < 300; // Under 5 mins
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isLowTime ? AppColors.error.withOpacity(0.1) : Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLowTime ? AppColors.error : Colors.white24),
      ),
      child: Center(
        child: Text(
          _formatTime(_secondsRemaining),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isLowTime ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentQuestionIndex + 1) / widget.assessment.questions.length;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.white10,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
    );
  }

  Widget _buildQuestionArea(Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${widget.assessment.questions.length}',
                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(question.difficulty).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  question.difficulty.toUpperCase(),
                  style: TextStyle(color: _getDifficultyColor(question.difficulty), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.text,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 32),
          ...List.generate(question.options.length, (index) {
            final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
            return _buildOptionTile(index, question.options[index], isSelected);
          }),
        ],
      ),
    );
  }

  Widget _buildOptionTile(int index, String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAnswers[_currentQuestionIndex] = index; // Auto-save logic
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.textMuted),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final isLast = _currentQuestionIndex == widget.assessment.questions.length - 1;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (_selectedAnswers.containsKey(_currentQuestionIndex))
            TextButton(
              onPressed: () => setState(() => _selectedAnswers.remove(_currentQuestionIndex)),
              child: const Text('Clear Selection', style: TextStyle(color: Colors.grey)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: isLast ? () => _submitAssessment() : () {
              setState(() {
                _currentQuestionIndex++;
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 56),
              backgroundColor: isLast ? AppColors.secondary : AppColors.primary,
            ),
            child: Text(isLast ? 'Submit Test' : 'Save & Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Question Palette', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: widget.assessment.questions.length,
                itemBuilder: (context, index) {
                  final isAnswered = _selectedAnswers.containsKey(index);
                  final isCurrent = _currentQuestionIndex == index;
                  
                  return InkWell(
                    onTap: () {
                      setState(() => _currentQuestionIndex = index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent 
                          ? AppColors.primary 
                          : isAnswered ? AppColors.secondary.withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: isAnswered ? Border.all(color: AppColors.secondary) : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrent || isAnswered ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildLegendItem(AppColors.secondary, 'Answered'),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.white10, 'Not Answered'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEvaluationScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 32),
            Text(
              'Evaluating your test...',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Checking submissions and anti-cheat logs.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return AppColors.secondary;
      case 'medium': return AppColors.accent;
      case 'hard': return AppColors.error;
      default: return Colors.grey;
    }
  }
}
