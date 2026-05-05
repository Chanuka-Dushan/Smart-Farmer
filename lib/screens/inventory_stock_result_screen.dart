import 'package:flutter/material.dart';

class InventoryStockResultScreen extends StatelessWidget {
  const InventoryStockResultScreen({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);

  Color _getStatusColor(String status) {
    switch (status) {
      case "LOW_STOCK":
        return Colors.red;
      case "ENOUGH_STOCK":
        return Colors.green;
      case "HIGH_STOCK":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "LOW_STOCK":
        return Icons.warning_rounded;
      case "ENOUGH_STOCK":
        return Icons.check_circle_rounded;
      case "HIGH_STOCK":
        return Icons.trending_up_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    final List stockList = result['stockAnalysis'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Stock Analysis",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: stockList.isEmpty
          ? const Center(child: Text("No stock analysis data"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stockList.length,
              itemBuilder: (context, index) {
                final item = stockList[index];

                final status = item['status'] ?? '';
                final color = _getStatusColor(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 Part + Model
                      Text(
                        item['partName'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['modelName'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 12),

                      /// 🔹 Status Badge
                      Row(
                        children: [
                          Icon(_getStatusIcon(status), color: color),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// 🔹 Stock Info
                      _infoRow("Current Stock", item['currentStock']),
                      _infoRow("Forecast Demand", item['forecastDemand']),
                      _infoRow("Safe Stock", item['safeStock']),
                      _infoRow("Need To Buy", item['needToBuy']),

                      const SizedBox(height: 12),

                      /// 🔹 Substitute Suggestions ⭐
                      if (item['substituteSuggestion'] != null &&
                          item['substituteSuggestion']['available'] == true)
                        _buildSubstituteBox(item['substituteSuggestion']),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text("$value")),
        ],
      ),
    );
  }

  Widget _buildSubstituteBox(Map<String, dynamic> suggestion) {
    final List parts = suggestion['suggestedParts'] ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Suggested Alternatives",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 6),
          ...parts.map<Widget>((p) {
            final partName = p['partName']?.toString() ?? '';
            final modelName = p['modelName']?.toString() ?? '';
            final brand = p['brand']?.toString() ?? '';
            final partType = p['partType']?.toString() ?? '';

            String displayText;

            if (modelName.isNotEmpty) {
              displayText = "• $partName - $modelName";

              if (brand.isNotEmpty) {
                displayText += " ($brand)";
              }
            } else {
              displayText = "• $partName";

              if (partType.isNotEmpty) {
                displayText += " ($partType)";
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(displayText),
            );
          }).toList(),
        ],
      ),
    );
  }
}