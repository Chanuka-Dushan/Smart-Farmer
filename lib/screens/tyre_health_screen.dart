import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/l10n_extension.dart';
import 'tyre_damage_results_screen.dart';

class TyreHealthScreen extends StatefulWidget {
  const TyreHealthScreen({super.key});

  @override
  State<TyreHealthScreen> createState() => _TyreHealthScreenState();
}

class _TyreHealthScreenState extends State<TyreHealthScreen> {
  final ApiService _apiService = ApiService();
  File? _selectedImage;
  bool _isAnalyzing = false;
  String _analysisStage = '';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to ${source == ImageSource.camera ? 'capture' : 'select'} image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showErrorDialog('Please select or capture a tyre image first');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisStage = 'Uploading image...';
    });

    try {
      // Step 1: Detect damage
      setState(() {
        _analysisStage = 'Detecting tyre damage...';
      });

      final detectionResult = await _apiService.detectTyreDamage(
        imagePath: _selectedImage!.path,
        confidenceThreshold: 0.25,
        saveAnnotated: true,
      );

      setState(() {
        _analysisStage = 'Analysis complete!';
      });

      // Navigate to results screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TyreDamageResultsScreen(
            detectionResult: detectionResult,
            originalImage: _selectedImage!,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Analysis failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisStage = '';
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue, size: 30),
                title: const Text('Camera', style: TextStyle(fontSize: 16)),
                subtitle: const Text('Take a photo of the tyre'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green, size: 30),
                title: const Text('Gallery', style: TextStyle(fontSize: 16)),
                subtitle: const Text('Choose from your photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tyre Health Check'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.tire_repair,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'AI-Powered Tyre Analysis',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Get instant damage detection and life prediction for your tractor tyres',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Features list
                _buildFeatureItem(
                  Icons.search,
                  'YOLOv8 Damage Detection',
                  'Advanced AI identifies cracks and wear',
                ),
                const SizedBox(height: 15),
                _buildFeatureItem(
                  Icons.analytics,
                  'Life Prediction',
                  'Calculate remaining tyre lifespan',
                ),
                const SizedBox(height: 15),
                _buildFeatureItem(
                  Icons.chat,
                  'AI Assistant (Sinhala)',
                  'Voice guidance for usage data collection',
                ),
                const SizedBox(height: 30),

                // Image preview
                if (_selectedImage != null) ...[
                  const Text(
                    'Selected Image:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      _selectedImage!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action buttons
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _showImageSourceDialog,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(_selectedImage == null ? 'Capture/Select Tyre Image' : 'Change Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                if (_selectedImage != null)
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeImage,
                    icon: const Icon(Icons.psychology),
                    label: const Text('Analyze Tyre Condition'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                // Instructions card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Text(
                              'Tips for Best Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildTipItem('📸', 'Take a clear, well-lit photo'),
                        _buildTipItem('🎯', 'Focus on the tread and sidewall'),
                        _buildTipItem('📏', 'Capture from 1-2 meters distance'),
                        _buildTipItem('🔍', 'Ensure damage areas are visible'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(40),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _analysisStage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
