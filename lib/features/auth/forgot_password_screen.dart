import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  int _currentStep = 0; // 0: Email, 1: PIN Verification, 2: New Password
  bool _isLoading = false;

  Future<void> _checkEmail() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email address');
      return;
    }
    setState(() => _currentStep = 1);
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.isEmpty) {
      _showError('Please enter your 4-digit Recovery PIN');
      return;
    }
    
    setState(() => _isLoading = true);
    final isValid = await ref.read(authServiceProvider).verifyRecoveryPin(
      _emailController.text.trim(),
      _pinController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (isValid) {
      _showSuccess('PIN Verified!');
      setState(() => _currentStep = 2);
    } else {
      _showError('Incorrect Recovery PIN. Please try again.');
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // In a prototype/demo, we simulate the password update
      await Future.delayed(const Duration(seconds: 1)); 
      _showSuccess('Password updated successfully! Please login.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error resetting password: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.05)),
            ),
          ).animate().fadeIn(duration: 1000.ms).scale(begin: const Offset(0.5, 0.5)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildCurrentStepView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Recovery';
    String subtitle = 'Enter your email to start recovery.';
    
    if (_currentStep == 1) {
      title = 'Verify PIN';
      subtitle = 'Enter the 4-digit Recovery PIN you set in your profile.';
    } else if (_currentStep == 2) {
      title = 'New Password';
      subtitle = 'Choose a secure password for your account.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -1),
        ).animate(key: ValueKey(_currentStep)).fadeIn().slideX(begin: -0.1),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
        ).animate(key: ValueKey('sub$_currentStep')).fadeIn(delay: 200.ms).slideX(begin: -0.1),
      ],
    );
  }

  Widget _buildCurrentStepView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentStep),
        child: _currentStep == 0 
          ? _buildEmailStep() 
          : _currentStep == 1 
            ? _buildPinStep() 
            : _buildPasswordStep(),
      ),
    );
  }

  Widget _buildEmailStep() {
    return _buildContainer(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address', 
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'user@example.com',
          ),
        ),
        const SizedBox(height: 32),
        _buildButton('Continue to PIN Verification', _checkEmail),
      ],
    );
  }

  Widget _buildPinStep() {
    return _buildContainer(
      children: [
        TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'Recovery PIN', 
            prefixIcon: Icon(Icons.security_outlined), 
            hintText: 'Enter 4 digits',
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() => _currentStep = 0), 
          child: const Text('Back to email'),
        ),
        const SizedBox(height: 32),
        _buildButton('Verify PIN', _verifyPin),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return _buildContainer(
      children: [
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_reset_outlined)),
        ),
        const SizedBox(height: 32),
        _buildButton('Reset Password', _resetPassword),
      ],
    );
  }

  Widget _buildContainer({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : Text(text),
      ),
    );
  }
}
