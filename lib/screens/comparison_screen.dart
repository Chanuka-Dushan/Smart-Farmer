import 'package:flutter/material.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comparison View"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          border: TableBorder.all(color: Colors.green),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(3),
          },
          children: [
            _row("Attribute", "Original Part", "Alternative Part", true),
            _row("Brand", "Kubota", "Mahindra"),
            _row("Matching %", "100%", "92%"),
            _row("Price Range", "Rs. 12,000", "Rs. 9,500"),
            _row("Expected Lifespan", "2 Years", "Slightly Less"),
            _row("Notes",
                "Manufacturer recommended",
                "Verified compatible by system"),
          ],
        ),
      ),
    );
  }

  TableRow _row(String a, String b, String c, [bool header = false]) {
    return TableRow(children: [
      _cell(a, header),
      _cell(b, header),
      _cell(c, header),
    ]);
  }

  Widget _cell(String text, bool header) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
            fontWeight:
                header ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}
