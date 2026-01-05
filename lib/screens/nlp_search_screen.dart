import 'package:flutter/material.dart';

class NlpSearchScreen extends StatelessWidget {
  const NlpSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NLP Spare Part Search")),
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
                  _resultCard(context, "Plough Blade", "Kubota", "96%"),
                  _resultCard(context, "Oil Filter", "Mahindra", "91%"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(
      BuildContext context, String part, String brand, String score) {
    return Card(
      child: ListTile(
        title: Text(part),
        subtitle: Text("Brand: $brand | Match: $score"),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.pushNamed(context, '/part-detail');
        },
      ),
    );
  }
}
