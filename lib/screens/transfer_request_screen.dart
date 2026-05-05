import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class TransferRequestScreen extends StatefulWidget {

  @override
  _TransferRequestScreenState createState() => _TransferRequestScreenState();
}

class _TransferRequestScreenState extends State<TransferRequestScreen> {
  final ApiService _apiService = ApiService();

  final serialController = TextEditingController();
  final buyerController = TextEditingController();

  void requestTransfer() async {

    final response = await _apiService.post(
      ApiConfig.transferRequest,
      body: {
        "serialNumber": serialController.text,
        "buyer": buyerController.text
      },
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(response["message"])));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text("Request Transfer")),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: Column(

          children: [

            TextField(
              controller: serialController,
              decoration: InputDecoration(labelText: "Serial Number"),
            ),

            TextField(
              controller: buyerController,
              decoration: InputDecoration(labelText: "Buyer"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: requestTransfer,
              child: Text("Send Request"),
            ),

          ],
        ),
      ),
    );
  }
}