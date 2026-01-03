import 'package:flutter/material.dart';

class InventoryDetailsScreen extends StatelessWidget {
  const InventoryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Oil Filter",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Current Stock: 20"),
            Text("Predicted Demand: 60/month"),
            Text("Recommended Action: Reorder"),
          ],
        ),
      ),
    );
  }
}
