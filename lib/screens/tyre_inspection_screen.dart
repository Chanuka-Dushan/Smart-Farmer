import 'dart:io';
import 'dart:math' as math;
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
  String _processingStage = '';
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

  void _beginProcessing(String stage) {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _processingStage = stage;
    });
  }

  void _endProcessing() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _processingStage = '';
    });
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
    _beginProcessing('Capturing tyre image…');
    try {
      final file = await _cameraController!.takePicture();
      _captured = file;

      _beginProcessing('YOLOv8 is thinking about the live tyre image…');
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (!mounted) return;
      setState(() {
        _processingStage = 'Scanning tread, cracks, and sidewall…';
      });

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
      _endProcessing();
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2000, maxHeight: 2000, imageQuality: 90);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _cropSelectedToROI() async {
    if (_selectedImage == null) return;
    _beginProcessing('Cropping the selected tyre image…');
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
      _endProcessing();
    }
  }

  Future<void> _analyzeSelected() async {
    if (_selectedImage == null) return;
    _beginProcessing('YOLOv8 is thinking about your tyre image…');
    try {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (!mounted) return;
      setState(() {
        _processingStage = 'Scanning tread, cracks, and sidewall…';
      });

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
      _endProcessing();
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
      body: Stack(
        children: [
          Column(
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
                        label: Text(_isProcessing ? 'YOLOv8 is thinking...' : 'Analyze'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          if (_isProcessing)
            _TyreProcessingOverlay(stage: _processingStage),
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

class _TyreProcessingOverlay extends StatefulWidget {
  final String stage;

  const _TyreProcessingOverlay({required this.stage});

  @override
  State<_TyreProcessingOverlay> createState() => _TyreProcessingOverlayState();
}

class _TyreProcessingOverlayState extends State<_TyreProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF2E7D32);
    const deepForest = Color(0xFF0F3D1F);
    const leaf = Color(0xFF7BC96F);

    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDF9F2), Color(0xFFF3EFE7)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: deepForest.withOpacity(0.28),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: forest.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.memory_rounded, color: forest, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'YOLOv8 Vision Core',
                      style: TextStyle(
                        color: forest.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 130,
                height: 130,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final pulse = 0.9 + (math.sin(_controller.value * math.pi * 2) * 0.08);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: pulse,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: leaf.withOpacity(0.25),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: _controller.value * math.pi * 2,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0x00000000),
                                  Color(0x667BC96F),
                                  Color(0x00000000),
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.32, 0.48, 0.64, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: forest.withOpacity(0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [deepForest, leaf]),
                            boxShadow: [
                              BoxShadow(
                                color: leaf.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'YOLOv8 is thinking...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: deepForest,
                  fontFamily: 'Georgia',
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.stage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: deepForest.withOpacity(0.72),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final wave = (math.sin((_controller.value * math.pi * 2) - (index * 0.6)) + 1) / 2;
                      return Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: leaf.withOpacity(0.35 + (wave * 0.65)),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 14),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: forest.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment(-1 + (_controller.value * 2), 0),
                        child: FractionallySizedBox(
                          widthFactor: 0.34,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [deepForest, leaf]),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Scanning tread, cracks, bulges, and wear patterns',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: deepForest.withOpacity(0.52),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
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
