import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BcTransferScreen extends StatefulWidget {
  const BcTransferScreen({super.key});
  @override
  State<BcTransferScreen> createState() => _BcTransferScreenState();
}

class _BcTransferScreenState extends State<BcTransferScreen> {
  final _buyerIdController = TextEditingController();
  final _bcMapIdController = TextEditingController();

  void _doTransfer() async {
    try {
      await ApiService().transferLedgerOwnership(
        int.parse(_bcMapIdController.text), 
        int.parse(_buyerIdController.text)
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transfer Recorded on Ledger")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ledger Ownership Transfer")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _bcMapIdController, decoration: const InputDecoration(labelText: "Ledger Item ID")),
            TextField(controller: _buyerIdController, decoration: const InputDecoration(labelText: "Buyer User ID")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _doTransfer, child: const Text("EXECUTE SECURE TRANSFER")),
          ],
        ),
      ),
    );
  }
}