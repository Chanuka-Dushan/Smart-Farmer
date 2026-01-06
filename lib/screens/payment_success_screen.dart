import 'package:flutter/material.dart';
import 'dart:math' as math;

class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String? transactionId;
  final String? paymentId;
  final bool offerAccepted;
  final String? offerStatus;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    this.transactionId,
    this.paymentId,
    this.offerAccepted = false,
    this.offerStatus,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for checkmark
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Rotation animation for confetti
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ),
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatTransactionId(String id) {
    if (id.isEmpty || id == 'N/A') return 'N/A';
    // If it's a Stripe ID, show last 8 characters
    if (id.startsWith('ch_') || id.startsWith('pi_')) {
      return id.length > 8 ? '...${id.substring(id.length - 8)}' : id;
    }
    // If it's numeric (payment ID), show as is
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(_rotationAnimation.value),
                  size: Size.infinite,
                );
              },
            ),
            // Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Success icon with scale animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Success message
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            const Text(
                              'Payment Successful!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'LKR ${widget.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.offerAccepted
                                  ? 'Your deposit has been processed and offer has been accepted!'
                                  : 'Your deposit has been processed',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Details card
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  Icons.receipt,
                                  'Transaction ID',
                                  _formatTransactionId(widget.transactionId ?? widget.paymentId ?? 'N/A'),
                                ),
                                const Divider(height: 32),
                                _buildDetailRow(
                                  Icons.payment,
                                  'Payment Status',
                                  'Completed',
                                  isStatus: true,
                                  statusColor: Colors.green,
                                ),
                                const Divider(height: 32),
                                _buildDetailRow(
                                  Icons.check_circle_outline,
                                  'Offer Status',
                                  widget.offerAccepted 
                                      ? 'Accepted' 
                                      : (widget.offerStatus?.toUpperCase() ?? 'Processing'),
                                  isStatus: true,
                                  statusColor: widget.offerAccepted ? Colors.green : Colors.orange,
                                ),
                                const Divider(height: 32),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'Date',
                                  DateTime.now().toString().split('.')[0],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Action buttons
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1400),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: child,
                          );
                        },
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Done'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                // Navigate back and then to order details if offer is accepted
                                Navigator.pop(context, true);
                                // The parent screen should handle navigation to order details
                              },
                              child: const Text('View Order Details'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool isStatus = false, Color? statusColor}) {
    final displayColor = isStatus 
        ? (statusColor ?? Colors.green)
        : const Color(0xFF2E7D32);
    
    return Row(
      children: [
        Icon(icon, color: displayColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isStatus ? displayColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final double rotation;

  ConfettiPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20) * i;
      final y = size.height * (0.2 + (i % 3) * 0.3);
      final colorIndex = i % 4;
      final colors = [
        Colors.green,
        Colors.blue,
        Colors.orange,
        Colors.purple,
      ];
      paint.color = colors[colorIndex].withOpacity(0.3);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation + (i * 0.5));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 8,
          height: 8,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

