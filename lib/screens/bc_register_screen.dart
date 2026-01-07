import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BcRegisterScreen extends StatefulWidget {
  const BcRegisterScreen({super.key});
  @override
  State<BcRegisterScreen> createState() => _BcRegisterScreenState();
}

class _BcRegisterScreenState extends State<BcRegisterScreen> {
  final _serialController = TextEditingController();
  bool _loading = false;

  void _mintAsset() async {
    setState(() => _loading = true);
    try {
      // For demo, we assume part_id 1. You can add a dropdown to select parts later.
      await ApiService().registerPartOnLedger(
        partId: 1, 
        serialNumber: _serialController.text, 
        manufacturerId: 1
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Asset Minted on Ledger!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Part on Ledger")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _serialController, decoration: const InputDecoration(labelText: "Enter QR Serial Number")),
            const SizedBox(height: 20),
            _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _mintAsset, child: const Text("MINT DIGITAL TWIN"))
          ],
        ),
      ),
    );
  }
}