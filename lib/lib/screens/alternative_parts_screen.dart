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

  // ===============================
  // RULE 1: Score Threshold
  // ===============================
  bool isScoreAcceptable(double score) {
    return score >= 50; // ❗ Only show >= 50%
  }

  // ===============================
  // RULE 2: Name Similarity (Partial Match)
  // ===============================
  bool isNameSimilar(String baseName, String altName) {
    final baseWords =
        baseName.toLowerCase().split(" ").where((w) => w.length > 2).toList();

    final altLower = altName.toLowerCase();

    // At least ONE meaningful word should match
    for (final word in baseWords) {
      if (altLower.contains(word)) {
        return true;
      }
    }
    return false;
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
                  final List allAlternatives = data["recommendations"];
                  final int baseId = data["base_part"]["id"];
                  final String baseName = data["base_part"]["name"];

                  // ===============================
                  // APPLY FRONTEND FILTERS
                  // ===============================
                  final List filteredAlternatives =
                      allAlternatives.where((part) {
                    final double score =
                        (part["final_score"] as num).toDouble();
                    final String altName = part["name"];

                    return isScoreAcceptable(score) &&
                        isNameSimilar(baseName, altName);
                  }).toList();

                  // No results after filtering
                  if (filteredAlternatives.isEmpty) {
                    return const Center(
                      child: Text(
                        "No suitable alternatives found\n(score > 50%)",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  // ===============================
                  // List of Alternative Parts
                  // ===============================
                  return ListView.builder(
                    itemCount: filteredAlternatives.length,
                    itemBuilder: (context, index) {
                      final part = filteredAlternatives[index];
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
