import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;

import '../services/inventory_service.dart';

class InventoryStockInputScreen extends StatefulWidget {
  const InventoryStockInputScreen({super.key});

  @override
  State<InventoryStockInputScreen> createState() =>
      _InventoryStockInputScreenState();
}

class _InventoryStockInputScreenState extends State<InventoryStockInputScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  final InventoryService _inventoryService = InventoryService();
  final Map<String, TextEditingController> _stockControllers = {};

  bool _isLoading = false;
  List<Map<String, dynamic>> predictedItems = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is List && predictedItems.isEmpty) {
      predictedItems =
          args.map((item) => Map<String, dynamic>.from(item)).toList();

      for (final item in predictedItems) {
        final key = _makeKey(
          item['modelName']?.toString() ?? '',
          item['partName']?.toString() ?? '',
        );

        _stockControllers[key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _makeKey(String modelName, String partName) {
    return '${modelName.trim().toLowerCase()}_${partName.trim().toLowerCase()}';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _analyzeStock() async {
    if (predictedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No predicted items found")),
      );
      return;
    }

    final List<Map<String, dynamic>> vendorStock = [];

    for (final item in predictedItems) {
      final modelName = item['modelName']?.toString() ?? '';
      final partName = item['partName']?.toString() ?? '';
      final key = _makeKey(modelName, partName);

      final text = _stockControllers[key]?.text.trim() ?? '';

      vendorStock.add({
        "modelName": modelName,
        "partName": partName,
        "currentStock": int.tryParse(text) ?? 0,
      });
    }

    setState(() => _isLoading = true);

    try {
      final result = await _inventoryService.analyzeStock(
        predictedItems: predictedItems,
        vendorStock: vendorStock,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/inventory-stock-result',
        arguments: result,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stock analysis failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadExcel() async {
    if (predictedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No predicted items found")),
      );
      return;
    }

    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;

      setState(() => _isLoading = true);

      final response = await _inventoryService.analyzeStockExcel(
        predictedItems: predictedItems,
        filePath: pickedFile.path,
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/inventory-stock-result',
        arguments: response,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel upload failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Check My Stock",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: predictedItems.isEmpty
          ? const Center(child: Text("No predicted items received"))
          : Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: predictedItems.length,
                    itemBuilder: (context, index) {
                      final item = predictedItems[index];

                      final modelName = item['modelName']?.toString() ?? '';
                      final partName = item['partName']?.toString() ?? '';
                      final forecastDemand = _toInt(
                        item['forecastDemand'] ?? item['predictedDemand'],
                      );

                      final key = _makeKey(modelName, partName);

                      return _stockInputCard(
                        context: context,
                        modelName: modelName,
                        partName: partName,
                        forecastDemand: forecastDemand,
                        controller: _stockControllers[key]!,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                _bottomSubmitButtons(),
              ],
            ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter Current Stock",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Enter stock manually or upload an Excel file.",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockInputCard({
    required BuildContext context,
    required String modelName,
    required String partName,
    required int forecastDemand,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            partName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.agriculture_rounded,
                size: 18,
                color: primaryGreen.withOpacity(0.85),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  modelName,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded, color: primaryGreen),
                const SizedBox(width: 8),
                Text(
                  "Forecast Demand: $forecastDemand",
                  style: const TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Current Stock",
              hintText: "Example: 5",
              prefixIcon: const Icon(Icons.numbers_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSubmitButtons() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyzeStock,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics_rounded),
                label: Text(_isLoading ? "Analyzing..." : "Analyze Manual Stock"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _uploadExcel,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text("Upload Excel Stock File"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(color: primaryGreen),
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
}