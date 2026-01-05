import 'package:flutter/material.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to grab user input
  final TextEditingController _partController = TextEditingController();
  final TextEditingController _usageController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  
  String? _selectedSoil;
  final List<String> _soilTypes = ['Sandy', 'Loamy', 'Clay'];

  void _simulatePrediction() {
    if (_formKey.currentState!.validate()) {
      // Simulate a loading delay then show a dummy result for UI Demo
      showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Close loader
        _showResultDialog();
      });
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Prediction Result"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estimated Lifespan Remaining:", style: TextStyle(color: Colors.grey)),
            Text("120 Hours", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Recommendation:", style: TextStyle(color: Colors.grey)),
            Text("Plan to replace within 2 weeks. High humidity is accelerating wear.", 
                style: TextStyle(color: Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lifecycle Forecast"),
        backgroundColor: const Color(0xFF2E7D32), // Agri Green
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enter Machinery Details", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Part Name Input
              TextFormField(
                controller: _partController,
                decoration: const InputDecoration(
                  labelText: "Spare Part Name (e.g., Filter)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings),
                ),
              ),
              const SizedBox(height: 15),

              // Usage Hours Input
              TextFormField(
                controller: _usageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Current Usage (Hours)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 15),

              // Soil Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSoil,
                decoration: const InputDecoration(
                  labelText: "Soil Condition",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.landscape),
                ),
                items: _soilTypes.map((String soil) {
                  return DropdownMenuItem(value: soil, child: Text(soil));
                }).toList(),
                onChanged: (val) => setState(() => _selectedSoil = val),
              ),
              const SizedBox(height: 15),

              // Humidity Input
              TextFormField(
                controller: _humidityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Humidity (%)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.water_drop),
                ),
              ),
              const SizedBox(height: 15),

              // Temperature Input
              TextFormField(
                controller: _tempController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Temperature (°C)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.thermostat),
                ),
              ),
              const SizedBox(height: 30),

              // Predict Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _simulatePrediction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("PREDICT LIFESPAN", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}