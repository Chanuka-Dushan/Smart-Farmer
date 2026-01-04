import 'package:flutter/material.dart';

class AlternativePartsScreen extends StatelessWidget {
  const AlternativePartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alternative Parts"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _altCard(context,
              part: "Plough Blade - Mahindra",
              match: "92%"),
          _altCard(context,
              part: "Plough Blade - TAFE",
              match: "89%"),
        ],
      ),
    );
  }

  Widget _altCard(BuildContext context,
      {required String part, required String match}) {
    return Card(
      child: ListTile(
        title: Text(part),
        subtitle: Text("Matching Score: $match"),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/comparison-view');
          },
          child: const Text("Compare"),
        ),
      ),
    );
  }
}
