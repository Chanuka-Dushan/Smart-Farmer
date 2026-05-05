import 'package:flutter/material.dart';

class InventoryDetailsScreen extends StatelessWidget {
  const InventoryDetailsScreen({super.key});

  // ✅ Define parts list
  final List<String> _parts = const [
    "Brake Pad",
    "Oil Filter",
    "Clutch Plate",
    "Fuel Pump",
    "Hydraulic Hose",
    "Air Filter",
    "Fan Belt",
    "Injector Nozzle",
  ];

  @override
  Widget build(BuildContext context) {
    final machine =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Details"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              machine,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              "Based on historical sales data",
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            // ✅ Safe spread operator usage
            ..._parts.take(6).map(
              (p) => Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.build,
                    color: Color(0xFF2E7D32),
                  ),
                  title: Text(p),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
