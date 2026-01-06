import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';

class AlternativePartsScreen extends StatelessWidget {
  const AlternativePartsScreen({super.key});

  // ===============================
  // Score → Tag
  // ===============================
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

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String partName = args["partName"];
    final int partId = args["partId"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alternative Parts"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===============================
            // Page Heading
            // ===============================
            Text(
              'Alternative parts for "$partName"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // ===============================
            // Backend Data Loader
            // ===============================
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: RecommendationService.getHybridRecommendations(partId),
                builder: (context, snapshot) {
                  // Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Failed to load recommendations"),
                    );
                  }

                  final data = snapshot.data!;
                  final List alternatives = data["recommendations"];
                  final int baseId = data["base_part"]["id"];

                  // No results
                  if (alternatives.isEmpty) {
                    return const Center(
                      child: Text("No compatible alternatives found"),
                    );
                  }

                  // ===============================
                  // List of Alternative Parts
                  // ===============================
                  return ListView.builder(
                    itemCount: alternatives.length,
                    itemBuilder: (context, index) {
                      final part = alternatives[index];
                      final double score =
                          (part["final_score"] as num).toDouble();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2E7D32),
                            child: Text(
                              "${score.toInt()}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // ===============================
                          // Part Details + Chip
                          // ===============================
                          title: Text(part["name"]),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Brand: ${part["brand"]}"),
                              const SizedBox(height: 6),

                              Chip(
                                label: Text(
                                  getQualityTag(score),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: getTagColor(score),
                              ),
                            ],
                          ),

                          // ===============================
                          // Compare Button
                          // ===============================
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/comparison',
                                arguments: {
                                  "baseId": baseId,
                                  "altId": part["part_id"],
                                },
                              );
                            },
                            child: const Text(
                              "Compare",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
