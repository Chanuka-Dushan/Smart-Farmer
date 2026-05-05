import 'package:flutter/material.dart';

import '../models/inventory_models.dart';
import '../services/inventory_service.dart';

class InventoryRecommendationScreen extends StatefulWidget {
  InventoryRecommendationScreen({super.key});

  @override
  State<InventoryRecommendationScreen> createState() =>
      _InventoryRecommendationScreenState();
}

class _InventoryRecommendationScreenState
    extends State<InventoryRecommendationScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  final InventoryService _service = InventoryService();
  final TextEditingController _vendorController =
      TextEditingController(text: '1');

  late Future<InventoryRecommendationResponse> _recommendationFuture;

  @override
  void initState() {
    super.initState();
    _recommendationFuture = _service.fetchInventoryRecommendations('1');
  }

  void _loadRecommendations() {
    setState(() {
      _recommendationFuture =
          _service.fetchInventoryRecommendations(_vendorController.text.trim());
    });
  }

  @override
  void dispose() {
    _vendorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Recommendations"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vendorController,
                    decoration: InputDecoration(
                      labelText: "Vendor ID",
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                  ),
                  onPressed: _loadRecommendations,
                  child: const Text("Load"),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<InventoryRecommendationResponse>(
              future: _recommendationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error: ${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final data = snapshot.data;

                if (data == null) {
                  return const Center(child: Text("No data available."));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      "Reorder List",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (data.reorderList.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("No reorder recommendations available."),
                        ),
                      )
                    else
                      ...data.reorderList.map(
                        (item) => Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.partName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text("Part ID: ${item.partId}"),
                                Text("Current Stock: ${item.currentStock}"),
                                Text("Reorder Point: ${item.reorderPoint}"),
                                Text(
                                  "Forecast: ${item.forecastNextMonth.toStringAsFixed(2)}",
                                ),
                                Text(
                                  "Recommended Reorder Qty: ${item.recommendedReorderQty}",
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.reason,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      "Suggested Substitutes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (data.suggestedSubstitutes.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("No substitute suggestions available."),
                        ),
                      )
                    else
                      ...data.suggestedSubstitutes.map(
                        (item) => Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${item.originalPartName} → ${item.substitutePartName}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text("Original Part ID: ${item.originalPartId}"),
                                Text(
                                  "Substitute Part ID: ${item.substitutePartId}",
                                ),
                                Text(
                                  "Feedback Score: ${item.feedbackScore.toStringAsFixed(2)}",
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.reason,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}