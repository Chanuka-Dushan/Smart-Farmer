import 'package:flutter/material.dart';

class InventoryOptimizationScreen extends StatelessWidget {
  const InventoryOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Optimization")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("High Demand Parts",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              title: const Text("Oil Filter"),
              subtitle: const Text("Reorder Suggested: 50 units"),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pushNamed(context, '/inventory-details');
              },
            ),
          ),
        ],
      ),
    );
  }
}
