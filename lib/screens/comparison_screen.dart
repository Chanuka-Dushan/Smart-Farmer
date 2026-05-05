import 'package:flutter/material.dart';
import '../services/compatibility_service.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  String _safe(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    return value.toString();
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '-';
    return 'Rs. $value';
  }

  String _formatLifespanDifference(dynamic diff) {
    if (diff == null) return '-';
    if (diff == 0) return 'Same as original';
    if (diff > 0) return '$diff more than original';
    return '${diff.abs()} less than original';
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

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final int baseId = args['baseId'];
    final int altId = args['altId'];
    final String? baseName = args['baseName'];
    final String? altName = args['altName'];

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
                  'Failed to load comparison\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No comparison data found'),
            );
          }

          final data = snapshot.data!;
          final base = data['original_part'] ?? {};
          final alt = data['alternative_part'] ?? {};
          final comparison = data['comparison'] ?? {};
          final recommendationScores = data['recommendation_scores'] ?? {};
          final compatibilityReason =
              data['compatibility_reason']?.toString() ?? '';
          final explanation =
              (data['explanation'] as List? ?? []).map((e) => e.toString()).toList();

          final double? score =
              recommendationScores['similarity_percentage'] != null
                  ? (recommendationScores['similarity_percentage'] as num)
                      .toDouble()
                  : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _partSummaryCard(
                      title: 'Original',
                      name: base['name'] ?? baseName ?? '-',
                      machine: base['machine_model'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _partSummaryCard(
                      title: 'Alternative',
                      name: alt['name'] ?? altName ?? '-',
                      machine: alt['machine_model'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (score != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: themeGreen),
                      const SizedBox(width: 10),
                      Text(
                        'Compatibility Score: ${score.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

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
                      'Original Part',
                      'Alternative Part',
                      header: true,
                    ),
                    _buildRow('Name', base['name'], alt['name']),
                    _buildRow('Machine Model', base['machine_model'], alt['machine_model']),
                    _buildRow('Brand', base['brand'], alt['brand']),
                    _buildRow('Category', base['category'], alt['category']),
                    _buildRow('Price', _formatPrice(base['price']), _formatPrice(alt['price'])),
                    _buildRow('Diameter', base['diameter'], alt['diameter']),
                    _buildRow('Material', base['material'], alt['material']),
                    _buildRow('Lifespan', base['lifespan'], alt['lifespan']),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comparison Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _summaryRow('Same Category', comparison['same_category']),
                    _summaryRow(
                      'Same Compatibility Group',
                      comparison['same_compatibility_group'],
                    ),
                    _summaryRow('Same Name', comparison['same_name']),
                    _summaryRow('Material Match', comparison['material_match']),
                    _summaryText(
                      'Price Difference',
                      comparison['price_difference'] == null
                          ? '-'
                          : 'Rs. ${comparison['price_difference']}',
                    ),
                    _summaryText(
                      'Diameter Difference',
                      comparison['diameter_difference']?.toString() ?? '-',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (compatibilityReason.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compatibility Reason',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(compatibilityReason),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              if (explanation.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why this alternative was recommended',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...explanation.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                        'queryPartName': base['name'] ?? baseName ?? '',
                        'recommendedPartName': alt['name'] ?? altName ?? '',
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

  Widget _partSummaryCard({
    required String title,
    required String name,
    dynamic machine,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Machine: ${machine ?? '-'}'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, dynamic value) {
    String textValue = '-';
    if (value is bool) {
      textValue = value ? 'Yes' : 'No';
    } else if (value != null) {
      textValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(textValue),
        ],
      ),
    );
  }

  Widget _summaryText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}