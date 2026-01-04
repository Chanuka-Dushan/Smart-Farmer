import 'package:flutter/material.dart';

class PartSearchResultScreen extends StatelessWidget {
  const PartSearchResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partName =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Part Details"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partName,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _info("Part Number", "KB-PL-102"),
            _info("Brand", "Kubota"),
            _info("Price Range", "Rs. 11,000 - 13,000"),
            _info("Description",
                "Heavy-duty plough blade suitable for medium tractors"),

            const SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.compare),
                label: const Text("Find Alternative Parts"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32)),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/compatibility-recommender',
                    arguments: partName,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text("$label: $value"),
    );
  }
}
