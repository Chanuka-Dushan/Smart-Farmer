import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/l10n_extension.dart';
import '../providers/auth_provider.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const forest   = Color(0xFF1B4332);
  static const leaf     = Color(0xFF2D6A4F);
  static const sage     = Color(0xFF52B788);
  static const mint     = Color(0xFFB7E4C7);
  static const cream    = Color(0xFFF8F5F0);
  static const charcoal = Color(0xFF2C2C2C);
  static const slate    = Color(0xFF6B7280);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Logo scale + fade
  late AnimationController _logoCtrl;
  late Animation<double>   _logoScale;
  late Animation<double>   _logoFade;

  // Text slide up + fade
  late AnimationController _textCtrl;
  late Animation<double>   _textFade;
  late Animation<Offset>   _textSlide;

  // Spinner fade in
  late AnimationController _spinnerCtrl;
  late Animation<double>   _spinnerFade;

  // Rotating outer ring
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();

    // Logo bounces in
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    // Text slides up after logo
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _textFade  = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Spinner fades in last
    _spinnerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _spinnerFade = CurvedAnimation(parent: _spinnerCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    // Continuously rotating decorative ring
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    // Staggered sequence
    _logoCtrl.forward().then((_) {
      _textCtrl.forward().then((_) {
        _spinnerCtrl.forward();
      });
    });

    _checkLanguageSelection();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _spinnerCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  // ── Navigation logic (unchanged) ───────────────────────────────────────────

  Future<void> _checkLanguageSelection() async {
    try {
      await Future.delayed(const Duration(seconds: 3));

      final prefs = await SharedPreferences.getInstance();
      final languageSelected = prefs.getBool('language_selected') ?? false;

      if (!mounted) return;
      debugPrint('Language selected: $languageSelected');

      if (!languageSelected) {
        Navigator.pushReplacementNamed(context, '/language');
        return;
      }

      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
      debugPrint('Onboarding completed: $onboardingCompleted');

      if (!onboardingCompleted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }

      debugPrint('Checking auth status...');
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);

      try {
        await authProvider.checkAuthStatus();
        debugPrint(
            'Auth check complete. Authenticated: ${authProvider.isAuthenticated}');
      } catch (e) {
        debugPrint('Error checking auth status: $e');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        if (authProvider.isSeller &&
            authProvider.seller != null &&
            !authProvider.seller!.onboardingCompleted) {
          Navigator.pushReplacementNamed(context, '/seller-onboarding');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Error in splash screen: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.forest,
      body: Stack(
        children: [

          // ── Background decorative circles ──────────────────────────
          Positioned(
            top: -size.width * 0.35,
            left: -size.width * 0.25,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.leaf.withOpacity(0.6),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.4,
            right: -size.width * 0.3,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.leaf.withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.25,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.35,
              height: size.width * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.sage.withOpacity(0.12),
              ),
            ),
          ),

          // ── Rotating dashed ring behind logo ───────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) {
                return Transform.rotate(
                  angle: _ringCtrl.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(170, 170),
                    painter: _DashedCirclePainter(
                      color: _C.sage.withOpacity(0.25),
                      dashCount: 24,
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Main content ───────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Logo tile
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App name + subtitle
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          context.tr('app_name'),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            context.tr('app_subtitle'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom loader + version ────────────────────────────────
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _spinnerFade,
              child: Column(
                children: [
                  // Thin progress bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 80),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor:
                            Colors.white.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _C.sage.withOpacity(0.8),
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.45),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Powered-by tag (top right) ─────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: FadeTransition(
              opacity: _textFade,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _C.sage,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SmartFarmer',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
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

// ─── Dashed Circle Painter ────────────────────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({
    required this.color,
    required this.dashCount,
  });

  final Color color;
  final int   dashCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dashAngle = (2 * math.pi) / dashCount;
    final gapFraction = 0.45;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}