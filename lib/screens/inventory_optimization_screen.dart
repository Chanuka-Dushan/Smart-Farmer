import 'package:flutter/material.dart';

class InventoryOptimizationScreen extends StatelessWidget {
  const InventoryOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Optimization"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------- Section 1 --------
          const Text(
            "High Demand Parts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Identify most sold spare parts using historical sales data",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),

          TextField(
            decoration: InputDecoration(
              hintText: "Enter machine name (e.g. TAFE 45 DI)",
              prefixIcon: const Icon(Icons.agriculture),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/high-demand-results');
            },
            child: const Text(
              "Search",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // -------- Section 2 --------
          const Text(
            "Seasonal Demand Forecast",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Predict machine demand based on season and location",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField(
            decoration: const InputDecoration(
              labelText: "Month Range",
              border: OutlineInputBorder(),
            ),
            items: [
              "January - March",
              "April - June",
              "July - September",
              "October - December"
            ]
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m),
                    ))
                .toList(),
            onChanged: (_) {},
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField(
            decoration: const InputDecoration(
              labelText: "District",
              border: OutlineInputBorder(),
            ),
            items: _districts
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d),
                    ))
                .toList(),
            onChanged: (_) {},
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/seasonal-machines');
            },
            child: const Text(
              "Analyze Demand",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final List<String> _districts = [
  "Colombo","Gampaha","Kalutara","Kandy","Matale","Nuwara Eliya",
  "Galle","Matara","Hambantota","Jaffna","Kilinochchi","Mannar",
  "Vavuniya","Mullaitivu","Batticaloa","Ampara","Trincomalee",
  "Kurunegala","Puttalam","Anuradhapura","Polonnaruwa","Badulla",
  "Monaragala","Ratnapura","Kegalle",
];
