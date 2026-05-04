import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../services/api_service.dart';
import 'tyre_damage_results_screen.dart';

class TyreInspectionScreen extends StatefulWidget {
  const TyreInspectionScreen({Key? key}) : super(key: key);

  @override
  State<TyreInspectionScreen> createState() => _TyreInspectionScreenState();
}

class _TyreInspectionScreenState extends State<TyreInspectionScreen> {
  bool _liveMode = true;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _isProcessing = false;
  XFile? _captured;

  // Upload
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(_cameras[0], ResolutionPreset.medium, enableAudio: false);
        await _cameraController!.initialize();
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      // ignore - camera may be unavailable on simulators
      setState(() => _cameraReady = false);
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() => _isProcessing = true);
    try {
      final file = await _cameraController!.takePicture();
      _captured = file;

      // Send to backend
      final result = await _api.detectTyreDamage(imagePath: file.path);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TyreDamageResultsScreen(
            detectionResult: result,
            originalImage: File(file.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2000, maxHeight: 2000, imageQuality: 90);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _cropSelectedToROI() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final w = decoded.width;
      final h = decoded.height;

      // Crop square centered with side = min(w,h) * 0.75 (based on circle guide)
      final side = ((w < h ? w : h) * 0.75).toInt();
      final left = ((w - side) / 2).toInt();
      final top = ((h - side) / 2).toInt();

      final cropped = img.copyCrop(decoded, x: left, y: top, width: side, height: side);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/tyre_cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));

      if (!mounted) return;
      setState(() {
        _selectedImage = outFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Cropped to ROI - you can zoom/pan and crop again if needed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Crop failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _analyzeSelected() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _api.detectTyreDamage(imagePath: _selectedImage!.path);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TyreDamageResultsScreen(
            detectionResult: result,
            originalImage: _selectedImage!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tyre Inspection'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: [
          // Mode toggle
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _liveMode = true),
                    style: ElevatedButton.styleFrom(backgroundColor: _liveMode ? const Color(0xFF2E7D32) : Colors.grey),
                    child: const Text('Live Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _liveMode = false),
                    style: ElevatedButton.styleFrom(backgroundColor: !_liveMode ? const Color(0xFF2E7D32) : Colors.grey),
                    child: const Text('Upload Image'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _liveMode ? _buildLiveView() : _buildUploadView(),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : (_liveMode ? _captureAndAnalyze : _analyzeSelected),
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(_isProcessing ? 'Processing...' : 'Analyze'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLiveView() {
    if (!_cameraReady || _cameraController == null) {
      return const Center(child: Text('Camera unavailable'));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        // Circular ROI overlay - full screen
        Center(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: _CircleOverlayPainter(),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black45,
            child: const Text('Align tyre inside circle', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadView() {
    return Column(
      children: [
        Expanded(
          child: _selectedImage == null
              ? Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Image'),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image with zoom/pan capability
                    InteractiveViewer(
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 0.3,
                      maxScale: 5.0,
                      boundaryMargin: const EdgeInsets.all(100),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Circular ROI overlay - GESTURE TRANSPARENT
                    IgnorePointer(
                      child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: CustomPaint(painter: _CircleOverlayPainter()),
                        ),
                      ),
                    ),
                    // Info text on bottom left
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black45,
                          child: const Text(
                            'Pinch to zoom • Drag to move • Tap Crop when ready',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _cropSelectedToROI,
                    icon: const Icon(Icons.crop),
                    label: const Text('Crop to ROI'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.change_circle),
                    label: const Text('Change'),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}

class _CircleOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Center of canvas
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    // Circle radius - use smaller dimension to fit on screen
    final r = (size.width < size.height ? size.width : size.height) / 2.2;

    // Draw dimmed background with transparent circle cutout
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawPath(Path.combine(PathOperation.difference, path, Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))), paint);

    // Draw circle border - thick and bright
    final border = Paint()
      ..color = Colors.amber[300] ?? Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(Offset(cx, cy), r, border);

    // Draw inner guide circle (faint)
    final innerGuide = Paint()
      ..color = Colors.yellow.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), r * 0.7, innerGuide);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
