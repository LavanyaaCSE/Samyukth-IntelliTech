import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/app_colors.dart';
import '../../services/gemini_service.dart';
import 'interview_summary_screen.dart';

class VoiceInterviewScreen extends ConsumerStatefulWidget {
  final String mode;
  final String topic;
  final String? jobDescription;

  const VoiceInterviewScreen({
    super.key,
    required this.mode,
    required this.topic,
    this.jobDescription,
  });

  @override
  ConsumerState<VoiceInterviewScreen> createState() => _VoiceInterviewScreenState();
}

class _VoiceInterviewScreenState extends ConsumerState<VoiceInterviewScreen> {
  // Voice Services
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  
  // Interview State
  String? _currentQuestion;
  bool _isLoading = false;
  Map<String, dynamic>? _feedback;
  String? _errorMessage;
  int _questionCount = 1;
  static const int _totalQuestions = 5;
  final List<Map<String, dynamic>> _sessionHistory = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadNextQuestion();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.cancel();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    } catch (e) {
      print("Speech initialization failed: $e");
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _initSpeech(); // Retry init
      if (!_speechEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
        return;
      }
    }
    
    await _flutterTts.stop(); // Stop speaking if listening
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
      _lastWords = '';
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _feedback = null;
      _lastWords = '';
      _currentQuestion = null;
    });

    try {
      final question = await ref.read(geminiServiceProvider).generateInterviewQuestion(
            widget.mode,
            widget.topic,
            jobDescription: widget.jobDescription,
          );
      
      if (question.contains('"error"')) {
        throw "Failed to generate question. Please try again.";
      }

      setState(() {
        _currentQuestion = question;
      });
      
      // Auto-speak the question
      _speak(question);
      
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
    if (_lastWords.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record your answer first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jsonString = await ref.read(geminiServiceProvider).evaluateInterviewResponse(
            _currentQuestion!,
            _lastWords,
          );

      if (jsonString.startsWith('{')) {
        final decoded = jsonDecode(jsonString);
        
        _sessionHistory.add({
          'question': _currentQuestion,
          'answer': _lastWords,
          'rating': decoded['rating'],
          'feedback': decoded['feedback'],
          'improved_answer': decoded['improved_answer'],
        });

        setState(() {
          _feedback = decoded;
        });

        // Speak the score
        _speak("I rated your answer ${decoded['rating']} out of 10.");

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
  
  void _finishInterview() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewSummaryScreen(
          mode: widget.mode,
          topic: widget.topic,
          sessionData: _sessionHistory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode} (Voice)'),
        elevation: 0,
        actions: [
          Center(
             child: Padding(
               padding: const EdgeInsets.only(right: 16.0),
               child: Text('${_questionCount}/$_totalQuestions', 
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   if (_isLoading && _currentQuestion == null)
                     const Center(
                       child: Padding(
                         padding: EdgeInsets.all(32.0),
                         child: CircularProgressIndicator(),
                       ),
                     ),

                   if (_currentQuestion != null)
                     Container(
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(
                         color: AppColors.primary.withOpacity(0.05),
                         borderRadius: BorderRadius.circular(24),
                         border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                       ),
                       child: Column(
                         children: [
                           Text(
                             "Question",
                             style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                           ),
                           const SizedBox(height: 16),
                           Text(
                             _currentQuestion!,
                             textAlign: TextAlign.center,
                             style: GoogleFonts.outfit(fontSize: 22, height: 1.4, fontWeight: FontWeight.w600),
                           ),
                           const SizedBox(height: 16),
                           IconButton(
                             icon: const Icon(Icons.volume_up, color: AppColors.primary),
                             onPressed: () => _speak(_currentQuestion!),
                           )
                         ],
                       ),
                     ).animate().fadeIn().slideY(),

                   const SizedBox(height: 32),

                   // User Answer Display
                   if (_lastWords.isNotEmpty)
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: AppColors.surface,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: AppColors.border),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text("Your Answer:", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                           const SizedBox(height: 8),
                           Text(_lastWords, style: const TextStyle(fontSize: 16)),
                         ],
                       ),
                     ).animate().fadeIn(),

                   if (_feedback != null) ...[
                      const SizedBox(height: 32),
                      _buildFeedbackCard(),
                   ],
                ],
              ),
            ),
          ),
          
          // Bottom Controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_feedback == null && !_isLoading)
                  GestureDetector(
                    onLongPressStart: (_) => _startListening(),
                    onLongPressEnd: (_) => _stopListening(),
                    onTap: () {
                         if (_isListening) {
                           _stopListening();
                         } else {
                           _startListening();
                         }
                    },
                    child: AnimatedContainer(
                      duration: 300.ms,
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(
                             color: (_isListening ? Colors.red : AppColors.primary).withOpacity(0.4),
                             blurRadius: 20,
                             spreadRadius: 5,
                           )
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                
                if (_feedback == null && !_isLoading) ...[
                   const SizedBox(height: 16),
                   Text(
                     _isListening ? 'Listening...' : (_lastWords.isEmpty ? 'Tap to Record Response' : 'Tap to Re-record'),
                     style: GoogleFonts.outfit(color: AppColors.textSecondary),
                   ),
                   if (_lastWords.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitAnswer,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Submit Answer'),
                      )
                   ]
                ],

                if (_feedback != null)
                   ElevatedButton(
                     onPressed: () {
                        if (_questionCount < _totalQuestions) {
                          setState(() => _questionCount++);
                          _loadNextQuestion();
                        } else {
                           _finishInterview();
                        }
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.secondary,
                       foregroundColor: Colors.white,
                       minimumSize: const Size(double.infinity, 56)
                     ),
                     child: Text(_questionCount < _totalQuestions ? 'Next Question' : 'Finish Interview'),
                   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    final rating = _feedback?['rating'] ?? 0;
    final feedbackText = _feedback?['feedback'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (rating >= 7 ? Colors.green : Colors.orange).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: rating >= 7 ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(
                'AI Rating: $rating/10',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(feedbackText),
        ],
      ),
    ).animate().fadeIn().slideY();
  }
}
