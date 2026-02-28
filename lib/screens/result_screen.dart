import 'package:flutter/material.dart';
import 'dart:io';
import '3D_viewer_screen.dart';
import 'part_details_screen.dart';

class ResultsScreen extends StatefulWidget {
  final File? uploadedImage;
  final String? identifiedLabel;
  final double? confidence;
  final List<dynamic>? predictions;
  final String? topPrediction;
  final double? topConfidence;

  const ResultsScreen({
    Key? key,
    this.uploadedImage,
    this.identifiedLabel,
    this.confidence,
    this.predictions,
    this.topPrediction,
    this.topConfidence,
  }) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String _selectedCategory = 'All';
  late Set<String> _favorites = {}; // Track favorite parts

  // Parts list populated from model predictions (fallback to mock data)
  late List<Map<String, dynamic>> _spareParts = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    // Build spare parts list from predictions if provided
    if (widget.predictions != null && widget.predictions!.isNotEmpty) {
      _spareParts = widget.predictions!.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value as Map<String, dynamic>;

        return {
          'name': p['name']?.toString() ?? 'Unknown',
          'partNumber': p['partNumber']?.toString() ?? 'UNKNOWN',
          'compatibility': (p['compatibility'] is List) ? List<String>.from(p['compatibility']) : ['Unknown'],
          'confidence': (p['confidence'] is num) ? (p['confidence'] as num).toDouble() : 0.0,
          'image': p['image']?.toString() ?? 'assets/spare1.jpg',
          'description': p['description']?.toString() ?? '',
          'model3dVideo': p['model3dVideo']?.toString() ?? '',
          'category': 'Engine', // keep hardcoded for now
        };
      }).toList();

      // Ensure topPrediction is first in the list
      if (widget.topPrediction != null) {
        final topIdx = _spareParts.indexWhere((p) => p['name'] == widget.topPrediction);
        if (topIdx > 0) {
          final top = _spareParts.removeAt(topIdx);
          _spareParts.insert(0, top);
        }
      }
    } else {
      // Fallback mock items
      _spareParts = [
        {
          'name': 'Engine Oil Filter',
          'partNumber': 'EF-2024-A',
          'compatibility': ['Tractor Model X100', 'Harvester H200'],
          'price': '\$45.99',
          'availability': 'In Stock',
          'confidence': 98,
          'image': 'assets/spare1.jpg',
          'category': 'Engine'
        },
        {
          'name': 'Oil Filter Premium',
          'partNumber': 'EF-2024-B',
          'compatibility': ['Tractor Model X100', 'Plough P150'],
          'price': '\$52.99',
          'availability': 'In Stock',
          'confidence': 95,
          'image': 'assets/spare2.jpg',
          'category': 'Engine'
        },
      ];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredParts {
    if (_selectedCategory == 'All') return _spareParts;
    return _spareParts.where((part) => part['category'] == _selectedCategory).toList();
  }

  void _navigateTo3DView(Map<String, dynamic> part) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Model3DViewerScreen(sparePart: part),
      ),
    );
  }

  void _navigateToPartDetails(Map<String, dynamic> part) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartDetailsScreen(sparePart: part, uploadedImage: widget.uploadedImage),
      ),
    );
  }

  void _toggleFavorite(Map<String, dynamic> part) {
    setState(() {
      final partId = part['partNumber'];
      if (_favorites.contains(partId)) {
        _favorites.remove(partId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        _favorites.add(partId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Identification Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Uploaded Image Preview Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Uploaded Image
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: widget.uploadedImage != null
                                ? Image.file(
                                    widget.uploadedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Identified Successfully',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Show top prediction if available
                              if (widget.topPrediction != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Top: ${widget.topPrediction}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    ),
                                    if (widget.topConfidence != null)
                                      Text(
                                        '${widget.topConfidence!.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ] else if (widget.identifiedLabel != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Label: ${widget.identifiedLabel}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],

                              // Predictions are shown in the main list below; removed compact header list
                              const SizedBox(height: 8),
                              Text(
                                '${_spareParts.length} similar parts found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Category: Engine Parts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Category Filter Chips
                  Container(
                    height: 50,
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip('All'),
                        _buildCategoryChip('Engine'),
                        _buildCategoryChip('Transmission'),
                        _buildCategoryChip('Hydraulic'),
                        _buildCategoryChip('Electrical'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Similar Parts List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredParts.length,
                itemBuilder: (context, index) {
                  return _buildSparePartCard(_filteredParts[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.green.shade100,
        checkmarkColor: Colors.green.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildSparePartCard(Map<String, dynamic> part, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _navigateTo3DView(part),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Part Image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildPartImage(part['image']),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                part['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _favorites.contains(part['partNumber']) ? Icons.favorite : Icons.favorite_border,
                                color: _favorites.contains(part['partNumber']) ? Colors.red : Colors.grey,
                                size: 24,
                              ),
                              onPressed: () => _toggleFavorite(part),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Part #: ${part['partNumber']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (part['description'] != null && part['description'].toString().isNotEmpty) ...[const SizedBox(height: 4),
                              Text(
                                part['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getConfidenceColor(part['confidence']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(part['confidence'] is double ? part['confidence'].toStringAsFixed(1) : part['confidence'].toString())}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.precision_manufacturing, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Compatible: ${part['compatibility'].join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _navigateToPartDetails(part),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _navigateTo3DView(part),
                      icon: const Icon(Icons.view_in_ar, size: 18),
                      label: const Text('3D View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Renders a part image from either a URL or an asset path.
  Widget _buildPartImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Center(
        child: Icon(Icons.settings, size: 50, color: Colors.grey.shade400),
      );
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400),
        ),
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(Icons.settings, size: 50, color: Colors.grey.shade400),
      ),
    );
  }

  Color _getConfidenceColor(dynamic confidence) {
    double value;
    if (confidence is int) {
      value = confidence.toDouble();
    } else if (confidence is double) {
      value = confidence;
    } else {
      value = 0.0;
    }
    if (value >= 85) return Colors.green.shade600;
    if (value >= 70) return Colors.blue.shade600;
    return Colors.orange.shade600;
  }
}