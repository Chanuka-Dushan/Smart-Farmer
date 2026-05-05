import 'package:flutter/material.dart';

import '../models/inventory_models.dart';
import '../services/inventory_service.dart';

class InventoryForecastScreen extends StatefulWidget {
  InventoryForecastScreen({super.key});

  @override
  State<InventoryForecastScreen> createState() =>
      _InventoryForecastScreenState();
}

class _InventoryForecastScreenState extends State<InventoryForecastScreen> {
  static const Color primaryGreen = Color(0xFF2E7D32);

  final InventoryService _service = InventoryService();
  final TextEditingController _vendorController =
      TextEditingController(text: '1');

  late Future<List<ForecastItem>> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _forecastFuture = _service.fetchInventoryForecast('1');
  }

  void _loadForecast() {
    setState(() {
      _forecastFuture =
          _service.fetchInventoryForecast(_vendorController.text.trim());
    });
  }

  @override
  void dispose() {
    _vendorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demand Forecast"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vendorController,
                    decoration: InputDecoration(
                      labelText: "Vendor ID",
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                  ),
                  onPressed: _loadForecast,
                  child: const Text("Load"),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ForecastItem>>(
              future: _forecastFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Error: ${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text("No forecast data found for this vendor."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.partName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text("Part ID: ${item.partId}"),
                            const SizedBox(height: 10),
                            Text(
                              "Monthly Demand: ${item.monthlyDemand.join(', ')}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Forecast Next Month: ${item.forecastNextMonth.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}