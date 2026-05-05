import 'package:flutter/material.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;

  void _startScan() {
    setState(() => _isScanning = true);
    
    // Simulate AI Processing time
    Future.delayed(const Duration(seconds: 3), () {
      setState(() => _isScanning = false);
      _showWearDetectionResult();
    });
  }

  void _showWearDetectionResult() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 300,
        child: Column(
          children: [
            Container(
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            const Text("Analysis Complete", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Part Type:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Hydraulic Hose"),
              ],
            ),
            const Divider(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Condition:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Good", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Defects:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("None Detected"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Wear Detection"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera Placeholder (Gray Box)
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[800],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 100, color: Colors.white54),
                  SizedBox(height: 10),
                  Text("Camera Feed Placeholder", style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          
          // Scanning Overlay Animation
          if (_isScanning)
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              ),
            ),

          // Capture Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: FloatingActionButton.large(
                onPressed: _startScan,
                backgroundColor: Colors.white,
                child: const Icon(Icons.circle, size: 60, color: Colors.black),
              ),
            ),
          )
        ],
      ),
    );
  }
}