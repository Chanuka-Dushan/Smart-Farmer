// Quick Camera Analysis Widget for Bottom Navigation
// File: lib/widgets/quick_camera_analysis.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class QuickCameraAnalysis extends StatefulWidget {
  @override
  _QuickCameraAnalysisState createState() => _QuickCameraAnalysisState();
}

class _QuickCameraAnalysisState extends State<QuickCameraAnalysis> {
  final ApiService apiService = ApiService();
  bool _isAnalyzing = false;

  Future<void> _quickAnalyze() async {
    final ImagePicker picker = ImagePicker();
    
    // Show options: Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.green),
              title: Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue),
              title: Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.red),
              title: Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Pick image
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    // Show quick input dialog
    _showQuickInputDialog(File(image.path));
  }

  void _showQuickInputDialog(File imageFile) {
    final partNameController = TextEditingController();
    final usageHoursController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Quick Analysis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
              
              // Part name input
              TextField(
                controller: partNameController,
                decoration: InputDecoration(
                  labelText: 'Part Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
              ),
              SizedBox(height: 12),
              
              // Usage hours input
              TextField(
                controller: usageHoursController,
                decoration: InputDecoration(
                  labelText: 'Usage Hours',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (partNameController.text.isEmpty || usageHoursController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              Navigator.pop(context);
              await _performAnalysis(
                imageFile,
                partNameController.text,
                double.parse(usageHoursController.text),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Analyze'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAnalysis(File imageFile, String partName, double usageHours) async {
    setState(() {
      _isAnalyzing = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Card(
            margin: EdgeInsets.all(32),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final result = await apiService.predictLifecycle(
        partName: partName,
        usageHours: usageHours,
        location: 'Colombo', // Default location
        imagePath: imageFile.path,
      );

      Navigator.pop(context); // Close loading dialog
      _showResultDialog(result);
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final prediction = result['prediction'];
    final status = prediction['status'];
    final isBad = status == 'CRITICAL REPLACEMENT' || status == 'WARNING' || status == 'URGENT (STORM RISK)';
    final colorCode = Color(int.parse(prediction['color_code'].substring(1), radix: 16) + 0xFF000000);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorCode,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Column(
                children: [
                  Icon(
                    isBad ? Icons.warning : Icons.check_circle,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    status,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    prediction['remaining_life'],
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Part', result['part_name']),
                  Divider(),
                  _buildDetailRow('Wear', result['visual_scan']['wear_detected']),
                  _buildDetailRow('Confidence', result['visual_scan']['confidence']),
                  Divider(),
                  _buildDetailRow('Fresh Lifespan', result['ai_knowledge']['fresh_lifespan']),
                  _buildDetailRow('AI Source', result['ai_knowledge']['source']),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isBad)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to shop finder
              },
              icon: Icon(Icons.store),
              label: Text('Find Parts'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _isAnalyzing ? null : _quickAnalyze,
      backgroundColor: Colors.green,
      child: Icon(Icons.camera_alt),
      tooltip: 'Quick Analysis',
    );
  }
}
