import 'package:flutter/material.dart';
import 'dart:math' as math;

class Model3DViewerScreen extends StatefulWidget {
  final Map<String, dynamic>? sparePart;

  const Model3DViewerScreen({Key? key, this.sparePart}) : super(key: key);

  @override
  State<Model3DViewerScreen> createState() => _Model3DViewerScreenState();
}

class _Model3DViewerScreenState extends State<Model3DViewerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  bool _isAutoRotating = true;
  bool _showLabels = true;
  bool _highlightMode = true;
  String _selectedView = '3D';
  double _rotationAngle = 0.0;
  Offset? _lastPanPosition;

  final List<Map<String, dynamic>> _machineParts = [
    {
      'name': 'Oil Filter',
      'position': const Offset(0.3, 0.4),
      'highlighted': true,
      'description': 'Main filtration component',
    },
    {
      'name': 'Engine Block',
      'position': const Offset(0.5, 0.5),
      'highlighted': false,
      'description': 'Core engine housing',
    },
    {
      'name': 'Fuel Pump',
      'position': const Offset(0.7, 0.35),
      'highlighted': false,
      'description': 'Fuel delivery system',
    },
    {
      'name': 'Air Filter',
      'position': const Offset(0.2, 0.6),
      'highlighted': false,
      'description': 'Air intake filtration',
    },
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleAutoRotation() {
    setState(() {
      _isAutoRotating = !_isAutoRotating;
      if (_isAutoRotating) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isAutoRotating) {
      setState(() {
        _rotationAngle += details.delta.dx * 0.01;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text(
          '3D Model Viewer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isAutoRotating ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoRotation,
            tooltip: _isAutoRotating ? 'Pause Rotation' : 'Auto Rotate',
          ),
        ],
      ),
      body: Column(
        children: [
          // Part Information Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sparePart?['name'] ?? 'Engine Oil Filter',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Part #: ${widget.sparePart?['partNumber'] ?? 'EF-2024-A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // 3D View Container
          Expanded(
            child: Stack(
              children: [
                // Main 3D View
                GestureDetector(
                  onPanUpdate: _handlePanUpdate,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.grey.shade800,
                          Colors.grey.shade900,
                        ],
                        center: Alignment.center,
                        radius: 1.0,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: Machine3DPainter(
                            rotation: _isAutoRotating
                                ? _rotationController.value * 2 * math.pi
                                : _rotationAngle,
                            highlightMode: _highlightMode,
                            pulseValue: _pulseController.value,
                          ),
                          child: child,
                        );
                      },
                      child: Stack(
                        children: _showLabels
                            ? _machineParts.map((part) {
                                return _buildPartLabel(
                                  part['name'],
                                  part['position'],
                                  part['highlighted'],
                                  part['description'],
                                );
                              }).toList()
                            : [],
                      ),
                    ),
                  ),
                ),

                // View Mode Selector
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewButton('3D', Icons.view_in_ar),
                        _buildViewButton('Front', Icons.crop_square),
                        _buildViewButton('Side', Icons.crop_portrait),
                      ],
                    ),
                  ),
                ),

                // Control Hint
                if (!_isAutoRotating)
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Drag to rotate',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Toggle Switches
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToggleButton(
                      icon: Icons.label,
                      label: 'Labels',
                      isActive: _showLabels,
                      onTap: () => setState(() => _showLabels = !_showLabels),
                    ),
                    _buildToggleButton(
                      icon: Icons.highlight,
                      label: 'Highlight',
                      isActive: _highlightMode,
                      onTap: () => setState(() => _highlightMode = !_highlightMode),
                    ),
                    _buildToggleButton(
                      icon: Icons.fullscreen,
                      label: 'Fullscreen',
                      isActive: false,
                      onTap: () {
                        // Implement fullscreen
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Part Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(
                                    0.5 + (_pulseController.value * 0.5),
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 8 * _pulseController.value,
                                      spreadRadius: 2 * _pulseController.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Highlighted Part: Oil Filter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Location: Front right section of the engine block\nAccess: Remove protective cover first',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showInstructionsDialog();
                              },
                              icon: const Icon(Icons.build, size: 18),
                              label: const Text('Instructions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showSpecsDialog();
                              },
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Specs'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, IconData icon) {
    final isSelected = _selectedView == label;
    return InkWell(
      onTap: () => setState(() => _selectedView = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartLabel(
    String name,
    Offset position,
    bool highlighted,
    String description,
  ) {
    return Positioned(
      left: MediaQuery.of(context).size.width * position.dx,
      top: MediaQuery.of(context).size.height * position.dy,
      child: GestureDetector(
        onTap: () {
          _showPartDetails(name, description);
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: highlighted
                    ? Colors.green.withOpacity(0.7 + (_pulseController.value * 0.3))
                    : Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: highlighted ? Colors.green.shade300 : Colors.white30,
                  width: highlighted ? 2 : 1,
                ),
                boxShadow: highlighted
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 10 * _pulseController.value,
                          spreadRadius: 2 * _pulseController.value,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (highlighted)
                    Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                  if (highlighted) const SizedBox(width: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPartDetails(String name, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replacement Instructions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Step 1: Turn off the engine and let it cool',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Step 2: Locate the oil filter housing'),
              SizedBox(height: 8),
              Text('Step 3: Remove the protective cover'),
              SizedBox(height: 8),
              Text('Step 4: Unscrew the old filter counterclockwise'),
              SizedBox(height: 8),
              Text('Step 5: Clean the mounting surface'),
              SizedBox(height: 8),
              Text('Step 6: Install new filter and hand-tighten'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSpecsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Technical Specifications'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Diameter: 3.5 inches'),
            SizedBox(height: 8),
            Text('Height: 4.2 inches'),
            SizedBox(height: 8),
            Text('Thread Size: 3/4-16 UNF'),
            SizedBox(height: 8),
            Text('Filter Media: Synthetic blend'),
            SizedBox(height: 8),
            Text('Micron Rating: 25'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for 3D machine visualization
class Machine3DPainter extends CustomPainter {
  final double rotation;
  final bool highlightMode;
  final double pulseValue;

  Machine3DPainter({
    required this.rotation,
    required this.highlightMode,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw machine body (simplified 3D representation)
    final bodyPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;

    final bodyPath = Path();
    final width = 200.0;
    final height = 250.0;
    
    // Apply rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // Draw main body (pseudo 3D box)
    bodyPath.moveTo(center.dx - width / 2, center.dy - height / 2);
    bodyPath.lineTo(center.dx + width / 2, center.dy - height / 2);
    bodyPath.lineTo(center.dx + width / 2, center.dy + height / 2);
    bodyPath.lineTo(center.dx - width / 2, center.dy + height / 2);
    bodyPath.close();
    
    canvas.drawPath(bodyPath, bodyPaint);

    // Draw 3D effect edges
    final edgePaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(bodyPath, edgePaint);

    // Draw highlighted part (oil filter location)
    if (highlightMode) {
      final highlightPaint = Paint()
        ..color = Colors.green.withOpacity(0.5 + (pulseValue * 0.3))
        ..style = PaintingStyle.fill;

      final highlightGlow = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * pulseValue);

      canvas.drawCircle(
        Offset(center.dx + 40, center.dy - 20),
        30 + (5 * pulseValue),
        highlightGlow,
      );
      
      canvas.drawCircle(
        Offset(center.dx + 40, center.dy - 20),
        25,
        highlightPaint,
      );
    }

    // Draw some detail lines
    final detailPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(center.dx - width / 2 + 20, center.dy - height / 2 + 50 + (i * 30)),
        Offset(center.dx + width / 2 - 20, center.dy - height / 2 + 50 + (i * 30)),
        detailPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant Machine3DPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.highlightMode != highlightMode ||
        oldDelegate.pulseValue != pulseValue;
  }
}