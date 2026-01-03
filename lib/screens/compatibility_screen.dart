import 'package:flutter/material.dart';

class CompatibilityScreen extends StatelessWidget {
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Compatibility Recommender")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(decoration: const InputDecoration(labelText: "Part Name")),
            TextField(decoration: const InputDecoration(labelText: "Brand")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Find Alternatives"),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text("Alternative Part"),
                subtitle: const Text("Compatibility: High"),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/comparison');
                  },
                  child: const Text("Compare"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
