import 'package:flutter/material.dart';

class InventoryPredictionResultScreen extends StatelessWidget {
  const InventoryPredictionResultScreen({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);

  List<Map<String, dynamic>> _flattenPrediction(Map<String, dynamic> result) {
    final List<Map<String, dynamic>> items = [];
    final machines = result['machines'] ?? [];

    for (final machine in machines) {
      final models = machine['models'] ?? [];

      for (final model in models) {
        final parts = model['parts'] ?? [];

        for (final part in parts) {
          items.add({
            "category": machine['category'],
            "modelName": model['modelName'],
            "partName": part['partName'],
            "forecastDemand": part['forecastDemand'] ?? 0,
            "forecastAccuracy": part['forecastAccuracy'],
          });
        }
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    final type = result['type'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Prediction Results",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: type == "high_demand_parts"
          ? _highDemandParts(result)
          : type == "high_demand_machines"
              ? _highDemandMachines(result)
              : _normalPrediction(context, result),
    );
  }

  Widget _normalPrediction(BuildContext context, Map<String, dynamic> result) {
    final machines = result['machines'] ?? [];
    final predictedItems = _flattenPrediction(result);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF252525)
                : primaryGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryGreen.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow("Season", result['season']),
              _summaryRow("Stage", result['stage']),
              _summaryRow("Category", result['category']),
              _summaryRow("Model", result['model']),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: machines.length,
            itemBuilder: (context, index) {
              final machine = machines[index];
              final models = machine['models'] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ExpansionTile(
                  leading: const Icon(
                    Icons.agriculture_rounded,
                    color: primaryGreen,
                  ),
                  title: Text(
                    machine['category'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Demand: ${machine['demandLevel']} | Base: ${machine['baseDemand']}",
                  ),
                  children: models.map<Widget>((model) {
                    final parts = model['parts'] ?? [];

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${model['brand']} - ${model['modelName']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...parts.map<Widget>((part) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          part['partName'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text("Type: ${part['partType']}"),
                                        Text(
                                          "Accuracy: ${part['forecastAccuracy'] ?? 'N/A'}%",
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      "Forecast ${part['forecastDemand']}",
                                    ),
                                    backgroundColor:
                                        primaryGreen.withOpacity(0.12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: predictedItems.isEmpty
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          '/inventory-stock-input',
                          arguments: predictedItems,
                        );
                      },
                icon: const Icon(Icons.inventory_rounded),
                label: const Text("Check My Stock"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text("${value ?? '-'}")),
        ],
      ),
    );
  }

  Widget _highDemandParts(Map<String, dynamic> result) {
    final items = result['items'] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.build_circle_rounded,
              color: Colors.orange,
            ),
            title: Text(item['partName'] ?? ''),
            subtitle: Text("${item['modelName']} | ${item['category']}"),
            trailing: Text(item['criticality'] ?? ''),
          ),
        );
      },
    );
  }

  Widget _highDemandMachines(Map<String, dynamic> result) {
    final machines = result['machines'] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: machines.length,
      itemBuilder: (context, index) {
        final machine = machines[index];
        final models = machine['models'] ?? [];

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            leading: const Icon(
              Icons.agriculture_rounded,
              color: Colors.blue,
            ),
            title: Text(machine['category'] ?? ''),
            children: models.map<Widget>((model) {
              return ListTile(
                title: Text(model['modelName'] ?? ''),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}