
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'subscription_service.dart';
import 'auth_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref);
});

class PaymentService {
  final Ref _ref;
  late Razorpay _razorpay;
  
  // Replace with your real Razorpay ID
  static const String _razorpayKeyId = 'rzp_test_SC2QWzu3JdamD5';

  Function(String)? onPaymentSuccess;
  Function(String)? onPaymentError;

  PaymentService(this._ref) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void startPayment({
    required double amount,
    required String userEmail,
    required String userPhone,
    required String description,
  }) {
    var options = {
      'key': _razorpayKeyId,
      'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
      'name': 'IntelliTrain',
      'description': description,
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      onPaymentError?.call(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');
    
    // In a real app, you would verify this on the server
    // For now, we update the subscription status directly
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await _ref.read(subscriptionServiceProvider).upgradeToPro(user.uid);
    }
    
    onPaymentSuccess?.call(response.paymentId!);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    onPaymentError?.call(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet Selected: ${response.walletName}');
  }
}
