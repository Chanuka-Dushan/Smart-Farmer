import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../providers/auth_provider.dart';
import '../services/l10n_extension.dart';

// ─── Design Tokens (matches ProfileScreen) ───────────────────────────────────
class _C {
  static const forest   = Color(0xFF1B4332);
  static const leaf     = Color(0xFF2D6A4F);
  static const sage     = Color(0xFF52B788);
  static const mint     = Color(0xFFB7E4C7);
  static const cream    = Color(0xFFF8F5F0);
  static const sand     = Color(0xFFEDE8DF);
  static const charcoal = Color(0xFF2C2C2C);
  static const slate    = Color(0xFF6B7280);
  static const error    = Color(0xFFDC2626);
}

// ─── Shared field decorator ───────────────────────────────────────────────────
InputDecoration _fieldDeco({
  required String label,
  String? hint,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: _C.slate, fontSize: 13, fontWeight: FontWeight.w500),
    floatingLabelStyle: const TextStyle(color: _C.forest, fontSize: 13, fontWeight: FontWeight.w600),
    hintStyle: TextStyle(color: _C.slate.withOpacity(0.5), fontSize: 13),
    prefixIcon: Icon(icon, color: _C.sage, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _C.sand, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _C.sand, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.sage, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.error, width: 2),
    ),
  );
}

// ─── Register Role Picker Bottom Sheet ────────────────────────────────────────
void _showRegisterPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RegisterPickerSheet(),
  );
}

class _RegisterPickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: _C.sand,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Title
          const Text(
            'Join SmartFarmer',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _C.charcoal,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you want to register',
            style: TextStyle(fontSize: 14, color: _C.slate.withOpacity(0.8)),
          ),
          const SizedBox(height: 28),

          // Farmer card
          _RoleCard(
            icon: Icons.agriculture_rounded,
            title: 'Register as Farmer',
            subtitle: 'Buy seeds, tools & supplies\nfrom verified sellers',
            iconBg: _C.mint,
            iconColor: _C.forest,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
          ),
          const SizedBox(height: 14),

          // Seller card
          _RoleCard(
            icon: Icons.storefront_rounded,
            title: 'Register as Seller',
            subtitle: 'List your products & reach\nthousands of farmers',
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFF92400E),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/seller-register');
            },
          ),
          const SizedBox(height: 16),

          // Already have account link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: _C.slate, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    color: _C.forest,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.sand, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _C.slate.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: _C.slate),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Screen ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  AnimationController? _animCtrl;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  @override
  void initState() {
    super.initState();
    if (_animCtrl == null) {
      _animCtrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 700));
      _fadeAnim  = CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut);
      _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut));
      _animCtrl!.forward();
    }
  }

  @override
  void dispose() {
    _animCtrl?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.info_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? _C.error : _C.leaf,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigate(AuthProvider auth) {
    if (auth.isSeller &&
        auth.seller != null &&
        !auth.seller!.onboardingCompleted) {
      Navigator.pushReplacementNamed(context, '/seller-onboarding');
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok   = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      _navigate(auth);
    } else {
      if (auth.errorMessage?.toLowerCase().contains('banned') ?? false) {
        _showBannedDialog();
      } else {
        _showSnack(auth.errorMessage ?? context.l10n.tr('login_failed'));
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _showSnack('Connecting to $provider...', isError: false);

    try {
      String? email, firstName, lastName, socialId, profilePic;

      if (provider == 'google') {
        final gs = GoogleSignIn(
          scopes: ['email'],
          serverClientId:
              '941688275134-rdm2qs0drvkceu69f0n8n71lth01h63b.apps.googleusercontent.com',
        );
        await gs.signOut();
        final user = await gs.signIn();
        if (user == null) {
          _showSnack('Google Sign-In cancelled');
          return;
        }
        email     = user.email;
        final np  = user.displayName?.split(' ') ?? ['Social', 'User'];
        firstName = np.first;
        lastName  = np.length > 1 ? np.sublist(1).join(' ') : 'Google';
        socialId  = user.id;
        profilePic = user.photoUrl;
      } else {
        final res = await FacebookAuth.instance.login();
        if (res.status != LoginStatus.success) {
          throw Exception('Facebook login failed: ${res.message}');
        }
        final ud = await FacebookAuth.instance.getUserData();
        email     = ud['email'];
        firstName = ud['name']?.split(' ').first ?? 'Social';
        lastName  = ud['name']?.split(' ').last  ?? 'Facebook';
        socialId  = ud['id'];
        profilePic = ud['picture']?['data']?['url'];
      }

      final ok = await auth.socialLogin(
        provider: provider,
        idToken: socialId ?? "mock_id_${DateTime.now().millisecondsSinceEpoch}",
        email: email ?? "user_$provider@example.com",
        name: "${firstName ?? 'Social'} ${lastName ?? provider.toUpperCase()}",
        photoUrl: profilePic,
      );

      if (!mounted) return;
      if (ok) {
        _navigate(auth);
      } else {
        if (auth.errorMessage?.toLowerCase().contains('banned') ?? false) {
          _showBannedDialog();
        } else {
          _showSnack(auth.errorMessage ?? 'Social login failed');
        }
      }
    } catch (e) {
      debugPrint("Social login error: $e");
      if (!mounted) return;
      if (e.toString().toLowerCase().contains('banned')) {
        _showBannedDialog();
        return;
      }
      String msg = 'Login failed';
      final s = e.toString();
      if (s.contains('sign_in_canceled'))     msg = 'Sign-in cancelled';
      else if (s.contains('network_error'))   msg = 'Network error. Check your connection.';
      else if (s.contains('sign_in_failed'))  msg = 'Sign-in failed. Please try again.';
      else if (s.contains('PlatformException')) msg = 'Google Sign-In error. Check configuration.';
      else                                    msg = 'Login failed: $s';
      _showSnack(msg);
    }
  }

  void _showBannedDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.block_rounded, color: _C.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _C.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has been restricted by an administrator for violating our terms of service or safety guidelines.',
                style: TextStyle(fontSize: 14, color: _C.slate, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'If you believe this is a mistake, contact us at support@smartfarmer.com',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _C.charcoal),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.forest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('I Understand',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: Stack(
        children: [
          // Top gradient blob
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.sage.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.mint.withOpacity(0.25),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
                child: SlideTransition(
                  position: _slideAnim ?? const AlwaysStoppedAnimation(Offset.zero),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),

                        // ── Logo + Title ─────────────────────────────────
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_C.leaf, _C.sage],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.sage.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.agriculture_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _C.charcoal,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to SmartFarmer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _C.slate.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Email ────────────────────────────────────────
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              fontSize: 15,
                              color: _C.charcoal,
                              fontWeight: FontWeight.w500),
                          decoration: _fieldDeco(
                            label: context.tr('email'),
                            hint: 'you@example.com',
                            icon: Icons.mail_outline_rounded,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return context.tr('please_enter_email');
                            if (!v.contains('@'))
                              return context.tr('please_enter_valid_email');
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Password ─────────────────────────────────────
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                              fontSize: 15,
                              color: _C.charcoal,
                              fontWeight: FontWeight.w500),
                          decoration: _fieldDeco(
                            label: context.tr('password'),
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _C.slate,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? context.tr('please_enter_password')
                              : null,
                        ),

                        // ── Forgot password ──────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: _C.forest,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            ),
                            child: Text(
                              context.tr('forgot_password'),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // ── Login Button ─────────────────────────────────
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => auth.isLoading
                              ? Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _C.forest,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _C.forest,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                    child: Text(
                                      context.tr('login'),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 28),

                        // ── Divider ──────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.transparent,
                                    _C.sand,
                                  ]),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                context.tr('or_continue_with'),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _C.slate.withOpacity(0.7),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    _C.sand,
                                    Colors.transparent,
                                  ]),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Social Buttons ───────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _SocialBtn(
                                iconPath: Icons.g_mobiledata_rounded,
                                iconColor: const Color(0xFFEA4335),
                                label: 'Google',
                                onTap: () => _handleSocialLogin('google'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SocialBtn(
                                iconPath: Icons.facebook_rounded,
                                iconColor: const Color(0xFF1877F2),
                                label: 'Facebook',
                                onTap: () => _handleSocialLogin('facebook'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Register prompt ──────────────────────────────
                        GestureDetector(
                          onTap: () => _showRegisterPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: _C.sand, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _C.mint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person_add_rounded,
                                      color: _C.forest, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                      fontSize: 14, color: _C.slate),
                                ),
                                const Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _C.forest,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 12, color: _C.forest),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
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

// ─── Social Button ────────────────────────────────────────────────────────────
class _SocialBtn extends StatelessWidget {
  const _SocialBtn({
    required this.iconPath,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData iconPath;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _C.sand, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconPath, color: iconColor, size: 26),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _C.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Forgot Password Screen ───────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      appBar: AppBar(
        backgroundColor: _C.cream,
        elevation: 0,
        foregroundColor: _C.charcoal,
        title: Text(
          context.tr('forgot_password'),
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _C.charcoal),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isSent ? _buildResetForm() : _buildEmailForm(),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Illustration
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.mint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.mail_lock_outlined,
                color: _C.forest, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Forgot your password?',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _C.charcoal,
              letterSpacing: -0.3),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('enter_email_to_reset'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: _C.slate.withOpacity(0.8)),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
                fontSize: 15,
                color: _C.charcoal,
                fontWeight: FontWeight.w500),
            decoration: _fieldDeco(
                label: context.tr('email'),
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded),
            validator: (v) => (v == null || v.isEmpty)
                ? context.tr('please_enter_email')
                : null,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final ok = await Provider.of<AuthProvider>(context,
                        listen: false)
                    .forgotPassword(_emailController.text.trim());
                if (!mounted) return;
                if (ok) {
                  setState(() => _isSent = true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(context.l10n.tr('failed_to_send_reset')),
                    backgroundColor: _C.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.forest,
              foregroundColor: Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              context.tr('send_reset_token'),
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    final tokenCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();
    final resetKey     = GlobalKey<FormState>();

    return Form(
      key: resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _C.mint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: _C.forest, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('reset_token_sent'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _C.charcoal,
                letterSpacing: -0.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your inbox and enter the reset token below.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: _C.slate.withOpacity(0.8), height: 1.4),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: tokenCtrl,
            style: const TextStyle(
                fontSize: 15, color: _C.charcoal, fontWeight: FontWeight.w500),
            decoration: _fieldDeco(
              label: context.tr('enter_token'),
              icon: Icons.vpn_key_outlined,
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter token' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: passwordCtrl,
            obscureText: true,
            style: const TextStyle(
                fontSize: 15, color: _C.charcoal, fontWeight: FontWeight.w500),
            decoration: _fieldDeco(
              label: context.tr('new_password'),
              icon: Icons.lock_reset_outlined,
            ),
            validator: (v) =>
                (v == null || v!.length < 6) ? 'Password too short' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                if (resetKey.currentState!.validate()) {
                  final ok = await Provider.of<AuthProvider>(context,
                          listen: false)
                      .resetPassword(tokenCtrl.text, passwordCtrl.text);
                  if (!mounted) return;
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l10n.tr('password_reset_success')),
                      backgroundColor: _C.leaf,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l10n.tr('invalid_token')),
                      backgroundColor: _C.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.forest,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                context.tr('reset_password'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}