import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/l10n_extension.dart';

class LifecyclePredictionScreen extends StatefulWidget {
  const LifecyclePredictionScreen({super.key});

  @override
  State<LifecyclePredictionScreen> createState() => _LifecyclePredictionScreenState();
}

class _LifecyclePredictionScreenState extends State<LifecyclePredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partNameController = TextEditingController();
  final _usageHoursController = TextEditingController();

  File? _selectedImage;
  Map<String, dynamic>? _predictionResult;
  bool _isLoading = false;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _currentLocationName;

  @override
  void dispose() {
    _partNameController.dispose();
    _usageHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request camera/gallery permissions if needed
      if (source == ImageSource.camera) {
        // For camera, we might need to request permissions
        // The image_picker package handles this automatically, but let's add error handling
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,  // Reduce image size for better performance
        maxHeight: 1024,
        imageQuality: 85, // Good quality but smaller file size
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(source == ImageSource.camera ? 'Photo captured successfully!' : 'Image selected successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${source == ImageSource.camera ? 'capture photo' : 'select image'}: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('location_services_disabled'))),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('location_permissions_denied'))),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('location_permissions_permanently_denied'))),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get location name from coordinates (simplified - you might want to use reverse geocoding)
      String locationName = _getLocationNameFromPosition(position);

      setState(() {
        _currentPosition = position;
        _currentLocationName = locationName;
        _isLoadingLocation = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getLocationNameFromPosition(Position position) {
    // Simplified location name mapping based on Sri Lankan districts
    // In a real app, you'd use reverse geocoding API
    double lat = position.latitude;
    double lng = position.longitude;

    // Colombo district
    if (lat >= 6.8 && lat <= 7.0 && lng >= 79.8 && lng <= 80.0) {
      return 'Colombo';
    }
    // Anuradhapura district
    else if (lat >= 8.2 && lat <= 8.5 && lng >= 80.3 && lng <= 80.6) {
      return 'Anuradhapura';
    }
    // Jaffna district
    else if (lat >= 9.6 && lat <= 9.8 && lng >= 80.0 && lng <= 80.2) {
      return 'Jaffna';
    }
    // Galle district
    else if (lat >= 6.0 && lat <= 6.1 && lng >= 80.2 && lng <= 80.3) {
      return 'Galle';
    }
    // Kandy district
    else if (lat >= 7.2 && lat <= 7.4 && lng >= 80.6 && lng <= 80.8) {
      return 'Kandy';
    }
    // Default to Colombo if not matched
    return 'Colombo';
  }

  Future<void> _analyzePart() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_select_image'))),
      );
      return;
    }

    // Get location if not available
    if (_currentPosition == null) {
      await _getCurrentLocation();
      // Check again after attempting to get location
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location is required for analysis. Please enable location services.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.predictLifecycle(
        partName: _partNameController.text.trim(),
        usageHours: double.parse(_usageHoursController.text.trim()),
        location: _currentLocationName ?? 'Colombo',
        imagePath: _selectedImage!.path,
      );

      setState(() {
        _predictionResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('analysis_completed')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImageSelector() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      const Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        child: const Text('Remove Image'),
                      ),
                    ],
                  );
                },
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  context.tr('no_image_selected'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
    );
  }

  Widget _buildPredictionResult() {
    if (_predictionResult == null) return const SizedBox.shrink();

    final prediction = _predictionResult!['prediction'];
    final aiKnowledge = _predictionResult!['ai_knowledge'];
    final visualScan = _predictionResult!['visual_scan'];
    final environment = _predictionResult!['environment'];

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('analysis_results'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),

            // AI Knowledge
            _buildResultSection(
              context.tr('ai_knowledge'),
              [aiKnowledge['fresh_lifespan']],
            ),

            // Visual Scan
            _buildResultSection(
              context.tr('visual_scan'),
              [
                '${context.tr('wear_detected')}: ${visualScan['wear_detected']}',
                '${context.tr('analysis_model')}: ${visualScan['analysis_model']}',
              ],
            ),

            // Environment
            _buildResultSection(
              context.tr('environment'),
              [
                '${context.tr('location')}: ${environment['location']}',
                environment['historical_stress'],
                environment['future_forecast'],
              ],
            ),

            // Prediction
            _buildResultSection(
              context.tr('prediction'),
              [
                '${context.tr('remaining_life')}: ${prediction['remaining_life']}',
                '${context.tr('status')}: ${prediction['status']}',
              ],
            ),

            // Status Color Indicator
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(int.parse(prediction['color_code'].replaceAll('#', '0xFF'))),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  prediction['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('• $item'),
        )),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('spare_part_analysis')),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Part Name Input
              TextFormField(
                controller: _partNameController,
                decoration: InputDecoration(
                  labelText: context.tr('part_name'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.build),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('please_enter_part_name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Usage Hours Input
              TextFormField(
                controller: _usageHoursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('usage_hours'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('please_enter_usage_hours');
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours < 0) {
                    return context.tr('please_enter_valid_hours');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Selector
              Text(
                context.tr('part_image'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildImageSelector(),
              const SizedBox(height: 16),

              // Image Source Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera),
                      label: Text(context.tr('take_photo')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: Text(context.tr('choose_from_gallery')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Location Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Location for Analysis',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_currentPosition != null && _currentLocationName != null)
                      Text(
                        '📍 $_currentLocationName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'Location required for accurate analysis',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoadingLocation
                          ? const Center(child: CircularProgressIndicator())
                          : OutlinedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const Text('Get Current Location'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Analyze Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _analyzePart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('analyze_part'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

              // Prediction Results
              _buildPredictionResult(),
            ],
          ),
        ),
      ),
    );
  }
}