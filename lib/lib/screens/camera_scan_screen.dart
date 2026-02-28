import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/l10n.dart';
import '../services/l10n_extension.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      
      if (status.isDenied || status.isPermanentlyDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tr('camera_error'))),
        );
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tr('no_camera_found'))),
        );
        return;
      }

      _cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${context.l10n.tr('camera_error')}: $e")),
      );
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
        _isProcessing = false;
      });

      // Show preview dialog
      if (!mounted) return;
      _showImagePreview(image);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${context.l10n.tr('capture_failed')}: $e")),
      );
    }
  }

  void _showImagePreview(XFile image) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(image.path)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _capturedImage = null);
                      Navigator.pop(dialogContext);
                    },
                    child: Text(context.tr('retake')),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _analyzeImage(image);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.tr('analyze')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeImage(XFile image) async {
    // TODO: Send image to backend for analysis
    // For now, just show a success message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('analyzing_spare_part')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.tr('wear_detection')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Stack(
              children: [
                // Camera Preview
                SizedBox.expand(
                  child: CameraPreview(_cameraController!),
                ),

                // Scanning Frame Overlay
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF2E7D32),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Corner indicators
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Color(0xFF2E7D32), width: 5),
                                left: BorderSide(
                                    color: Color(0xFF2E7D32), width: 5),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Color(0xFF2E7D32), width: 5),
                                right: BorderSide(
                                    color: Color(0xFF2E7D32), width: 5),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Color(0xFF2E7D32), width: 5),
                                left: BorderSide(
                                    color: Color(0xFF2E7D32), width: 5),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Color(0xFF2E7D32), width: 5),
                                right: BorderSide(
                                    color: Color(0xFF2E7D32), width: 5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Instructions
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: const Text(
                      "Position the spare part within the frame",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ),

                // Capture Button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _captureImage,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF2E7D32),
                            width: 5,
                          ),
                        ),
                        child: _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(15.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2E7D32),
                                ),
                              )
                            : const Icon(
                                Icons.camera,
                                size: 35,
                                color: Color(0xFF2E7D32),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
