import 'package:flutter/material.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Part Comparison"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          border: TableBorder.all(color: Colors.green),
          children: [
            TableRow(children: [
              _cell("Attribute", true),
              _cell("Original", true),
              _cell("Alternative", true),
            ]),
            TableRow(children: [
              _cell("Price"),
              _cell("Rs. 12,000"),
              _cell("Rs. 9,500"),
            ]),
            TableRow(children: [
              _cell("Lifespan"),
              _cell("2 years"),
              _cell("1.5 years"),
            ]),
            TableRow(children: [
              _cell("Compatibility"),
              _cell("High"),
              _cell("Medium"),
            ]),
          ],
        ),
      ),
    );
  }

  static Widget _cell(String text, [bool header = false]) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
