import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/l10n_extension.dart';
import 'blockchain_verification_result_screen.dart';

class BcScannerScreen extends StatefulWidget {
  const BcScannerScreen({super.key});

  @override
  State<BcScannerScreen> createState() => _BcScannerScreenState();
}

class _BcScannerScreenState extends State<BcScannerScreen> {
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? "";
      
      if (code.isNotEmpty) {
        setState(() => _isProcessing = true);
        
        try {
          // Call the Python API we wrote
          final result = await _apiService.verifyBlockchainPart(code);

          if (!mounted) return;

          // Navigate to your Result Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BlockchainVerificationResultScreen(resultData: result),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Ledger QR"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // QR Scanner Camera
          MobileScanner(onDetect: _onDetect),

          // Visual Overlay (Matching teammate's style)
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
            
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              "Align QR code to verify authenticity",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, backgroundColor: Colors.black54),
            ),
          )
        ],
      ),
    );
  }
}