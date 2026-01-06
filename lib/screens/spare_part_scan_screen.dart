import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/error_handler.dart';
import 'package:lottie/lottie.dart';

class SparePartScanScreen extends StatefulWidget {
  const SparePartScanScreen({super.key});

  @override
  State<SparePartScanScreen> createState() => _SparePartScanScreenState();
}

class _SparePartScanScreenState extends State<SparePartScanScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _partNameController = TextEditingController();
  final _usageHoursController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  File? _selectedImage;
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisStage = '';
  Map<String, dynamic>? _predictionResult;
  String _currentLocationName = 'Unknown';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _usageHoursController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _captureImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _predictionResult = null;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzePart() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or select an image first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.0;
      _analysisStage = 'Initializing...';
    });

    _animationController.repeat();

    try {
      // Stage 1: Uploading
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _analysisProgress = 0.15;
        _analysisStage = 'Uploading image...';
      });

      // Stage 2: Processing image
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _analysisProgress = 0.35;
        _analysisStage = 'Processing image with AI...';
      });

      // Stage 3: Analyzing damage
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _analysisProgress = 0.55;
        _analysisStage = 'Analyzing visual damage...';
      });

      // Make actual API call
      final result = await _apiService.predictLifecycle(
        partName: _partNameController.text.trim(),
        usageHours: double.parse(_usageHoursController.text.trim()),
        location: _currentLocationName,
        imagePath: _selectedImage!.path,
      );

      // Stage 4: Calculating
      if (!mounted) return;
      setState(() {
        _analysisProgress = 0.85;
        _analysisStage = 'Calculating predictions...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Complete
      if (!mounted) return;
      setState(() {
        _analysisProgress = 1.0;
        _analysisStage = 'Analysis complete!';
        _predictionResult = result;
        _isAnalyzing = false;
      });

      _animationController.stop();
      _animationController.reset();

      // Check if condition is critical
      _checkCriticalCondition(result);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisProgress = 0.0;
      });
      _animationController.stop();
      _animationController.reset();

      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getUserFriendlyMessage(e),
      );
    }
  }

  void _checkCriticalCondition(Map<String, dynamic> result) {
    try {
      // Safely extract prediction data
      final prediction = result['prediction'] as Map<String, dynamic>?;
      if (prediction == null) {
        print('⚠️ No prediction data in result');
        return;
      }

      final status = (prediction['status'] as String?)?.toLowerCase() ?? '';
      final remainingLife = prediction['remaining_life_hours'] as int? ?? 
                           (prediction['remaining_life_hours'] as double?)?.toInt() ?? 0;

      print('🔍 Checking condition - Status: $status, Remaining Life: $remainingLife hours');

      // Check if critical (bad status or remaining life < 100 hours)
      if (status == 'critical' || status == 'bad' || remainingLife < 100) {
        print('⚠️ Critical condition detected!');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _showRecommendationDialog();
        });
      }
    } catch (e) {
      print('❌ Error checking critical condition: $e');
      // Don't show error to user, just log it
    }
  }

  void _showRecommendationDialog() {
    // Get prediction details for the dialog
    final prediction = _predictionResult?['prediction'] as Map<String, dynamic>?;
    final status = prediction?['status'] as String? ?? 'critical';
    final remainingLife = prediction?['remaining_life_hours'] as int? ?? 
                         (prediction?['remaining_life_hours'] as double?)?.toInt() ?? 0;
    
    // Determine urgency level
    String urgencyMessage;
    Color urgencyColor;
    IconData urgencyIcon;
    
    if (remainingLife < 50 || status == 'critical') {
      urgencyMessage = 'URGENT: This part needs immediate replacement!';
      urgencyColor = Colors.red;
      urgencyIcon = Icons.error_outline;
    } else if (remainingLife < 100 || status == 'bad') {
      urgencyMessage = 'WARNING: This part needs replacement soon.';
      urgencyColor = Colors.orange;
      urgencyIcon = Icons.warning_amber_rounded;
    } else {
      urgencyMessage = 'This part is approaching end of life.';
      urgencyColor = Colors.orange;
      urgencyIcon = Icons.info_outline;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(urgencyIcon, color: urgencyColor, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Critical Spare Part',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              urgencyMessage,
              style: TextStyle(
                color: urgencyColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Part: ${_partNameController.text}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text('Remaining Life: $remainingLife hours'),
                  Text('Condition: ${status.toUpperCase()}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We will automatically create a spare part request and notify nearby verified sellers.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _createSparePartRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send Request Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSparePartRequest() async {
    if (_selectedImage == null || _predictionResult == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating spare part request...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Upload image first
      final imageUrl = await _apiService.uploadSparePartImage(_selectedImage!.path);

      // Safely extract prediction data with null checks and backward compatibility
      final prediction = _predictionResult!['prediction'] as Map<String, dynamic>?;
      final visualScan = _predictionResult!['visual_scan'] as Map<String, dynamic>?;
      
      if (prediction == null) {
        throw Exception('Prediction data is missing from API response');
      }

      final status = prediction['status'] as String? ?? 'unknown';
      
      // Support both old and new API response formats
      int remainingLife;
      int estimatedLife;
      
      if (prediction['remaining_life_hours'] != null) {
        // New format - direct integer values
        remainingLife = prediction['remaining_life_hours'] as int? ?? 
                       (prediction['remaining_life_hours'] as double?)?.toInt() ?? 0;
        estimatedLife = prediction['estimated_life_hours'] as int? ?? 
                       (prediction['estimated_life_hours'] as double?)?.toInt() ?? 0;
      } else {
        // Old format - extract from string "X Days (Y hours)"
        final remainingLifeStr = prediction['remaining_life'] as String? ?? '0 Days (0 hours)';
        final match = RegExp(r'\((\d+) hours\)').firstMatch(remainingLifeStr);
        remainingLife = match != null ? int.parse(match.group(1)!) : 0;
        estimatedLife = remainingLife; // Fallback if no estimated life
      }
      
      final visualDamage = (visualScan?['wear_detected'] as String? ?? '0%').replaceAll('%', '');
      
      // Ensure location is never null
      final location = _currentLocationName ?? 'Unknown Location';
      
      // Create description with all prediction details
      final description = '''
Spare part needed based on AI analysis:

Part Name: ${_partNameController.text.isEmpty ? 'Unknown Part' : _partNameController.text}
Usage Hours: ${_usageHoursController.text.isEmpty ? '0' : _usageHoursController.text}
Location: $location

Condition Status: $status
Estimated Life: $estimatedLife hours
Remaining Life: $remainingLife hours
Visual Damage: $visualDamage%

AI Analysis: ${visualScan?['analysis_model'] ?? 'N/A'}
Recommendation: Replacement ${remainingLife < 100 ? 'URGENT' : remainingLife < 300 ? 'SOON' : 'when convenient'}
''';

      // Create request using the existing createSparePartRequest method
      await _apiService.createSparePartRequest(
        title: 'Spare Part Request: ${_partNameController.text.isEmpty ? 'Unknown Part' : _partNameController.text}',
        description: description,
        category: 'spare_parts',
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Request Created'),
            ],
          ),
          content: const Text(
            'Your spare part request has been created successfully. Sellers will be notified and you will receive offers soon.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Try to navigate, fallback to pop if route doesn't exist
                try {
                  Navigator.pushReplacementNamed(context, '/spare-parts');
                } catch (e) {
                  print('⚠️ Spare parts route not found, going back instead');
                  Navigator.pop(context); // Just go back if route doesn't exist
                }
              },
              child: const Text('View Requests'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog
      
      // Check if it's a session expired error
      final errorMessage = e.toString();
      final isSessionExpired = errorMessage.contains('Session expired') || 
                               errorMessage.contains('Not authenticated') ||
                               errorMessage.contains('login again');
      
      if (isSessionExpired) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Session Expired'),
              ],
            ),
            content: const Text(
              'Your session has expired. Please log in again to continue. Your spare part image has been saved and you can create the request after logging in.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Navigate to login - user will be redirected automatically
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create request: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good':
      case 'excellent':
        return Colors.green;
      case 'fair':
      case 'warning':
        return Colors.orange;
      case 'bad':
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'good':
      case 'excellent':
        return Icons.check_circle;
      case 'fair':
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'bad':
      case 'critical':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spare Part Analysis'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Preview
                    GestureDetector(
                      onTap: _isAnalyzing ? null : _showImageSourceDialog,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, 
                                    size: 64, 
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to capture or select image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Part Name
                    TextFormField(
                      controller: _partNameController,
                      enabled: !_isAnalyzing,
                      decoration: const InputDecoration(
                        labelText: 'Part Name',
                        hintText: 'e.g., Battery, Fan Belt, Tire',
                        prefixIcon: Icon(Icons.build),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter part name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Usage Hours
                    TextFormField(
                      controller: _usageHoursController,
                      enabled: !_isAnalyzing,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Usage Hours',
                        hintText: 'e.g., 500',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                        suffixText: 'hours',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter usage hours';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Analysis Progress
                    if (_isAnalyzing) ...[
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Animated Icon
                              SizedBox(
                                height: 100,
                                width: 100,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: _analysisProgress,
                                      strokeWidth: 6,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2E7D32),
                                      ),
                                    ),
                                    AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _animationController.value * 2 * 3.14159,
                                          child: const Icon(
                                            Icons.auto_fix_high,
                                            size: 40,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _analysisStage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_analysisProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Prediction Results
                    if (_predictionResult != null && !_isAnalyzing) ...[
                      Card(
                        elevation: 4,
                        color: _getStatusColor(_predictionResult!['prediction']['status'])
                            .withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                _getStatusIcon(_predictionResult!['prediction']['status']),
                                size: 64,
                                color: _getStatusColor(_predictionResult!['prediction']['status']),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Status: ${_predictionResult!['prediction']['status']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_predictionResult!['prediction']['status']),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildResultRow(
                                'Remaining Life',
                                '${_predictionResult!['prediction']['remaining_life_hours'] ?? _predictionResult!['prediction']['remaining_life'] ?? 0} hours',
                                Icons.timelapse,
                              ),
                              const Divider(height: 24),
                              _buildResultRow(
                                'Visual Damage',
                                '${((_predictionResult!['visual_scan']?['wear_detected'] as String? ?? '0%').replaceAll('%', ''))}%',
                                Icons.visibility,
                              ),
                              const Divider(height: 24),
                              _buildResultRow(
                                'AI Model Used',
                                _predictionResult!['prediction']['analysis_model'] ?? _predictionResult!['analysis_model'] ?? 'Standard',
                                Icons.smart_toy,
                              ),
                              if (_predictionResult!['prediction']['recommendation'] != null || _predictionResult!['recommendation'] != null) ...[
                                const Divider(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.lightbulb, 
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _predictionResult!['prediction']['recommendation'] ?? _predictionResult!['recommendation'] ?? 'No specific recommendations',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isAnalyzing
          ? null
          : FloatingActionButton.extended(
              onPressed: _selectedImage == null ? _showImageSourceDialog : _analyzePart,
              backgroundColor: const Color(0xFF2E7D32),
              icon: Icon(_selectedImage == null ? Icons.camera_alt : Icons.search),
              label: Text(_selectedImage == null ? 'SCAN' : 'ANALYZE'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
