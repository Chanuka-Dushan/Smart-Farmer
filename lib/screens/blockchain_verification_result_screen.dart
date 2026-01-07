import 'package:flutter/material.dart';
import '../services/l10n_extension.dart';

class BlockchainVerificationResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const BlockchainVerificationResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    // Extracting data from the Python API response
    final details = resultData['details'] ?? {};
    final List history = resultData['history'] ?? [];
    final bool isAuthentic = resultData['status'] == "AUTHENTIC";

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('verification_result') ?? 'Verification Result'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isAuthentic ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isAuthentic ? Colors.green : Colors.red),
              ),
              child: Column(
                children: [
                  Icon(
                    isAuthentic ? Icons.verified : Icons.gpp_bad,
                    size: 80,
                    color: isAuthentic ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAuthentic ? "VERIFIED AUTHENTIC" : "INVALID PART",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isAuthentic ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                  const Text(
                    "Secured by Hyperledger Fabric Ledger",
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Part Details Section (Digital Twin Info)
            Text(
              context.tr('part_details') ?? "Part Information",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildDetailRow("Part Name", details['name']),
              _buildDetailRow("Brand", details['brand']),
              _buildDetailRow("Manufacturer", details['manufacturer']),
              _buildDetailRow("Blockchain ID", details['serial']),
              _buildDetailRow("Condition", resultData['condition'] ?? "New"),
            ]),
            const SizedBox(height: 32),

            // 3. Immutable Ledger History (Traceability)
            Text(
              context.tr('ledger_history') ?? "Immutable Ledger History",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "This history is permanent and cannot be tampered with.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            if (history.isEmpty)
              const Center(child: Text("No transaction history found on-chain."))
            else
              ...history.map((event) => _buildHistoryTile(event)).toList(),

            const SizedBox(height: 40),

            // 4. Action Buttons (Transfer & Rating)
            ElevatedButton(
              onPressed: () {
                // Navigate to Transfer Screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("TRANSFER OWNERSHIP", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // Navigate to Rating Screen
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("RATE VENDOR", style: TextStyle(color: Color(0xFF2E7D32))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.link, color: Color(0xFF2E7D32)),
        ),
        title: Text(event['event'] ?? "Transaction"),
        subtitle: Text(event['date'] ?? ""),
        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 16),
      ),
    );
  }
}