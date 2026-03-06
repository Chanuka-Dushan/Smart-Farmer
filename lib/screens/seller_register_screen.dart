import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../providers/auth_provider.dart';
import '../services/l10n_extension.dart';
import '../utils/error_handler.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const forest   = Color(0xFF1B4332);
  static const leaf     = Color(0xFF2D6A4F);
  static const sage     = Color(0xFF52B788);
  static const mint     = Color(0xFFB7E4C7);
  static const cream    = Color(0xFFF8F5F0);
  static const sand     = Color(0xFFEDE8DF);
  static const amber    = Color(0xFFFEF3C7);
  static const amberDark = Color(0xFF92400E);
  static const charcoal = Color(0xFF2C2C2C);
  static const slate    = Color(0xFF6B7280);
  static const error    = Color(0xFFDC2626);
}

InputDecoration _fieldDeco({
  required String label,
  String? hint,
  required IconData icon,
  String? helper,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperStyle: TextStyle(color: _C.slate.withOpacity(0.7), fontSize: 11),
    labelStyle: const TextStyle(
        color: _C.slate, fontSize: 13, fontWeight: FontWeight.w500),
    floatingLabelStyle: const TextStyle(
        color: _C.forest, fontSize: 13, fontWeight: FontWeight.w600),
    hintStyle: TextStyle(color: _C.slate.withOpacity(0.5), fontSize: 13),
    prefixIcon: Icon(icon, color: _C.sage, size: 20),
    suffixIcon: suffix,
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

// ─── Seller Register Screen ───────────────────────────────────────────────────
class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey                = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _firstnameController    = TextEditingController();
  final _lastnameController     = TextEditingController();
  final _emailController        = TextEditingController();
  final _passwordController     = TextEditingController();
  final _phoneController        = TextEditingController();

  bool _obscurePassword = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _businessNameController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.info_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: isError ? _C.error : _C.leaf,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                child: const Icon(Icons.block_rounded,
                    color: _C.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _C.charcoal),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has been restricted by an administrator for violating our terms of service or safety guidelines.',
                style: TextStyle(
                    fontSize: 14, color: _C.slate, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'If you believe this is a mistake, contact us at support@smartfarmer.com',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _C.charcoal),
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

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.registerSeller(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      businessName: _businessNameController.text.trim(),
      ownerFirstname: _firstnameController.text.trim(),
      ownerLastname: _lastnameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      _showSnack(
          'Seller account created! Complete your shop setup.',
          isError: false);
      Navigator.pushReplacementNamed(context, '/seller-onboarding');
    } else {
      _showSnack(auth.errorMessage ?? 'Registration failed');
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      String email = '', firstname = '', lastname = '', socialId = '';
      String? profilePic;

      if (provider == 'google') {
        final gs = GoogleSignIn(
          scopes: ['email'],
          serverClientId:
              '941688275134-rdm2qs0drvkceu69f0n8n71lth01h63b.apps.googleusercontent.com',
        );
        await gs.signOut();
        final user = await gs.signIn();
        if (user == null) return;

        email      = user.email;
        final np   = user.displayName?.split(' ') ?? ['User'];
        firstname  = np[0];
        lastname   = np.length > 1 ? np.sublist(1).join(' ') : '';
        socialId   = user.id;
        profilePic = user.photoUrl;
      } else {
        final res = await FacebookAuth.instance.login();
        if (res.status != LoginStatus.success) return;

        final ud   = await FacebookAuth.instance.getUserData();
        email      = ud['email'];
        final np   = (ud['name'] as String).split(' ');
        firstname  = np[0];
        lastname   = np.length > 1 ? np.sublist(1).join(' ') : '';
        socialId   = ud['id'];
        profilePic = ud['picture']['data']['url'];
      }

      final ok = await auth.socialLogin(
        provider: provider,
        idToken: socialId,
        email: email,
        name: '$firstname $lastname',
        photoUrl: profilePic,
        userType: 'seller',
        businessName: "$firstname's Shop",
      );

      if (!mounted) return;
      if (ok) {
        if (auth.seller != null && !auth.seller!.onboardingCompleted) {
          Navigator.pushReplacementNamed(context, '/seller-onboarding');
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      } else {
        if (auth.errorMessage?.toLowerCase().contains('banned') ?? false) {
          _showBannedDialog();
        } else {
          _showSnack(auth.errorMessage ?? 'Social login failed');
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().toLowerCase().contains('banned')) {
        _showBannedDialog();
      } else {
        _showSnack(ErrorHandler.getUserFriendlyMessage(e));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: Stack(
        children: [
          // Decorative blobs — warm amber tone to differentiate from farmer
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.amber.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.sage.withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Custom AppBar ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _C.sand, width: 1.5),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: _C.charcoal),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Seller badge — amber tint to differentiate
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _C.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.storefront_rounded,
                                size: 14, color: _C.amberDark),
                            SizedBox(width: 5),
                            Text(
                              'Seller Account',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.amberDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),

                              // ── Header ─────────────────────────────
                              const Text(
                                'Open your\nshop today',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: _C.charcoal,
                                  letterSpacing: -0.6,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sell farm equipment & supplies to thousands of farmers',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _C.slate.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── Social Buttons ─────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialBtn(
                                      icon: Icons.g_mobiledata_rounded,
                                      iconColor:
                                          const Color(0xFFEA4335),
                                      label: 'Google',
                                      onTap: () => _handleSocialLogin(
                                          'google'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SocialBtn(
                                      icon: Icons.facebook_rounded,
                                      iconColor:
                                          const Color(0xFF1877F2),
                                      label: 'Facebook',
                                      onTap: () => _handleSocialLogin(
                                          'facebook'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Divider ────────────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              _C.sand,
                                            ]),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    child: Text(
                                      'or fill in details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            _C.slate.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            colors: [
                                              _C.sand,
                                              Colors.transparent,
                                            ]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── Section: Business ──────────────────
                              _SectionLabel(
                                label: 'Business Info',
                                icon: Icons.storefront_outlined,
                                badgeColor: _C.amber,
                                badgeIconColor: _C.amberDark,
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _businessNameController,
                                style: _inputTextStyle,
                                decoration: _fieldDeco(
                                  label: 'Business / Shop Name',
                                  hint: 'e.g. Green Farm Supplies',
                                  icon: Icons.storefront_outlined,
                                ),
                                validator: (v) => (v == null ||
                                        v.isEmpty)
                                    ? 'Please enter your business name'
                                    : null,
                              ),
                              const SizedBox(height: 10),

                              // Info tip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _C.amber.withOpacity(0.45),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: _C.amber, width: 1.2),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: _C.amberDark),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'You can add your shop location & logo after registration',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _C.amberDark
                                              .withOpacity(0.85),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Section: Owner ─────────────────────
                              _SectionLabel(
                                label: 'Owner Details',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstnameController,
                                      style: _inputTextStyle,
                                      decoration: _fieldDeco(
                                        label: context.tr('first_name'),
                                        icon:
                                            Icons.person_outline_rounded,
                                      ),
                                      validator: (v) =>
                                          (v == null || v.isEmpty)
                                              ? context.tr(
                                                  'please_enter_first_name')
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastnameController,
                                      style: _inputTextStyle,
                                      decoration: _fieldDeco(
                                        label: context.tr('last_name'),
                                        icon:
                                            Icons.person_outline_rounded,
                                      ),
                                      validator: (v) =>
                                          (v == null || v.isEmpty)
                                              ? context.tr(
                                                  'please_enter_last_name')
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ── Section: Account ───────────────────
                              _SectionLabel(
                                label: 'Account Details',
                                icon: Icons.shield_outlined,
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _emailController,
                                keyboardType:
                                    TextInputType.emailAddress,
                                style: _inputTextStyle,
                                decoration: _fieldDeco(
                                  label: context.tr('email'),
                                  hint: 'you@example.com',
                                  icon: Icons.mail_outline_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return context
                                        .tr('please_enter_email');
                                  if (!v.contains('@'))
                                    return context.tr(
                                        'please_enter_valid_email');
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: _inputTextStyle,
                                decoration: _fieldDeco(
                                  label: context.tr('password'),
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  helper: context
                                      .tr('password_min_length'),
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _C.slate,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return context
                                        .tr('please_enter_password');
                                  if (v.length < 6)
                                    return context
                                        .tr('password_too_short');
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // ── Section: Contact (optional) ────────
                              _SectionLabel(
                                label: 'Contact',
                                icon: Icons.contacts_outlined,
                                isOptional: true,
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: _inputTextStyle,
                                decoration: _fieldDeco(
                                  label: context.tr('phone'),
                                  hint: '+1 234 567 8900',
                                  icon: Icons.phone_outlined,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── Register Button ────────────────────
                              Consumer<AuthProvider>(
                                builder: (_, auth, __) =>
                                    auth.isLoading
                                        ? _loadingBtn
                                        : SizedBox(
                                            height: 52,
                                            child: ElevatedButton(
                                              onPressed: _register,
                                              style: ElevatedButton
                                                  .styleFrom(
                                                backgroundColor:
                                                    _C.forest,
                                                foregroundColor:
                                                    Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                14)),
                                              ),
                                              child: const Text(
                                                'Register as Seller',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ),
                              ),
                              const SizedBox(height: 16),

                              // ── Sign in link ───────────────────────
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    context.tr('already_have_account') +
                                        ' ',
                                    style: TextStyle(
                                        fontSize: 13, color: _C.slate),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.pop(context),
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _C.forest,
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const _inputTextStyle = TextStyle(
  fontSize: 15,
  color: _C.charcoal,
  fontWeight: FontWeight.w500,
);

final _loadingBtn = Container(
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
          strokeWidth: 2.5, color: Colors.white),
    ),
  ),
);

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.icon,
    this.isOptional = false,
    this.badgeColor,
    this.badgeIconColor,
  });

  final String   label;
  final IconData icon;
  final bool     isOptional;
  final Color?   badgeColor;
  final Color?   badgeIconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: badgeColor ?? _C.forest,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon,
              color: badgeIconColor ?? Colors.white, size: 14),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _C.forest,
            letterSpacing: 0.2,
          ),
        ),
        if (isOptional) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _C.sand,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'optional',
              style: TextStyle(
                  fontSize: 10,
                  color: _C.slate,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.sage.withOpacity(0.35), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color    iconColor;
  final String   label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
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
              Icon(icon, color: iconColor, size: 24),
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