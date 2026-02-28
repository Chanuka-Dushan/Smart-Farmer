import 'package:flutter/material.dart';

class PartDetailScreen extends StatelessWidget {
  const PartDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Part Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Plough Blade",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Brand: Kubota"),
            const Text("Compatible Machine: Tractor X"),
            const Text("Price: Rs. 12,000"),
            const SizedBox(height: 20),

            const Text(
              "Recommended Alternatives",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Card(
              child: ListTile(
                title: const Text("Plough Blade - Alternative"),
                subtitle: const Text("Brand: Mahindra"),
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
