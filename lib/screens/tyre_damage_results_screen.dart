import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';
import 'tyre_voice_chat_realtime_screen.dart';
import 'tyre_text_chat_screen.dart';

class TyreDamageResultsScreen extends StatefulWidget {
  final Map<String, dynamic> detectionResult;
  final File originalImage;

  const TyreDamageResultsScreen({
    super.key,
    required this.detectionResult,
    required this.originalImage,
  });

  @override
  State<TyreDamageResultsScreen> createState() => _TyreDamageResultsScreenState();
}

class _TyreDamageResultsScreenState extends State<TyreDamageResultsScreen> {
  bool _showingAnnotated = false;

  @override
  Widget build(BuildContext context) {
    final detections = widget.detectionResult['detections'] as List? ?? [];
    final primaryDamage = widget.detectionResult['primary_damage'] as Map<String, dynamic>?;
    final model = widget.detectionResult['model'] as String? ?? 'Unknown';
    final detectionsCount = widget.detectionResult['detections_count'] as int? ?? 0;
    final annotatedBase64 = widget.detectionResult['annotated_image_base64'] as String?;
    final hasAnnotatedImage = annotatedBase64 != null && annotatedBase64.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Results'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (hasAnnotatedImage)
            IconButton(
              icon: Icon(_showingAnnotated ? Icons.image : Icons.insights),
              onPressed: () {
                setState(() {
                  _showingAnnotated = !_showingAnnotated;
                });
              },
              tooltip: _showingAnnotated ? 'Show Original' : 'Show Annotated',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image display
            Stack(
              children: [
                _showingAnnotated && hasAnnotatedImage
                    ? Image.memory(
                        base64Decode(annotatedBase64),
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        widget.originalImage,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                if (hasAnnotatedImage)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _showingAnnotated ? 'Annotated' : 'Original',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Detection count badge
            Container(
              padding: const EdgeInsets.all(20),
              color: detectionsCount == 0 ? Colors.green[50] : Colors.orange[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    detectionsCount == 0 ? Icons.check_circle : Icons.warning_amber,
                    color: detectionsCount == 0 ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    detectionsCount == 0
                        ? 'No Damage Detected'
                        : '$detectionsCount Damage(s) Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: detectionsCount == 0 ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),

            // Primary damage card
            if (primaryDamage != null) ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.priority_high, color: Colors.red, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'Primary Damage',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 25),
                        _buildDetailRow(
                          'Type',
                          _formatDamageType(primaryDamage['damage_type'] as String? ?? 'Unknown'),
                          Icons.category,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Confidence',
                          '${((primaryDamage['confidence'] as num? ?? 0) * 100).toStringAsFixed(1)}%',
                          Icons.verified,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Severity',
                          _formatSeverity(primaryDamage['severity'] as String? ?? 'unknown'),
                          Icons.emergency,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Lifespan Impact',
                          '${((primaryDamage['lifespan_reduction'] as num? ?? 0) * 100).toStringAsFixed(0)}% reduction',
                          Icons.trending_down,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Chat options buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Voice chat button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TyreVoiceChatRealtimeScreen(
                              damageInfo: primaryDamage,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text('හඬ සංවාදය (Voice Chat)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Text chat button (fallback)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TyreTextChatScreen(
                              damageInfo: primaryDamage,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('මුකුත කථාවක් (Text Chat)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // All detections list
            if (detectionsCount > 1) ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Detections',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...detections.map((detection) {
                      final damageData = detection as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getSeverityColor(damageData['severity'] as String? ?? 'unknown'),
                            child: const Icon(Icons.error_outline, color: Colors.white),
                          ),
                          title: Text(_formatDamageType(damageData['damage_type'] as String? ?? 'Unknown')),
                          subtitle: Text(
                            '${((damageData['confidence'] as num? ?? 0) * 100).toStringAsFixed(1)}% confidence',
                          ),
                          trailing: Chip(
                            label: Text(
                              _formatSeverity(damageData['severity'] as String? ?? 'unknown'),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            backgroundColor: _getSeverityColor(damageData['severity'] as String? ?? 'unknown'),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            // Model info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Analysis Model: $model',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDamageType(String type) {
    final formatted = type.replaceAll('_', ' ');
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  String _formatSeverity(String severity) {
    return severity.toUpperCase();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'severe':
        return Colors.deepOrange;
      case 'moderate':
        return Colors.orange;
      case 'minor':
        return Colors.amber;
      case 'good':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
