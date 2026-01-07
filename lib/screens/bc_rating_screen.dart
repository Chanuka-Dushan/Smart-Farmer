import 'package:flutter/material.dart';

class BcRatingScreen extends StatelessWidget {
  const BcRatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Reputation")),
      body: const Center(child: Text("Reputation System live on Blockchain Ledger.\nUser rating: 4.8/5.0")),
    );
  }
}