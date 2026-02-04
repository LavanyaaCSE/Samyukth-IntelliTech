
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_colors.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final SubscriptionPlan targetPlan;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.targetPlan,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Setup listeners
    Future.microtask(() {
      final paymentService = ref.read(paymentServiceProvider);
      paymentService.onPaymentSuccess = _onPaymentSuccess;
      paymentService.onPaymentError = _onPaymentError;
    });
  }

  void _onPaymentSuccess(String paymentId) {
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });

    // Wait and go back
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context, true);
        Navigator.pop(context, true);
      }
    });
  }

  void _onPaymentError(String message) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _handlePayment() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    ref.read(paymentServiceProvider).startPayment(
      amount: widget.amount,
      userEmail: user.email ?? '',
      userPhone: '9876543210', // Default placeholder for testing
      description: 'IntelliTrain ${widget.targetPlan.name.toUpperCase()} Plan Upgrade',
    );
  }

  @override
  void dispose() {
    // We don't dispose the service here because it's a provider, 
    // but we can clear the callbacks
    final paymentService = ref.read(paymentServiceProvider);
    paymentService.onPaymentSuccess = null;
    paymentService.onPaymentError = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessOverlay();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Secure Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).blur(begin: const Offset(5, 5), end: const Offset(15, 15), duration: 3.seconds),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummary(),
                const SizedBox(height: 32),
                Text(
                  'Complete Your Payment',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildBenefitsCard(),
                const Spacer(),
                _buildPayButton(),
              ],
            ),
          ),
          
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.targetPlan.name.toUpperCase()} Plan',
                    style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Full Pro Access',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.workspace_premium, color: AppColors.primary, size: 32),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              Text(
                '₹${widget.amount.toInt()}',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildBenefitRow(Icons.check_circle, 'Full Access to Mock Interviews'),
          const SizedBox(height: 12),
          _buildBenefitRow(Icons.check_circle, 'Advanced Performance Analytics'),
          const SizedBox(height: 12),
          _buildBenefitRow(Icons.check_circle, 'Priority Support'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
        ],
      ),
      child: ElevatedButton(
        onPressed: _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          'Pay ₹${widget.amount.toInt()} with Razorpay',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds);
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            const Text('Opening Payment Gateway...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 64),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 32),
            Text('Upgrade Successful!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Welcome to Pro Access', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
