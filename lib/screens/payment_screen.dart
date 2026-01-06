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
  bool _saveCard = false;
  List<dynamic> _savedMethods = [];
  String? _selectedPaymentMethodId;
  
  @override
  void initState() {
    super.initState();
    _initializeStripe();
    _loadSavedPaymentMethods();
  }
  
  Future<void> _loadSavedPaymentMethods() async {
    try {
      final methods = await _apiService.getSavedPaymentMethods();
      setState(() {
        _savedMethods = methods;
        // Auto-select default method if available
        final defaultMethod = methods.firstWhere(
          (m) => m['is_default'] == true,
          orElse: () => methods.isNotEmpty ? methods[0] : null,
        );
        if (defaultMethod != null) {
          _selectedPaymentMethodId = defaultMethod['stripe_payment_method_id'];
        }
      });
    } catch (e) {
      // Silently fail - saved methods are optional
      print('Failed to load saved payment methods: $e');
    }
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
        saveCard: _saveCard,
        paymentMethodId: _selectedPaymentMethodId,
      );
      final clientSecret = intentData['client_secret'] as String?;
      final paymentIntentId = intentData['payment_intent_id'] as String;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Failed to get payment client secret');
      }

      // If using saved payment method, payment might be automatically confirmed
      // Otherwise, show payment sheet for new card
      if (_selectedPaymentMethodId == null) {
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
      }

      // Step 4: Confirm payment on backend
      final result = await _apiService.confirmPayment(
        paymentIntentId,
        saveCard: _saveCard,
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
          
          // Get offer acceptance status
          final offerAccepted = offerData?['accepted'] as bool? ?? false;
          final offerStatus = offerData?['status'] as String?;
          
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
            if (_savedMethods.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved Payment Methods',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._savedMethods.map((method) {
                        final isSelected = _selectedPaymentMethodId == method['stripe_payment_method_id'];
                        final brand = method['card_brand'] ?? 'card';
                        final last4 = method['card_last4'] ?? '****';
                        final expMonth = method['card_exp_month'] ?? 0;
                        final expYear = method['card_exp_year'] ?? 0;
                        final isDefault = method['is_default'] == true;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPaymentMethodId = method['stripe_payment_method_id'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected ? Colors.green[50] : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.credit_card,
                                  color: const Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${brand.toUpperCase()} •••• $last4',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Expires ${expMonth.toString().padLeft(2, '0')}/${expYear.toString().substring(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'DEFAULT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedPaymentMethodId = null;
                          });
                        },
                        icon: const Icon(Icons.add_card),
                        label: const Text('Use New Card'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
            // Save card checkbox (only show if using new card)
            if (_selectedPaymentMethodId == null)
              Card(
                child: CheckboxListTile(
                  title: const Text('Save card for future payments'),
                  subtitle: const Text('Your card will be securely saved for faster checkout'),
                  value: _saveCard,
                  onChanged: (value) {
                    setState(() {
                      _saveCard = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF2E7D32),
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

