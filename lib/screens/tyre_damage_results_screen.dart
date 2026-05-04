import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';

class TyreDamageResultsScreen extends StatefulWidget {
  final Map<String, dynamic> detectionResult;
  final File originalImage;

  const TyreDamageResultsScreen({
    super.key,
    required this.detectionResult,
    required this.originalImage,
  });

  @override
  State<TyreDamageResultsScreen> createState() =>
      _TyreDamageResultsScreenState();
}

class _TyreDamageResultsScreenState extends State<TyreDamageResultsScreen>
    with TickerProviderStateMixin {
  // Default to annotated image first (as requested)
  bool _showingAnnotated = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Tyre life prediction
  Map<String, dynamic>? _lifePredictor;
  bool _predictionLoading = true;
  String? _predictionError;

  final ApiService _api = ApiService();

  // ── Design tokens ──────────────────────────────────────────
  static const _forest = Color(0xFF0F3D1F);
  static const _forestMid = Color(0xFF1B5E30);
  static const _forestLight = Color(0xFF2E7D4F);
  static const _leaf = Color(0xFF4CAF71);
  static const _cream = Color(0xFFF7F2E8);
  static const _warmWhite = Color(0xFFFDFAF5);
  static const _charcoal = Color(0xFF1C1C1C);
  static const _muted = Color(0xFF9E9E9E);
  static const _alertOrange = Color(0xFFE8621A);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
    
    // Predict tyre life
    _predictTyreLife();
  }

  Future<void> _predictTyreLife() async {
    try {
      final primaryDamage =
          widget.detectionResult['primary_damage'] as Map<String, dynamic>?;
      
      if (primaryDamage == null) {
        setState(() {
          _lifePredictor = {
            'remaining_life_months': 30,
            'status': 'Healthy',
          };
          _predictionLoading = false;
        });
        return;
      }

      final prediction = await _api.predictTyreLife(
        damageType: primaryDamage['damage_type'] ?? 'unknown',
        damageSeverity: primaryDamage['severity'] ?? 'unknown',
        lifespanReduction: primaryDamage['lifespan_reduction'] ?? 0.0,
        usageHoursPerWeek: 40.0,
        monthsUsed: 12.0,
        confidence: primaryDamage['confidence'] ?? 0.8,
      );

      if (!mounted) return;
      setState(() {
        _lifePredictor = prediction;
        _predictionLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _predictionError = e.toString();
        _predictionLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleImage() {
    _fadeController.reset();
    setState(() => _showingAnnotated = !_showingAnnotated);
    _fadeController.forward();
  }

  // ── Helpers ────────────────────────────────────────────────
  String _formatDamageType(String type) {
    final formatted = type.replaceAll('_', ' ');
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  String _formatSeverity(String severity) =>
      severity[0].toUpperCase() + severity.substring(1).toLowerCase();

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F2F);
      case 'severe':
        return const Color(0xFFE64A19);
      case 'moderate':
        return const Color(0xFFF57C00);
      case 'minor':
        return const Color(0xFFFBC02D);
      case 'good':
        return const Color(0xFF388E3C);
      default:
        return _muted;
    }
  }

  Color _severityBg(String severity) =>
      _severityColor(severity).withOpacity(0.12);

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final detections =
        widget.detectionResult['detections'] as List? ?? [];
    final primaryDamage =
        widget.detectionResult['primary_damage'] as Map<String, dynamic>?;
    final model =
        widget.detectionResult['model'] as String? ?? 'Unknown';
    final detectionsCount =
        widget.detectionResult['detections_count'] as int? ?? 0;
    final annotatedBase64 =
        widget.detectionResult['annotated_image_base64'] as String?;
    final hasAnnotated =
        annotatedBase64 != null && annotatedBase64.isNotEmpty;

    return Scaffold(
      backgroundColor: _cream,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sliver App Bar with image ──────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: _forest,
            foregroundColor: Colors.white,
            title: const Text(
              'Detection Results',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              if (hasAnnotated)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ImageToggleButton(
                    showingAnnotated: _showingAnnotated,
                    onTap: _toggleImage,
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: _ImageHero(
                showingAnnotated: _showingAnnotated && hasAnnotated,
                annotatedBase64: annotatedBase64,
                originalImage: widget.originalImage,
                fadeAnim: _fadeAnim,
                hasAnnotated: hasAnnotated,
              ),
            ),
          ),

          // ── Body content ──────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: CurvedAnimation(
                    parent: _slideController, curve: Curves.easeIn),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Status banner
                    _StatusBanner(
                      detectionsCount: detectionsCount,
                      leaf: _leaf,
                      alertOrange: _alertOrange,
                      forest: _forest,
                    ),

                    const SizedBox(height: 20),

                    // Primary damage card
                    if (primaryDamage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _PrimaryDamageCard(
                          primaryDamage: primaryDamage,
                          forest: _forest,
                          forestLight: _forestLight,
                          leaf: _leaf,
                          charcoal: _charcoal,
                          muted: _muted,
                          warmWhite: _warmWhite,
                          formatDamageType: _formatDamageType,
                          formatSeverity: _formatSeverity,
                          severityColor: _severityColor,
                          severityBg: _severityBg,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tyre Life Prediction Card
                      if (_predictionLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _leaf.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _leaf.withOpacity(0.3)),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      else if (_predictionError == null && _lifePredictor != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _LifePredictionCard(
                            prediction: _lifePredictor!,
                            forest: _forest,
                            leaf: _leaf,
                            charcoal: _charcoal,
                            warmWhite: _warmWhite,
                            muted: _muted,
                          ),
                        ),
                    ],

                    // All detections
                    if (detectionsCount > 1) ...[
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _AllDetectionsSection(
                          detections: detections,
                          forest: _forest,
                          charcoal: _charcoal,
                          muted: _muted,
                          warmWhite: _warmWhite,
                          formatDamageType: _formatDamageType,
                          formatSeverity: _formatSeverity,
                          severityColor: _severityColor,
                          severityBg: _severityBg,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Model info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ModelBadge(model: model, muted: _muted),
                    ),

                    const SizedBox(height: 32),
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _ImageToggleButton extends StatelessWidget {
  final bool showingAnnotated;
  final VoidCallback onTap;

  const _ImageToggleButton({
    required this.showingAnnotated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: showingAnnotated
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showingAnnotated ? Icons.auto_awesome : Icons.image_outlined,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              showingAnnotated ? 'Annotated' : 'Original',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageHero extends StatelessWidget {
  final bool showingAnnotated;
  final String? annotatedBase64;
  final File originalImage;
  final Animation<double> fadeAnim;
  final bool hasAnnotated;

  const _ImageHero({
    required this.showingAnnotated,
    required this.annotatedBase64,
    required this.originalImage,
    required this.fadeAnim,
    required this.hasAnnotated,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        FadeTransition(
          opacity: fadeAnim,
          child: showingAnnotated && annotatedBase64 != null
              ? Image.memory(
                  base64Decode(annotatedBase64!),
                  fit: BoxFit.cover,
                )
              : Image.file(
                  originalImage,
                  fit: BoxFit.cover,
                ),
        ),

        // Gradient overlay bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0F3D1F).withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),

        // Toggle hint pill at bottom
        if (hasAnnotated)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      showingAnnotated
                          ? 'Tap ↗ to see original'
                          : 'Tap ↗ to see annotated',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final int detectionsCount;
  final Color leaf, alertOrange, forest;

  const _StatusBanner({
    required this.detectionsCount,
    required this.leaf,
    required this.alertOrange,
    required this.forest,
  });

  @override
  Widget build(BuildContext context) {
    final noIssue = detectionsCount == 0;
    final color = noIssue ? leaf : alertOrange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                noIssue ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noIssue ? 'Tyre is Healthy' : '$detectionsCount Issue(s) Detected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: noIssue ? const Color(0xFF1B5E30) : const Color(0xFF7C2D00),
                      letterSpacing: -0.3,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    noIssue
                        ? 'No damage found in this scan'
                        : 'Review the damage details below',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryDamageCard extends StatelessWidget {
  final Map<String, dynamic> primaryDamage;
  final Color forest, forestLight, leaf, charcoal, muted, warmWhite;
  final String Function(String) formatDamageType;
  final String Function(String) formatSeverity;
  final Color Function(String) severityColor;
  final Color Function(String) severityBg;

  const _PrimaryDamageCard({
    required this.primaryDamage,
    required this.forest,
    required this.forestLight,
    required this.leaf,
    required this.charcoal,
    required this.muted,
    required this.warmWhite,
    required this.formatDamageType,
    required this.formatSeverity,
    required this.severityColor,
    required this.severityBg,
  });

  @override
  Widget build(BuildContext context) {
    final damageType =
        formatDamageType(primaryDamage['damage_type'] as String? ?? 'Unknown');
    final confidence =
        (primaryDamage['confidence'] as num? ?? 0) * 100;
    final severity = primaryDamage['severity'] as String? ?? 'unknown';
    final lifespanReduction =
        ((primaryDamage['lifespan_reduction'] as num? ?? 0) * 100).toStringAsFixed(0);

    final sColor = severityColor(severity);

    return Container(
      decoration: BoxDecoration(
        color: warmWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: forest.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: forest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.radar_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Primary Damage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Georgia',
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                // Severity chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sColor.withOpacity(0.5), width: 1),
                  ),
                  child: Text(
                    formatSeverity(severity),
                    style: TextStyle(
                      color: sColor == const Color(0xFFFBC02D)
                          ? const Color(0xFF7A5C00)
                          : sColor.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats grid
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.category_outlined,
                        label: 'Damage Type',
                        value: damageType,
                        iconColor: forestLight,
                        bgColor: forestLight.withOpacity(0.08),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.verified_outlined,
                        label: 'Confidence',
                        value: '${confidence.toStringAsFixed(1)}%',
                        iconColor: const Color(0xFF1565C0),
                        bgColor: const Color(0xFF1565C0).withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.emergency_outlined,
                        label: 'Severity',
                        value: formatSeverity(severity),
                        iconColor: sColor,
                        bgColor: sColor.withOpacity(0.08),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.trending_down_rounded,
                        label: 'Lifespan Impact',
                        value: '-$lifespanReduction%',
                        iconColor: const Color(0xFFB71C1C),
                        bgColor: const Color(0xFFB71C1C).withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1C),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllDetectionsSection extends StatelessWidget {
  final List detections;
  final Color forest, charcoal, muted, warmWhite;
  final String Function(String) formatDamageType;
  final String Function(String) formatSeverity;
  final Color Function(String) severityColor;
  final Color Function(String) severityBg;

  const _AllDetectionsSection({
    required this.detections,
    required this.forest,
    required this.charcoal,
    required this.muted,
    required this.warmWhite,
    required this.formatDamageType,
    required this.formatSeverity,
    required this.severityColor,
    required this.severityBg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: forest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'All Detections',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: charcoal,
                  fontFamily: 'Georgia',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: forest.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${detections.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: forest,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...detections.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value as Map<String, dynamic>;
          final severity = d['severity'] as String? ?? 'unknown';
          final sColor = severityColor(severity);
          final confidence =
              ((d['confidence'] as num? ?? 0) * 100).toStringAsFixed(1);

          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + i * 60),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: warmWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: sColor.withOpacity(0.15), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tire_repair_rounded,
                      color: sColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDamageType(
                            d['damage_type'] as String? ?? 'Unknown'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: charcoal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$confidence% confidence',
                        style: TextStyle(
                          fontSize: 12,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    formatSeverity(severity),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _ModelBadge extends StatelessWidget {
  final String model;
  final Color muted;

  const _ModelBadge({required this.model, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: muted.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.memory_rounded, size: 16, color: muted),
          const SizedBox(width: 8),
          Text(
            'Model: $model',
            style: TextStyle(
              fontSize: 12,
              color: muted,
              fontFamily: 'Courier',
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifePredictionCard extends StatelessWidget {
  final Map<String, dynamic> prediction;
  final Color forest, leaf, charcoal, warmWhite, muted;

  const _LifePredictionCard({
    required this.prediction,
    required this.forest,
    required this.leaf,
    required this.charcoal,
    required this.warmWhite,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final prediction_data = prediction['prediction'] as Map<String, dynamic>? ?? {};
    final remainingLifeValue = prediction_data['remaining_life_months'];
    final status = prediction_data['status'] ?? 'Unknown';
    final recommendations = prediction_data['recommendations'] as List? ?? [];

    String remainingLifeText;
    if (remainingLifeValue is num) {
      remainingLifeText = '${remainingLifeValue.round()} months';
    } else if (remainingLifeValue != null) {
      final valueText = remainingLifeValue.toString().trim();
      remainingLifeText = valueText.toLowerCase().contains('month')
          ? valueText
          : '$valueText months';
    } else {
      remainingLifeText = 'Unknown';
    }

    final isHealthy = status.toString().toLowerCase().contains('good') ||
        status.toString().toLowerCase().contains('healthy');
    final statusColor = isHealthy ? leaf : const Color(0xFFE64A19);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHealthy ? Icons.schedule : Icons.warning_amber_rounded,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tyre Health Prediction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: forest,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Life prediction
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: warmWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: forest.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining Life',
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remainingLifeText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: forest,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: leaf.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_bottom, color: leaf, size: 28),
                ),
              ],
            ),
          ),

          // Recommendations
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: forest,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 8),
            ...recommendations.take(3).map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: leaf,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rec.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: charcoal.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}