import 'package:flutter/material.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final TextEditingController _partController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  final List<String> brands = [
    "TAFE 45 DI",
    "TAFE 7250",
    "MF 240",
    "Kubota 4508",
    "Mahindra 575 DI",
  ];

  @override
  void dispose() {
    _partController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _findAlternatives() {
    if (_partController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a part name")),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/alternative-parts',
      arguments: {
        "partName": _partController.text.trim(),
        "brand": _brandController.text.trim(),
        "partId": 1, // 🔹 TEMP for PP1 demo
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Compatibility Recommender"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===============================
          // Part Name Input
          // ===============================
          TextField(
            controller: _partController,
            decoration: const InputDecoration(
              labelText: "Spare Part Name",
              hintText: "e.g. Oil Filter, Plough Blade",
              prefixIcon: Icon(Icons.build),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // ===============================
          // Brand Input (Dropdown + Typing)
          // ===============================
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return brands;
              }
              return brands.where(
                (b) => b
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()),
              );
            },
            onSelected: (String selection) {
              _brandController.text = selection;
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              controller.text = _brandController.text;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: "Machine / Brand",
                  hintText: "Select or type brand",
                  prefixIcon: Icon(Icons.agriculture),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _brandController.text = value;
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // ===============================
          // CTA Button
          // ===============================
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                "Find Alternative Parts",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _findAlternatives,
            ),
          ),

          const SizedBox(height: 32),

          // ===============================
          // Bottom Illustration Image
          // ===============================
          Column(
            children: [
              Image.asset(
                "assets/images/compatibility.jpg",
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              const Text(
                "Smart compatibility matching for agricultural spare parts",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
