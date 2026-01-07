import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class QRVerifyScreen extends StatefulWidget {

  @override
  _QRVerifyScreenState createState() => _QRVerifyScreenState();
}

class _QRVerifyScreenState extends State<QRVerifyScreen> {
  final ApiService _apiService = ApiService();

  bool scanned = false;

  void verify(String token) async {

    final response = await _apiService.post(
      ApiConfig.verifyQr,
      body: {"qr_token": token},
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Verification"),
        content: Text(response["status"]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text("Scan QR")),

      body: MobileScanner(

        onDetect: (capture) {

          if (scanned) return;

          final barcode = capture.barcodes.first;

          final String? code = barcode.rawValue;

          if (code != null) {

            scanned = true;

            verify(code);
          }
        },
      ),
    );
  }
}