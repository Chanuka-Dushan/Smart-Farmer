import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int offerId;
  final double amount;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.offerId,
    required this.amount,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _apiService = ApiService();
  bool _isProcessing = false;
  String? _errorMessage;
  bool _stripeInitialized = false;

  
  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }
  
  Future<void> _initializeStripe() async {
    try {
      // Get publishable key
      final publishableKey = AppConfig.stripePublishableKey;
      
      // Validate key format
      if (publishableKey.isEmpty || !publishableKey.startsWith('pk_')) {
        setState(() {
          _stripeInitialized = false;
          _errorMessage = 'Invalid Stripe configuration. Please contact support.';
        });
        return;
      }
      
      // Set publishable key if not already set
      if (Stripe.publishableKey.isEmpty || Stripe.publishableKey != publishableKey) {
        Stripe.publishableKey = publishableKey;
      }
      
      // Try to apply settings - don't fail if this doesn't work
      // The actual payment operations might still work
      try {
        await Stripe.instance.applySettings();
      } on PlatformException catch (e) {
        // PlatformException during applySettings is often not critical
        // The payment sheet might still work
        print('Stripe applySettings PlatformException (non-critical): ${e.message}');
      } catch (e) {
        // Other errors are also non-critical at this stage
        print('Stripe applySettings warning (non-critical): $e');
      }
      
      // Mark as initialized if we have a valid key
      // The actual payment operations will handle any remaining issues
      setState(() {
        _stripeInitialized = true;
        _errorMessage = null; // Clear any previous errors
      });
    } catch (e) {
      // Only fail if we can't get the key at all
      setState(() {
        _stripeInitialized = false;
        _errorMessage = 'Unable to load payment configuration';
      });
      print('Stripe initialization error: $e');
    }
  }


  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Ensure Stripe publishable key is set (this is the minimum requirement)
      final publishableKey = AppConfig.stripePublishableKey;
      if (publishableKey.isEmpty || !publishableKey.startsWith('pk_')) {
        setState(() {
          _errorMessage = 'Payment service is not configured. Please contact support.';
          _isProcessing = false;
        });
        return;
      }
      
      // Set the key if not already set
      if (Stripe.publishableKey.isEmpty || Stripe.publishableKey != publishableKey) {
        Stripe.publishableKey = publishableKey;
      }
      
      // Try to apply settings if not already initialized (but don't fail if it doesn't work)
      if (!_stripeInitialized) {
        try {
          await Stripe.instance.applySettings();
          setState(() {
            _stripeInitialized = true;
          });
        } catch (e) {
          // Non-critical - we'll proceed anyway
          print('Stripe applySettings warning: $e');
        }
      }

      // Step 1: Create payment intent
      final intentData = await _apiService.createPaymentIntent(
        widget.offerId,
      );
      final clientSecret = intentData['client_secret'] as String?;
      final paymentIntentId = intentData['payment_intent_id'] as String;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Failed to get payment client secret');
      }

      // Step 2: Initialize payment sheet with Stripe SDK
      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Smart Farmer',
          ),
        );
      } on PlatformException catch (e) {
        setState(() {
          _errorMessage = 'Failed to initialize payment: ${e.message ?? e.code}';
          _isProcessing = false;
        });
        return;
      }

      // Step 3: Present payment sheet to user
      try {
        await Stripe.instance.presentPaymentSheet();
      } on StripeException catch (e) {
        // User cancelled or payment failed
        setState(() {
          _errorMessage = e.error.message ?? 'Payment was cancelled';
          _isProcessing = false;
        });
        return;
      } on PlatformException catch (e) {
        setState(() {
          _errorMessage = 'Payment error: ${e.message ?? e.code}';
          _isProcessing = false;
        });
        return;
      }

      // Step 4: Confirm payment on backend
      final result = await _apiService.confirmPayment(
        paymentIntentId,
      );

      if (!mounted) return;

      // Check if payment was successful
      if (result['success'] == true) {
        // Show success screen with animations
        if (mounted) {
          final paymentData = result['payment'] as Map<String, dynamic>?;
          final offerData = result['offer'] as Map<String, dynamic>?;

          // Get transaction ID - prefer charge ID, fallback to payment intent ID
          final transactionId = paymentData?['stripe_charge_id'] as String? ??
                               paymentData?['stripe_payment_intent_id'] as String? ??
                               paymentData?['id']?.toString();

          // Get offer acceptance status - if payment succeeded, offer should be accepted
          // Check backend response first, then fallback to assuming accepted if payment succeeded
          final offerAccepted = offerData?['accepted'] as bool? ??
                               offerData?['status'] == 'accepted' ??
                               true; // Default to true if payment succeeded
          final offerStatus = offerData?['status'] as String? ?? 'accepted';
          
          print('🔍 Payment confirmation result: $result');
          print('🔍 Payment data: $paymentData');
          print('🔍 Offer data: $offerData');
          print('🔍 Offer accepted: $offerAccepted, status: $offerStatus');
          
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                amount: widget.amount,
                transactionId: transactionId,
                paymentId: paymentData?['id']?.toString(),
                offerAccepted: offerAccepted,
                offerStatus: offerStatus,
              ),
            ),
            result: true,
          );
        }
      } else {
        // Payment is still in progress or failed
        final status = result['status'] as String?;
        final message = result['message'] as String?;
        
        if (status == 'requires_payment_method' || 
            status == 'requires_confirmation' || 
            status == 'requires_action' ||
            status == 'processing') {
          // Payment is still in progress - show message
          setState(() {
            _errorMessage = message ?? 'Payment is still being processed. Please wait.';
            _isProcessing = false;
          });
        } else {
          // Payment failed
          setState(() {
            _errorMessage = message ?? 'Payment failed. Please try again.';
            _isProcessing = false;
          });
        }
      }
    } on StripeException catch (e) {
      // Handle Stripe-specific errors
      setState(() {
        _errorMessage = e.error.message ?? 'Payment was cancelled or failed';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.payment,
              size: 80,
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Order Amount:'),
                        Text(
                          'LKR ${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Deposit (5%):'),
                        Text(
                          'LKR ${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Saved Payment Methods

            // Only show warning if there's a specific error message about initialization
            if (_errorMessage != null && _errorMessage!.contains('configuration'))
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null && _stripeInitialized)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Pay LKR ${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Note: This is a 5% deposit. The remaining amount will be paid upon delivery.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

