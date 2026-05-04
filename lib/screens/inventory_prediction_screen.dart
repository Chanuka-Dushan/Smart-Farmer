import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class InventoryPredictionScreen extends StatefulWidget {
  const InventoryPredictionScreen({super.key});

  @override
  State<InventoryPredictionScreen> createState() => _InventoryPredictionScreenState();
}

class _InventoryPredictionScreenState extends State<InventoryPredictionScreen> {
  final InventoryService _service = InventoryService();

  String? selectedMonth;
  String? selectedSeason;
  String? selectedStage;
  String? selectedCategory;
  String? type;

  final TextEditingController modelController = TextEditingController();

  bool isLoading = false;
  bool loadedTypeOnce = false;

  final months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  final seasons = ["Yala", "Maha"];

  final stages = [
    "Land Ploughing",
    "Harrowing",
    "Puddling",
    "Sowing",
    "Harvesting",
  ];

  final categories = [
    "Tractor",
    "Rotavator",
    "Power Tiller",
    "Seeder",
    "Sprayer",
    "Combine Harvester",
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loadedTypeOnce) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map && args['type'] != null) {
        type = args['type'];
        loadedTypeOnce = true;

        Future.delayed(Duration.zero, () {
          _submitPrediction();
        });
      }
    }
  }

  Future<void> _submitPrediction() async {
    if (type == null &&
        selectedMonth == null &&
        selectedSeason == null &&
        selectedStage == null &&
        selectedCategory == null &&
        modelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one search option")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await _service.predictInventory(
        month: selectedMonth,
        season: selectedSeason,
        stage: selectedStage,
        category: selectedCategory,
        model: modelController.text.trim(),
        type: type,
        flatten: false,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/inventory-prediction-result',
        arguments: result,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _clearForm() {
    setState(() {
      selectedMonth = null;
      selectedSeason = null;
      selectedStage = null;
      selectedCategory = null;
      modelController.clear();
      type = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title = "Demand Prediction";
    if (type == "high_demand_parts") title = "High Demand Parts";
    if (type == "high_demand_machines") title = "High Demand Machines";

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.analytics_rounded, size: 38, color: green),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "Search by month, season, stage, machine category, or model to forecast spare part demand.",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (type == null) ...[
              _dropdown("Month", selectedMonth, months, (value) {
                setState(() => selectedMonth = value);
              }),
              _dropdown("Season", selectedSeason, seasons, (value) {
                setState(() => selectedSeason = value);
              }),
              _dropdown("Stage", selectedStage, stages, (value) {
                setState(() => selectedStage = value);
              }),
              _dropdown("Machine Category", selectedCategory, categories, (value) {
                setState(() => selectedCategory = value);
              }),

              const SizedBox(height: 12),

              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: "Model Name",
                  hintText: "Example: TAFE 7250",
                  prefixIcon: const Icon(Icons.agriculture_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _submitPrediction,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(isLoading ? "Loading..." : "Get Prediction"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (type == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Clear"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}