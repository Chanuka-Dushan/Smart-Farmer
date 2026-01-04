import 'package:flutter/material.dart';

class CompatibilityScreen extends StatelessWidget {
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchedPart =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Compatibility Recommender"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration:
                const InputDecoration(labelText: "Part Name"),
            controller: TextEditingController(text: searchedPart),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField(
            decoration: const InputDecoration(labelText: "Machine / Brand"),
            items: const [
              "TAFE 45 DI",
              "TAFE 7250",
              "MF 240",
              "Kubota 4508",
              "Mahindra 575 DI"
            ]
                .map((b) =>
                    DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (_) {},
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              Navigator.pushNamed(context, '/alternative-parts');
            },
            child: const Text("Find Alternative Parts"),
          ),

          const SizedBox(height: 30),
          Image.asset(
            "assets/images/compatibility.png",
            height: 180,
          ),
        ],
      ),
    );
  }
}
