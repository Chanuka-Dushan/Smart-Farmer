import 'package:flutter/material.dart';

class NlpSearchScreen extends StatelessWidget {
  const NlpSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Spare Part Search"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "e.g. plough blade for Kubota tractor",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  _resultCard(context,
                      part: "Plough Blade",
                      brand: "Kubota",
                      score: "96%"),
                  _resultCard(context,
                      part: "Oil Filter",
                      brand: "Mahindra",
                      score: "91%"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(BuildContext context,
      {required String part,
      required String brand,
      required String score}) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.build, color: Color(0xFF2E7D32)),
        title: Text(part),
        subtitle: Text("Brand: $brand | Match: $score"),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/part-search-result',
            arguments: part,
          );
        },
      ),
    );
  }
}
