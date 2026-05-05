import 'package:flutter/material.dart';
import '../models/compatibility_models.dart';
import '../services/compatibility_service.dart';

class AlternativePartsScreen extends StatelessWidget {
  const AlternativePartsScreen({super.key});

  String getQualityTag(double score) {
    if (score >= 90) return "BEST";
    if (score >= 80) return "BETTER";
    return "GOOD";
  }

  Color getTagColor(double score) {
    if (score >= 90) return Colors.green.shade100;
    if (score >= 80) return Colors.orange.shade100;
    return Colors.blue.shade100;
  }

  Color getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.orange;
    return Colors.blue;
  }

  String formatPercentage(double? value) {
    if (value == null || value <= 0) return '';
    final percentage = value <= 1 ? value * 100 : value;
    return '${percentage.toStringAsFixed(0)}%';
  }

  String cleanFieldName(String field) {
    return field.replaceAll('_', ' ').toUpperCase();
  }

  int _readIntArg(Map<String, dynamic> args, List<String> keys) {
    for (final key in keys) {
      final value = args[key];

      if (value == null) continue;

      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();

      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }

    return 0;
  }

  String _readStringArg(
    Map<String, dynamic> args,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = args[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Invalid navigation data. Please go back and search the part again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final int routePartId = _readIntArg(
      rawArgs,
      ['partId', 'baseId', 'queryPartId', 'originalPartId'],
    );

    final String routePartName = _readStringArg(
      rawArgs,
      ['partName', 'baseName', 'queryPartName', 'originalPartName'],
      'Unknown Part',
    );

    final String routeMachineModel = _readStringArg(
      rawArgs,
      ['machineModel', 'machine_model'],
      'Unknown Machine',
    );

    const themeGreen = Color(0xFF2E7D32);

    if (routePartId == 0) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Original part ID is missing. Please go back to the compatibility search page and search the part again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Parts'),
        backgroundColor: themeGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<RecommendationResponse>(
        future: CompatibilityService.fetchRecommendations(routePartId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load recommendations\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No recommendation data found.'));
          }

          final response = snapshot.data!;

          final int safeBaseId =
              response.queryPart.id != 0 ? response.queryPart.id : routePartId;

          final String safeBaseName = response.queryPart.name.isNotEmpty
              ? response.queryPart.name
              : routePartName;

          final String safeMachineModel =
              response.queryPart.machineModel.isNotEmpty
                  ? response.queryPart.machineModel
                  : routeMachineModel;

          if (safeBaseId == 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Original part ID is missing. Please go back and search the part again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final filtered = response.recommendations
              .where((item) => item.partId != 0 && item.score >= 65)
              .toList()
            ..sort((a, b) => b.score.compareTo(a.score));

          final top3 = filtered.take(3).toList();

          if (top3.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No alternative parts found with compatibility score above 65%.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Original Part',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      safeBaseName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Machine Model: $safeMachineModel',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Original Part ID: $safeBaseId',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (response.totalCandidates > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Total Candidates: ${response.totalCandidates}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Showing top ${top3.length} compatible alternatives with score above 65%.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ...top3.map((part) {
                final score = part.score;
                final confidence = formatPercentage(part.confidenceScore);
                final similarity = formatPercentage(part.similarityScore);
                final ml = formatPercentage(part.mlScore);
                final feedback = formatPercentage(part.feedbackScore);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: getScoreColor(score),
                            child: Text(
                              '${score.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  part.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                Text('Part ID: ${part.partId}'),

                                if (part.machineModel.isNotEmpty)
                                  Text('Machine: ${part.machineModel}')
                                else if (part.machineFamily != null &&
                                    part.machineFamily!.isNotEmpty)
                                  Text('Machine Family: ${part.machineFamily}'),

                                if (part.brand != null &&
                                    part.brand!.isNotEmpty)
                                  Text('Brand: ${part.brand}'),

                                if (part.category != null &&
                                    part.category!.isNotEmpty)
                                  Text('Category: ${part.category}'),

                                if (part.compatibilityGroup != null &&
                                    part.compatibilityGroup!.isNotEmpty)
                                  Text(
                                    'Compatibility Group: ${part.compatibilityGroup}',
                                  ),

                                if (part.functionType != null &&
                                    part.functionType!.isNotEmpty)
                                  Text('Function Type: ${part.functionType}'),

                                if (part.substituteLevel != null &&
                                    part.substituteLevel!.isNotEmpty)
                                  Text(
                                    'Substitute Level: ${part.substituteLevel}',
                                  ),

                                if (confidence.isNotEmpty)
                                  Text('Confidence: $confidence'),
                              ],
                            ),
                          ),

                          Chip(
                            label: Text(
                              getQualityTag(score),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: getTagColor(score),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hybrid Score Breakdown',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Final Score: ${score.toStringAsFixed(2)}%'),
                            if (similarity.isNotEmpty)
                              Text('Vector Similarity: $similarity'),
                            if (ml.isNotEmpty) Text('ML Score: $ml'),
                            if (feedback.isNotEmpty)
                              Text('Feedback Score: $feedback'),
                          ],
                        ),
                      ),

                      if (part.whyRecommended != null &&
                          part.whyRecommended!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Why Recommended',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                part.whyRecommended!,
                                style: TextStyle(color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (part.explanation.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Explanation Notes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              ...part.explanation.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $item',
                                    style:
                                        TextStyle(color: Colors.grey.shade800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (part.matchedFields.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Matched Fields',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: part.matchedFields
                              .map(
                                (field) => Chip(
                                  label: Text(cleanFieldName(field)),
                                  backgroundColor: Colors.green.shade50,
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      if (part.differences.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Differences',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              ...part.differences.entries.map(
                                (entry) {
                                  final value = entry.value;

                                  if (value is Map) {
                                    final summary =
                                        value['summary']?.toString();
                                    final original =
                                        value['original']?.toString();
                                    final recommended =
                                        value['recommended']?.toString();

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        summary != null &&
                                                summary.trim().isNotEmpty
                                            ? '${cleanFieldName(entry.key)}: $summary'
                                            : '${cleanFieldName(entry.key)}: ${original ?? '-'} → ${recommended ?? '-'}',
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '${cleanFieldName(entry.key)}: $value',
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (safeBaseId == 0 || part.partId == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cannot compare because part IDs are missing.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                print('COMPARE BASE ID SENT: $safeBaseId');
                                print('COMPARE ALT ID SENT: ${part.partId}');

                                Navigator.pushNamed(
                                  context,
                                  '/comparison',
                                  arguments: {
                                    'baseId': safeBaseId,
                                    'altId': part.partId,
                                    'baseName': safeBaseName,
                                    'altName': part.name,
                                  },
                                );
                              },
                              icon: const Icon(Icons.compare_arrows),
                              label: const Text('Compare'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeGreen,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                if (safeBaseId == 0 || part.partId == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cannot submit feedback because part IDs are missing.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pushNamed(
                                  context,
                                  '/feedback',
                                  arguments: {
                                    'queryPartId': safeBaseId,
                                    'recommendedPartId': part.partId,
                                    'queryPartName': safeBaseName,
                                    'recommendedPartName': part.name,
                                  },
                                );
                              },
                              icon: const Icon(Icons.rate_review_outlined),
                              label: const Text('Feedback'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}