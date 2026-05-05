import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class RegisterPartScreen extends StatefulWidget {
  const RegisterPartScreen({super.key});

  @override
  State<RegisterPartScreen> createState() => _RegisterPartScreenState();
}

class _RegisterPartScreenState extends State<RegisterPartScreen> {
  final ApiService _apiService = ApiService();

  final serialController = TextEditingController();
  final partIdController = TextEditingController();
  final partNameController = TextEditingController();
  final manufacturerController = TextEditingController();
  final countryController = TextEditingController();
  final descriptionController = TextEditingController();
  final ownerController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ownerController.text.isEmpty) {
      final sellerEmail =
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).seller?.email.trim().toLowerCase();
      if (sellerEmail != null && sellerEmail.isNotEmpty) {
        ownerController.text = sellerEmail;
      }
    }
  }

  void registerPart() async {
    final data = {
      "serialNumber": serialController.text,
      "partID": partIdController.text,
      "partName": partNameController.text,
      "manufacturer": manufacturerController.text,
      "country": countryController.text,
      "description": descriptionController.text,
      "owner": ownerController.text.trim().toLowerCase(),
    };

    final response = await _apiService.post(ApiConfig.registerPart, body: data);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response["message"])));
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
              controller: partNameController,
              decoration: InputDecoration(labelText: "Part Name"),
            ),

            TextField(
              controller: manufacturerController,
              decoration: InputDecoration(labelText: "Manufacturer"),
            ),

            TextField(
              controller: countryController,
              decoration: InputDecoration(labelText: "Country"),
            ),

            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),

            TextField(
              controller: ownerController,
              decoration: InputDecoration(labelText: "Owner"),
            ),

            SizedBox(height: 20),

            ElevatedButton(onPressed: registerPart, child: Text("Register")),
          ],
        ),
      ),
    );
  }
}
