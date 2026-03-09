import 'package:flutter/material.dart';
import '../models/compatibility_models.dart';
import '../services/compatibility_service.dart';

class AlternativePartsScreen extends StatelessWidget {
  const AlternativePartsScreen({super.key});

  String getQualityTag(double score) {
    if (score >= 90) return "BEST";
    if (score >= 75) return "BETTER";
    return "GOOD";
  }

  Color getTagColor(double score) {
    if (score >= 90) return Colors.green.shade100;
    if (score >= 75) return Colors.orange.shade100;
    return Colors.blue.shade100;
  }

  Color getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final int partId = args['partId'];
    final String partName = args['partName'];
    final String machineModel = args['machineModel'];

    const themeGreen = Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alternative Parts'),
        backgroundColor: themeGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<RecommendationResponse>(
        future: CompatibilityService.fetchRecommendations(partId),
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

          final filtered = response.recommendations
              .where((item) => item.score >= 65)
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
                      partName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Machine Model: $machineModel',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
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
                        children: [
                          CircleAvatar(
                            radius: 24,
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
                                Text('Machine: ${part.machineModel}'),
                                if (part.brand != null && part.brand!.isNotEmpty)
                                  Text('Brand: ${part.brand}'),
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/comparison',
                                  arguments: {
                                    'baseId': response.queryPart.id,
                                    'altId': part.partId,
                                    'baseName': response.queryPart.name,
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
                                Navigator.pushNamed(
                                  context,
                                  '/feedback',
                                  arguments: {
                                    'queryPartId': response.queryPart.id,
                                    'recommendedPartId': part.partId,
                                    'queryPartName': response.queryPart.name,
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