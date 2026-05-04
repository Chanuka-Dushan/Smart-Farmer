import 'package:flutter/material.dart';
import '../services/compatibility_service.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  String _safe(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    return value.toString();
  }

  String _formatPrice(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    return 'Rs. $value';
  }

  String _formatPercentage(dynamic value) {
    if (value == null) return '-';

    double? number;
    if (value is num) {
      number = value.toDouble();
    } else {
      number = double.tryParse(value.toString());
    }

    if (number == null) return '-';

    if (number > 0 && number <= 1) {
      number = number * 100;
    }

    return '${number.toStringAsFixed(2)}%';
  }

  String _formatBoolean(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  String _cleanFieldName(String value) {
    return value.replaceAll('_', ' ').toUpperCase();
  }

  String _formatDifference(dynamic value) {
    if (value == null) return '-';

    if (value is Map) {
      final summary = value['summary'];
      final original = value['original'];
      final recommended = value['recommended'];
      final difference = value['difference'];

      if (summary != null && summary.toString().trim().isNotEmpty) {
        return summary.toString();
      }

      if (original != null || recommended != null) {
        return '${original ?? '-'} → ${recommended ?? '-'}';
      }

      if (difference != null) {
        return difference.toString();
      }
    }

    return value.toString();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }

    return {};
  }

  List<String> _extractExplanationList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is Map) {
      final notes = value['notes'];
      final why = value['why_recommended'];

      final result = <String>[];

      if (why != null && why.toString().trim().isNotEmpty) {
        result.add(why.toString());
      }

      if (notes is List) {
        result.addAll(notes.map((e) => e.toString()));
      }

      return result;
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }

    return [];
  }

  TableRow _buildRow(
    String label,
    dynamic baseValue,
    dynamic altValue, {
    bool header = false,
  }) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.bold : FontWeight.w500,
      color: header ? Colors.black : null,
    );

    return TableRow(
      decoration:
          header ? const BoxDecoration(color: Color(0xFFE8F5E9)) : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(label, style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_safe(baseValue), style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_safe(altValue), style: style),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(_formatBoolean(value)),
        ],
      ),
    );
  }

  Widget _summaryText(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              _safe(value),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _partCard({
    required String title,
    required String name,
    required String machine,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Machine: $machine',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(Map<String, dynamic> scores, Map<String, dynamic> data) {
    final finalScore = scores['final_score'] ??
        scores['compatibility_score'] ??
        scores['similarity_percentage'] ??
        data['final_score'] ??
        data['compatibility_score'];

    final similarityScore = scores['similarity_score'] ??
        scores['vector_similarity_score'] ??
        data['similarity_score'] ??
        data['vector_similarity_score'];

    final mlScore = scores['ml_score'] ?? scores['rf_score'] ?? data['ml_score'];

    final feedbackScore = scores['feedback_score'] ?? data['feedback_score'];

    if (finalScore == null &&
        similarityScore == null &&
        mlScore == null &&
        feedbackScore == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Hybrid Compatibility Score',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (finalScore != null)
            _summaryText('Final Score', _formatPercentage(finalScore)),
          if (similarityScore != null)
            _summaryText(
              'Vector Similarity',
              _formatPercentage(similarityScore),
            ),
          if (mlScore != null)
            _summaryText('ML Score', _formatPercentage(mlScore)),
          if (feedbackScore != null)
            _summaryText('Feedback Score', _formatPercentage(feedbackScore)),
        ],
      ),
    );
  }

  Widget _differencesCard(Map<String, dynamic> differences) {
    if (differences.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Differences',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...differences.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${_cleanFieldName(entry.key)}:',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDifference(entry.value),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesCard({
    required String title,
    required String text,
    required Color color,
    required IconData icon,
  }) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(text),
        ],
      ),
    );
  }

  Widget _missingArgumentsScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparison View'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs is! Map<String, dynamic>) {
      return _missingArgumentsScreen(
        context,
        'Comparison data is missing.\n\nPlease go back to Alternative Parts and click Compare again.\n\nDo not refresh or open /comparison directly.',
      );
    }

    final int baseId = (rawArgs['baseId'] as num?)?.toInt() ?? 0;
    final int altId = (rawArgs['altId'] as num?)?.toInt() ?? 0;
    final String baseName = rawArgs['baseName']?.toString() ?? 'Original Part';
    final String altName = rawArgs['altName']?.toString() ?? 'Alternative Part';

    print('COMPARISON SCREEN BASE ID: $baseId');
    print('COMPARISON SCREEN ALT ID: $altId');

    if (baseId == 0 || altId == 0) {
      return _missingArgumentsScreen(
        context,
        'Original part ID or alternative part ID is missing.\n\nBase ID: $baseId\nAlternative ID: $altId\n\nPlease go back to Alternative Parts and click Compare again.',
      );
    }

    const themeGreen = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparison View'),
        backgroundColor: themeGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: CompatibilityService.fetchComparison(
          baseId: baseId,
          altId: altId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load comparison data\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No comparison data found.'),
            );
          }

          final data = snapshot.data!;

          final base = _asMap(
            data['original_part'] ??
                data['base_part'] ??
                data['query_part'] ??
                {},
          );

          final alt = _asMap(
            data['alternative_part'] ??
                data['recommended_part'] ??
                {},
          );

          final comparison = _asMap(
            data['comparison'] ??
                data['difference'] ??
                data['differences'] ??
                {},
          );

          final scores = _asMap(
            data['recommendation_scores'] ?? data['scores'] ?? {},
          );

          final differences = _asMap(
            data['differences'] ??
                data['difference_details'] ??
                comparison,
          );

          final explanationList = _extractExplanationList(data['explanation']);

          final compatibilityReason =
              data['compatibility_reason']?.toString() ??
                  data['why_recommended']?.toString() ??
                  '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _partCard(
                      title: 'Original Part',
                      name: _safe(base['name'] ?? baseName),
                      machine: _safe(base['machine_model']),
                      color: Colors.teal.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _partCard(
                      title: 'Alternative Part',
                      name: _safe(alt['name'] ?? altName),
                      machine: _safe(alt['machine_model']),
                      color: Colors.green.shade50,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _scoreCard(scores, data),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Table(
                  border: TableBorder.all(color: Colors.green.shade200),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(3),
                  },
                  children: [
                    _buildRow(
                      'Attribute',
                      'Original',
                      'Alternative',
                      header: true,
                    ),
                    _buildRow(
                      'Name',
                      base['name'] ?? baseName,
                      alt['name'] ?? altName,
                    ),
                    _buildRow(
                      'Machine Model',
                      base['machine_model'],
                      alt['machine_model'],
                    ),
                    _buildRow('Brand', base['brand'], alt['brand']),
                    _buildRow('Category', base['category'], alt['category']),
                    _buildRow(
                      'Machine Family',
                      base['machine_family'],
                      alt['machine_family'],
                    ),
                    _buildRow(
                      'Function Type',
                      base['function_type'],
                      alt['function_type'],
                    ),
                    _buildRow(
                      'Compatibility Group',
                      base['compatibility_group'],
                      alt['compatibility_group'],
                    ),
                    _buildRow(
                      'Price',
                      _formatPrice(base['price']),
                      _formatPrice(alt['price']),
                    ),
                    _buildRow('Material', base['material'], alt['material']),
                    _buildRow('Diameter', base['diameter'], alt['diameter']),
                    _buildRow('Lifespan', base['lifespan'], alt['lifespan']),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (comparison.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compatibility Rule Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (comparison.containsKey('same_category'))
                        _summaryRow(
                          'Same Category',
                          comparison['same_category'],
                        ),
                      if (comparison.containsKey('same_machine_family'))
                        _summaryRow(
                          'Same Machine Family',
                          comparison['same_machine_family'],
                        ),
                      if (comparison.containsKey('same_compatibility_group'))
                        _summaryRow(
                          'Same Compatibility Group',
                          comparison['same_compatibility_group'],
                        ),
                      if (comparison.containsKey('same_function_type'))
                        _summaryRow(
                          'Same Function Type',
                          comparison['same_function_type'],
                        ),
                      if (comparison.containsKey('material_match'))
                        _summaryRow(
                          'Material Match',
                          comparison['material_match'],
                        ),
                      if (comparison.containsKey('price_difference'))
                        _summaryText(
                          'Price Difference',
                          _formatPrice(comparison['price_difference']),
                        ),
                      if (comparison.containsKey('lifespan_difference'))
                        _summaryText(
                          'Lifespan Difference',
                          comparison['lifespan_difference'],
                        ),
                      if (comparison.containsKey('diameter_difference'))
                        _summaryText(
                          'Diameter Difference',
                          comparison['diameter_difference'],
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              _differencesCard(differences),

              const SizedBox(height: 16),

              _notesCard(
                title: 'Compatibility Reason',
                text: compatibilityReason,
                color: Colors.orange.shade50,
                icon: Icons.info_outline,
              ),

              if (explanationList.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Explanation Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...explanationList.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $item'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/feedback',
                      arguments: {
                        'queryPartId': base['id'] ?? baseId,
                        'recommendedPartId': alt['id'] ?? altId,
                        'queryPartName': base['name'] ?? baseName,
                        'recommendedPartName': alt['name'] ?? altName,
                      },
                    );
                  },
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text('Add Feedback'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}