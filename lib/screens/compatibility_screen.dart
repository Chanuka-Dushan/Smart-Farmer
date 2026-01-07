import 'package:flutter/material.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final TextEditingController _partController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  bool _loading = false;

  final List<String> brands = [
    "TAFE 45 DI",
    "TAFE 7250",
    "MF 240",
  ];

  /// 🔹 TEMP PART MAP (PP1)
  /// key = "partName|brand"
  final Map<String, int> partIdMap = {
  // ---------- TAFE 45 DI ----------
  "oil filter|tafe 45 di": 1,
  "fuel filter|tafe 45 di": 2,
  "air filter|tafe 45 di": 3,
  "head gasket|tafe 45 di": 4,
  "crank oil seal (rear)|tafe 45 di": 5,
  "front hub bearing inner|tafe 45 di": 6,
  "front hub bearing outer|tafe 45 di": 7,
  "pinion pilot racer|tafe 45 di": 8,
  "front axle|tafe 45 di": 9,
  "front center beam|tafe 45 di": 10,
  "center pin bush|tafe 45 di": 11,
  "king pin bush|tafe 45 di": 12,
  "crown wheel pinion assy|tafe 45 di": 13,
  "reverse gear wheel|tafe 45 di": 14,
  "top cover|tafe 45 di": 15,
  "hydraulic control valve|tafe 45 di": 16,
  "hydraulic safety valve|tafe 45 di": 17,
  "hydraulic pump o-ring kit|tafe 45 di": 18,
  "lift arm|tafe 45 di": 19,
  "bell cam|tafe 45 di": 20,
  "lift shaft|tafe 45 di": 21,

  // ---------- TAFE 7250 ----------
  "oil filter|tafe 7250": 22,
  "fuel filter|tafe 7250": 23,
  "front hub bearing inner|tafe 7250": 24,
  "front hub bearing outer|tafe 7250": 25,

  // ---------- MF 240 ----------
  "oil filter|mf 240": 26,
  "fuel filter|mf 240": 27,
  "front hub bearing inner|mf 240": 28,
  "front hub grease seal|mf 240": 29,
  "crank oil seal (rear)|mf 240": 30,
  "crown wheel & pinion|mf 240": 31,
  "reverse gear|mf 240": 32,
  "front axle|mf 240": 34,
  "front center beam|mf 240": 35,
  "center pin bush|mf 240": 36,
  "king pin bush|mf 240": 37,
  "hydraulic control valve|mf 240": 38,
  "hydraulic safety valve|mf 240": 39,
  "hydraulic pump o-ring kit|mf 240": 40,
  "pinion pilot racer|mf 240": 41,
  "top cover|mf 240": 42,
  "lift arm|mf 240": 43,
  "bell cam|mf 240": 44,
  "lift shaft|mf 240": 45,
};


  @override
  void dispose() {
    _partController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  // ==========================================================
  // 🔍 TEMP FIND ALTERNATIVES
  // ==========================================================
  void _findAlternatives() {
    final partName = _partController.text.trim().toLowerCase();
    final brand = _brandController.text.trim().toLowerCase();

    if (partName.isEmpty || brand.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter part name and brand")),
      );
      return;
    }

    final key = "$partName|$brand";

    if (!partIdMap.containsKey(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Part not found (PP1 demo set)")),
      );
      return;
    }

    final int partId = partIdMap[key]!;

    Navigator.pushNamed(
      context,
      '/alternative-parts',
      arguments: {
        "partId": partId,
        "partName": _partController.text.trim(),
        "brand": _brandController.text.trim(),
      },
    );
  }

  // ==========================================================
  // UI
  // ==========================================================
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
          TextField(
            controller: _partController,
            decoration: const InputDecoration(
              labelText: "Spare Part Name",
              hintText: "e.g. Fuel Filter",
              prefixIcon: Icon(Icons.build),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          Autocomplete<String>(
            optionsBuilder: (value) {
              if (value.text.isEmpty) return brands;
              return brands.where(
                (b) => b.toLowerCase().contains(value.text.toLowerCase()),
              );
            },
            onSelected: (selection) {
              _brandController.text = selection;
            },
            fieldViewBuilder: (context, controller, focusNode, _) {
              controller.text = _brandController.text;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: "Machine / Brand",
                  prefixIcon: Icon(Icons.agriculture),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _brandController.text = v,
              );
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              onPressed: _findAlternatives,
              child: const Text(
                "Find Alternative Parts",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
