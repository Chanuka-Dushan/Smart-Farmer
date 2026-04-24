import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'tyre_damage_results_screen.dart';

class TyreHealthScreen extends StatefulWidget {
  const TyreHealthScreen({super.key});

  @override
  State<TyreHealthScreen> createState() => _TyreHealthScreenState();
}

class _TyreHealthScreenState extends State<TyreHealthScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  File? _selectedImage;
  bool _isAnalyzing = false;
  String _analysisStage = '';
  int _activeFeatureCard = 0;
  final PageController _pageController = PageController(viewportFraction: 0.88);

  // ── Design tokens ───────────────────────────────────────────
  static const _forest = Color(0xFF0D3320);
  static const _forestMid = Color(0xFF1B5E35);
  static const _forestLight = Color(0xFF2E7D4F);
  static const _leaf = Color(0xFF52C27A);
  static const _cream = Color(0xFFF6F1E7);
  static const _warmWhite = Color(0xFFFCF9F3);
  static const _charcoal = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF9A9A9A);

  late AnimationController _heroAnim;
  late AnimationController _staggerAnim;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _staggerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _heroFade =
        CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutCubic));

    _heroAnim.forward();
    Future.delayed(
        const Duration(milliseconds: 200), () => _staggerAnim.forward());
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _staggerAnim.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Feature cards data ──────────────────────────────────────
  final List<_FeatureCardData> _features = const [
    _FeatureCardData(
      icon: Icons.radar_rounded,
      title: 'YOLOv8 Detection',
      subtitle: 'Damage Recognition',
      description:
          'State-of-the-art object detection identifies cracks, bulges, and wear patterns with high precision.',
      gradient: [Color(0xFF0D3320), Color(0xFF1B6B38)],
      accentColor: Color(0xFF52C27A),
      tag: 'AI · Vision',
    ),
    _FeatureCardData(
      icon: Icons.timeline_rounded,
      title: 'Life Prediction',
      subtitle: 'Remaining Lifespan',
      description:
          'Combines damage severity with your usage data to calculate how many months your tyre will last.',
      gradient: [Color(0xFF0D2B4A), Color(0xFF1565A0)],
      accentColor: Color(0xFF64B5F6),
      tag: 'Analytics',
    ),
    _FeatureCardData(
      icon: Icons.record_voice_over_rounded,
      title: 'AI Assistant',
      subtitle: 'Sinhala Voice Guide',
      description:
          'Conversational AI in Sinhala collects your usage context through natural voice or text interaction.',
      gradient: [Color(0xFF3A0A2E), Color(0xFF7B1FA2)],
      accentColor: Color(0xFFCE93D8),
      tag: 'NLP · Voice',
    ),
  ];

  // ── Actions ─────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image != null) {
        HapticFeedback.mediumImpact();
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      _showError(
          'Failed to ${source == ImageSource.camera ? "capture" : "select"} image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isAnalyzing = true;
      _analysisStage = 'Uploading image…';
    });
    try {
      setState(() => _analysisStage = 'Detecting tyre damage…');
      final result = await _apiService.detectTyreDamage(
        imagePath: _selectedImage!.path,
        confidenceThreshold: 0.25,
        saveAnnotated: true,
      );
      setState(() => _analysisStage = 'Analysis complete!');
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
      _showError('Analysis failed: $e');
    } finally {
      if (mounted) setState(() { _isAnalyzing = false; _analysisStage = ''; });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Error', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: _forestLight, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        onCamera: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
        onGallery: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
        forest: _forest,
        forestLight: _forestLight,
        leaf: _leaf,
        cream: _cream,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _cream,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Collapsing hero header ───────────────────
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  stretch: true,
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: _HeroHeader(
                      heroFade: _heroFade,
                      heroSlide: _heroSlide,
                      forest: _forest,
                      forestMid: _forestMid,
                      leaf: _leaf,
                    ),
                  ),
                  title: const Text(
                    'Tyre Health Check',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                // ── Body ────────────────────────────────────
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                        parent: _staggerAnim, curve: Curves.easeIn),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),

                        // Section label
                        _SectionLabel(
                            label: 'CAPABILITIES', forest: _forest),
                        const SizedBox(height: 14),

                        // Feature cards slider
                        SizedBox(
                          height: 210,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _features.length,
                            onPageChanged: (i) =>
                                setState(() => _activeFeatureCard = i),
                            itemBuilder: (_, i) => _FeatureCard(
                              data: _features[i],
                              isActive: i == _activeFeatureCard,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dots indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _features.length,
                            (i) => _DotIndicator(
                              active: i == _activeFeatureCard,
                              forest: _forest,
                              leaf: _leaf,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Image upload area
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _ImageUploadArea(
                            selectedImage: _selectedImage,
                            isAnalyzing: _isAnalyzing,
                            onTap: _showImageSourceSheet,
                            forest: _forest,
                            forestLight: _forestLight,
                            leaf: _leaf,
                            cream: _cream,
                            muted: _muted,
                          ),
                        ),

                        // Analyze button
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _AnalyzeButton(
                              onTap: _isAnalyzing ? null : _analyzeImage,
                              forest: _forest,
                              forestMid: _forestMid,
                              leaf: _leaf,
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Tips card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _TipsCard(
                            forest: _forest,
                            forestLight: _forestLight,
                            leaf: _leaf,
                            warmWhite: _warmWhite,
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Analyzing overlay ────────────────────────────
            if (_isAnalyzing)
              _AnalyzingOverlay(
                stage: _analysisStage,
                forest: _forest,
                leaf: _leaf,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final Color forest, forestMid, leaf;

  const _HeroHeader({
    required this.heroFade,
    required this.heroSlide,
    required this.forest,
    required this.forestMid,
    required this.leaf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [forest, forestMid],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: leaf.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -30,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 56,
              24,
              24,
            ),
            child: SlideTransition(
              position: heroSlide,
              child: FadeTransition(
                opacity: heroFade,
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.tire_repair_rounded,
                        color: leaf,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'AI-Powered Analysis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Georgia',
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Instant damage detection & lifespan prediction',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Feature card data
// ─────────────────────────────────────────────────────────────
class _FeatureCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final Color accentColor;
  final String tag;

  const _FeatureCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.accentColor,
    required this.tag,
  });
}

// ─────────────────────────────────────────────────────────────
// Feature card
// ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final _FeatureCardData data;
  final bool isActive;

  const _FeatureCard({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        right: 12,
        top: isActive ? 0 : 12,
        bottom: isActive ? 0 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: data.gradient.last.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -20, bottom: -20,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accentColor.withOpacity(0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + tag
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: data.accentColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(data.icon, color: data.accentColor, size: 22),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        data.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: data.accentColor.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  data.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dot indicator
// ─────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final bool active;
  final Color forest, leaf;

  const _DotIndicator({
    required this.active,
    required this.forest,
    required this.leaf,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? forest : forest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Image upload area
// ─────────────────────────────────────────────────────────────
class _ImageUploadArea extends StatelessWidget {
  final File? selectedImage;
  final bool isAnalyzing;
  final VoidCallback onTap;
  final Color forest, forestLight, leaf, cream, muted;

  const _ImageUploadArea({
    required this.selectedImage,
    required this.isAnalyzing,
    required this.onTap,
    required this.forest,
    required this.forestLight,
    required this.leaf,
    required this.cream,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAnalyzing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        height: selectedImage != null ? 260 : 160,
        decoration: BoxDecoration(
          color: selectedImage != null ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: selectedImage == null
              ? Border.all(
                  color: forest.withOpacity(0.15),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
          boxShadow: selectedImage != null
              ? [
                  BoxShadow(
                    color: forest.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.file(selectedImage!, fit: BoxFit.cover),

                  // Gradient overlay
                  Positioned(
                    left: 0, right: 0, bottom: 0, height: 90,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Change image pill
                  Positioned(
                    bottom: 14, right: 14,
                    child: GestureDetector(
                      onTap: isAnalyzing ? null : onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 6),
                            const Text(
                              'Change',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Selected label top-left
                  Positioned(
                    top: 14, left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: forest.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: leaf, size: 13),
                          const SizedBox(width: 6),
                          const Text(
                            'Image Selected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: forest.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: forest.withOpacity(0.6),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Capture or Select Tyre Image',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: forest,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tap to open camera or gallery',
                    style: TextStyle(
                      fontSize: 12,
                      color: muted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Analyze button
// ─────────────────────────────────────────────────────────────
class _AnalyzeButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color forest, forestMid, leaf;

  const _AnalyzeButton({
    required this.onTap,
    required this.forest,
    required this.forestMid,
    required this.leaf,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [forest, forestMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: forest.withOpacity(0.38),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analyze Tyre Condition',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Georgia',
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Powered by YOLOv8 · AI',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: leaf,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tips card
// ─────────────────────────────────────────────────────────────
class _TipsCard extends StatelessWidget {
  final Color forest, forestLight, leaf, warmWhite;

  const _TipsCard({
    required this.forest,
    required this.forestLight,
    required this.leaf,
    required this.warmWhite,
  });

  static const _tips = [
    ('📸', 'Take a clear, well-lit photo of the tyre'),
    ('🎯', 'Focus on the tread area and sidewall'),
    ('📏', 'Capture from 1–2 metres distance'),
    ('🔍', 'Make sure damage areas are clearly visible'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: warmWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: forest.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: forest.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: forestLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tips_and_updates_rounded,
                    color: forestLight, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Tips for Best Results',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: forest,
                  fontFamily: 'Georgia',
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0x0F000000)),
          const SizedBox(height: 16),

          // Tips list
          ..._tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F1E7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(tip.$1,
                          style: const TextStyle(fontSize: 17)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF444444),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Image source bottom sheet
// ─────────────────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final Color forest, forestLight, leaf, cream;

  const _ImageSourceSheet({
    required this.onCamera,
    required this.onGallery,
    required this.forest,
    required this.forestLight,
    required this.leaf,
    required this.cream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: forest.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Select Image Source',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: forest,
              fontFamily: 'Georgia',
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you\'d like to add the tyre photo',
            style: TextStyle(
              fontSize: 13,
              color: forest.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              // Camera
              Expanded(
                child: GestureDetector(
                  onTap: onCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: forest,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: forest.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.camera_alt_rounded,
                            color: leaf, size: 30),
                        const SizedBox(height: 10),
                        const Text(
                          'Camera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Take a photo',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Gallery
              Expanded(
                child: GestureDetector(
                  onTap: onGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: forest.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.photo_library_rounded,
                            color: forestLight, size: 30),
                        const SizedBox(height: 10),
                        Text(
                          'Gallery',
                          style: TextStyle(
                            color: forest,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Choose a photo',
                          style: TextStyle(
                            color: forest.withOpacity(0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Analyzing overlay
// ─────────────────────────────────────────────────────────────
class _AnalyzingOverlay extends StatelessWidget {
  final String stage;
  final Color forest, leaf;

  const _AnalyzingOverlay({
    required this.stage,
    required this.forest,
    required this.leaf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF9F3),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: forest.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56, height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(forest),
                  backgroundColor: forest.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Analyzing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: forest,
                  fontFamily: 'Georgia',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stage,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF777777),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: forest.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: leaf, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'YOLOv8 · AI Processing',
                      style: TextStyle(
                        fontSize: 11,
                        color: forest.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color forest;

  const _SectionLabel({required this.label, required this.forest});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
              color: forest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: forest.withOpacity(0.5),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}