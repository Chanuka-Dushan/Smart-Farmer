import 'package:flutter/material.dart';

class HighDemandResultScreen extends StatelessWidget {
  const HighDemandResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Most Sold Parts"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _parts.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.build, color: Color(0xFF2E7D32)),
              title: Text(_parts[index]),
              subtitle:
                  const Text("Based on historical sales data"),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/inventory-details',
                  arguments: "TAFE 45 DI",
                );
              },
            ),
          );
        },
      ),
    );
  }
}

final List<String> _parts = [
  "Oil Filter",
  "Fuel Injector",
  "Clutch Plate",
  "Air Filter",
  "Brake Shoe",
  "Hydraulic Pump",
  "Radiator Hose",
  "Alternator",
  "Starter Motor",
  "Fan Belt",
  "Water Pump",
  "Fuel Pump",
  "Engine Gasket",
  "Gear Shaft",
  "Transmission Seal",
  "Piston Ring",
  "Battery",
  "Glow Plug",
  "Steering Cylinder",
  "Hydraulic Filter",
];
