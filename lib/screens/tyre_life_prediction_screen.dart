import 'package:flutter/material.dart';
import 'dart:math' as math;

class TyreLifePredictionScreen extends StatelessWidget {
  final Map<String, dynamic> predictionData;

  const TyreLifePredictionScreen({
    super.key,
    required this.predictionData,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = predictionData['recommendation'] as Map<String, dynamic>? ?? {};
    final conversation = predictionData['conversation'] as Map<String, dynamic>? ?? {};
    
    final remainingLife = recommendation['remaining_life_months'] as int? ?? 0;
    final urgencyScore = recommendation['urgency_score'] as int? ?? 0;
    final status = recommendation['status'] as String? ?? 'UNKNOWN';
    final recommendations = recommendation['recommendations'] as List? ?? [];
    final collectedData = conversation['collected_data'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tyre Life Prediction'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            _buildStatusBanner(status, urgencyScore),

            // Remaining life card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const Text(
                        'Estimated Remaining Life',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLifeCircle(remainingLife, status),
                      const SizedBox(height: 20),
                      Text(
                        '$remainingLife Months',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getEstimatedDate(remainingLife),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Urgency score
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                color: _getUrgencyColor(urgencyScore).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Urgency Level',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getUrgencyColor(urgencyScore),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getUrgencyLabel(urgencyScore),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      LinearProgressIndicator(
                        value: urgencyScore / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getUrgencyColor(urgencyScore),
                        ),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$urgencyScore / 100',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getUrgencyColor(urgencyScore),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Usage data
            if (collectedData.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Usage Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            if (collectedData['usage_hours_per_day'] != null)
                              _buildInfoRow(
                                Icons.access_time,
                                'Daily Usage',
                                '${collectedData['usage_hours_per_day']} hours',
                              ),
                            if (collectedData['months_used'] != null) ...[
                              const Divider(height: 20),
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Months Used',
                                '${collectedData['months_used']} months',
                              ),
                            ],
                            if (collectedData['vehicle_type'] != null) ...[
                              const Divider(height: 20),
                              _buildInfoRow(
                                Icons.directions_car,
                                'Vehicle Type',
                                collectedData['vehicle_type'] as String,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Recommendations
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Colors.amber[700],
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ...recommendations.asMap().entries.map((entry) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2E7D32),
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(entry.value as String),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _scheduleReplacement(context),
                    icon: const Icon(Icons.event),
                    label: const Text('Schedule Replacement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _findTyreDealer(context),
                    icon: const Icon(Icons.store),
                    label: const Text('Find Tyre Dealers'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status, int urgencyScore) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final message = _getStatusMessage(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeCircle(int months, String status) {
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter: _CircleProgressPainter(
          progress: (months / 36).clamp(0.0, 1.0),
          color: _getStatusColor(status),
        ),
        child: Center(
          child: Icon(
            Icons.tire_repair,
            size: 60,
            color: _getStatusColor(status),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'GOOD':
        return Colors.green;
      case 'CAUTION':
        return Colors.amber;
      case 'WARNING':
        return Colors.orange;
      case 'URGENT':
        return Colors.deepOrange;
      case 'CRITICAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'GOOD':
        return Icons.check_circle;
      case 'CAUTION':
        return Icons.warning_amber;
      case 'WARNING':
        return Icons.error_outline;
      case 'URGENT':
        return Icons.priority_high;
      case 'CRITICAL':
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'GOOD':
        return 'Your tyre is in good condition';
      case 'CAUTION':
        return 'Monitor your tyre closely';
      case 'WARNING':
        return 'Plan for replacement soon';
      case 'URGENT':
        return 'Replacement needed very soon';
      case 'CRITICAL':
        return 'Replace immediately for safety';
      default:
        return 'Status unknown';
    }
  }

  Color _getUrgencyColor(int score) {
    if (score >= 80) return Colors.red;
    if (score >= 60) return Colors.deepOrange;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.amber;
    return Colors.green;
  }

  String _getUrgencyLabel(int score) {
    if (score >= 80) return 'CRITICAL';
    if (score >= 60) return 'HIGH';
    if (score >= 40) return 'MODERATE';
    if (score >= 20) return 'LOW';
    return 'MINIMAL';
  }

  String _getEstimatedDate(int months) {
    final date = DateTime.now().add(Duration(days: months * 30));
    return 'Replace by: ${date.month}/${date.year}';
  }

  void _shareReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  void _scheduleReplacement(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule feature coming soon')),
    );
  }

  void _findTyreDealer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dealer finder coming soon')),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius - 10, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
