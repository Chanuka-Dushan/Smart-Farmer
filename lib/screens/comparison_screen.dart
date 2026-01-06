import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  String getLifespanText(dynamic diff) {
    if (diff == null) return "Not guaranteed";
    if (diff == 0) return "Same as original";
    if (diff > 0) return "More than original";
    return "Less than original";
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final int baseId = args["baseId"];
    final int altId = args["altId"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comparison View"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: RecommendationService.getComparison(baseId, altId),
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error
            if (snapshot.hasError) {
              return const Center(
                child: Text("Failed to load comparison data"),
              );
            }

            final data = snapshot.data!;
            final base = data["base_part"];
            final alt = data["alternative_part"];
            final diff = data["difference"];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===============================
                  // Comparison Table
                  // ===============================
                  Table(
                    border: TableBorder.all(color: Colors.green),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(3),
                    },
                    children: [
                      _row("Attribute", "Original Part", "Alternative Part", true),
                      _row("Name", base["name"], alt["name"]),
                      _row("Brand", base["brand"], alt["brand"]),
                      _row(
                        "Price",
                        "Rs. ${base["price"] ?? "-"}",
                        "Rs. ${alt["price"] ?? "-"}",
                      ),
                      _row(
                        "Expected Lifespan",
                        "${base["lifespan"] ?? "-"}",
                        getLifespanText(diff["lifespan"]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===============================
                  // Notes Section (Novelty)
                  // ===============================
                  const Text(
                    "Compatibility Notes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This alternative part is recommended based on "
                    "engineering rules and machine-learned similarity "
                    "scores, ensuring functional compatibility.",
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  TableRow _row(String a, String b, String c, [bool header = false]) {
    return TableRow(
      decoration: header
          ? const BoxDecoration(color: Color(0xFFE8F5E9))
          : null,
      children: [
        _cell(a, header),
        _cell(b, header),
        _cell(c, header),
      ],
    );
  }

  Widget _cell(String text, bool header) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
