import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class RegisterPartScreen extends StatefulWidget {

  @override
  _RegisterPartScreenState createState() => _RegisterPartScreenState();
}

class _RegisterPartScreenState extends State<RegisterPartScreen> {
  final ApiService _apiService = ApiService();

  final serialController = TextEditingController();
  final partIdController = TextEditingController();
  final manufacturerController = TextEditingController();
  final ownerController = TextEditingController();

  void registerPart() async {

    final data = {
      "serialNumber": serialController.text,
      "partID": partIdController.text,
      "partName": "Sample Part",
      "manufacturer": manufacturerController.text,
      "country": "Japan",
      "description": "Auto part",
      "owner": ownerController.text
    };

    final response = await _apiService.post(
      ApiConfig.registerPart,
      body: data,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(response["message"])));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text("Register Part")),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: Column(

          children: [

            TextField(
              controller: serialController,
              decoration: InputDecoration(labelText: "Serial Number"),
            ),

            TextField(
              controller: partIdController,
              decoration: InputDecoration(labelText: "Part ID"),
            ),

            TextField(
              controller: manufacturerController,
              decoration: InputDecoration(labelText: "Manufacturer"),
            ),

            TextField(
              controller: ownerController,
              decoration: InputDecoration(labelText: "Owner"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: registerPart,
              child: Text("Register"),
            ),

          ],
        ),
      ),
    );
  }
}