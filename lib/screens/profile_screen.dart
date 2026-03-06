import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../services/l10n_extension.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const forest      = Color(0xFF1B4332);
  static const leaf        = Color(0xFF2D6A4F);
  static const sage        = Color(0xFF52B788);
  static const mint        = Color(0xFFB7E4C7);
  static const cream       = Color(0xFFF8F5F0);
  static const sand        = Color(0xFFEDE8DF);
  static const bark        = Color(0xFF8B6F47);
  static const charcoal    = Color(0xFF2C2C2C);
  static const slate       = Color(0xFF6B7280);
  static const error       = Color(0xFFDC2626);
  static const errorLight  = Color(0xFFFEF2F2);
  static const successBg   = Color(0xFFECFDF5);
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _AppColors.forest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _AppColors.forest,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_AppColors.sage.withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: _AppColors.charcoal,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: _AppColors.slate.withOpacity(0.6), fontSize: 13),
        labelStyle: const TextStyle(
          color: _AppColors.slate,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: _AppColors.forest,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: _AppColors.sage, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _AppColors.sand, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _AppColors.sand, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AppColors.sage, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AppColors.error, width: 2),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppColors.forest,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _AppColors.forest.withOpacity(0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AppColors.forest,
          side: const BorderSide(color: _AppColors.sage, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationNameController;

  Position? _currentPosition;
  bool _isLoadingLocation = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isSeller) {
      final seller = authProvider.seller;
      _firstnameController    = TextEditingController(text: seller?.ownerFirstname ?? '');
      _lastnameController     = TextEditingController(text: seller?.ownerLastname ?? '');
      _phoneController        = TextEditingController(text: seller?.phoneNumber ?? '');
      _addressController      = TextEditingController(text: seller?.businessAddress ?? '');
      _businessNameController = TextEditingController(text: seller?.businessName ?? '');
      _descriptionController  = TextEditingController(text: seller?.businessDescription ?? '');
      _locationNameController = TextEditingController(text: seller?.shopLocationName ?? '');

      if (seller?.latitude != null && seller?.longitude != null) {
        try {
          _currentPosition = Position(
            latitude: double.parse(seller!.latitude!),
            longitude: double.parse(seller.longitude!),
            timestamp: DateTime.now(),
            accuracy: 0, altitude: 0, heading: 0,
            speed: 0, speedAccuracy: 0,
            altitudeAccuracy: 0, headingAccuracy: 0,
          );
        } catch (_) {
          _currentPosition = null;
        }
      }
    } else {
      final user = authProvider.user;
      _firstnameController    = TextEditingController(text: user?.firstname ?? '');
      _lastnameController     = TextEditingController(text: user?.lastname ?? '');
      _phoneController        = TextEditingController(text: user?.phoneNumber ?? '');
      _addressController      = TextEditingController(text: user?.address ?? '');
      _businessNameController = TextEditingController();
      _descriptionController  = TextEditingController();
      _locationNameController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentPicUrl = authProvider.isSeller
        ? authProvider.seller?.logoUrl
        : authProvider.user?.profilePictureUrl;

    if (currentPicUrl != null && currentPicUrl.isNotEmpty) {
      try { NetworkImage(currentPicUrl).evict(); } catch (_) {}
    }

    final success = await authProvider.uploadProfilePicture(image.path);
    if (!mounted) return;

    _showSnack(
      success
          ? context.tr('profile_picture_updated')
          : (authProvider.errorMessage ?? context.tr('upload_failed')),
      success: success,
    );
    if (success) setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showSnack(context.tr('location_services_disabled'));
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack(context.tr('location_permissions_denied'));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack(context.tr('location_permissions_permanently_denied'));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = pos);
      _showSnack(context.tr('location_updated'), success: true);
    } catch (e) {
      _showSnack('Failed to get location: $e', success: false);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _updateLocation() async {
    if (_currentPosition == null) {
      _showSnack(context.tr('please_get_location_first'));
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateSellerLocation(
      latitude: _currentPosition!.latitude.toString(),
      longitude: _currentPosition!.longitude.toString(),
      shopLocationName: _locationNameController.text.trim().isEmpty
          ? null
          : _locationNameController.text.trim(),
    );
    if (!mounted) return;
    _showSnack(
      success
          ? context.tr('location_updated_successfully')
          : (authProvider.errorMessage ?? context.tr('location_update_failed')),
      success: success,
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (authProvider.isSeller) {
      success = await authProvider.updateSellerProfile(
        businessName: _businessNameController.text.trim(),
        ownerFirstname: _firstnameController.text.trim(),
        ownerLastname: _lastnameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        businessAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        businessDescription: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );
    } else {
      success = await authProvider.updateProfile(
        firstname: _firstnameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );
    }

    if (!mounted) return;
    _showSnack(
      success
          ? context.l10n.tr('profile_updated')
          : (authProvider.errorMessage ?? context.l10n.tr('update_failed')),
      success: success,
    );
  }

  void _showSnack(String message, {bool? success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success == true ? Icons.check_circle_outline : Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success == true
            ? _AppColors.leaf
            : success == false
                ? _AppColors.error
                : _AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _showChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final fKey    = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (dCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _AppColors.mint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_outline, color: _AppColors.forest, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('change_password'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.charcoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: fKey,
                child: Column(
                  children: [
                    _StyledField(
                      controller: oldCtrl,
                      label: context.tr('old_password'),
                      icon: Icons.lock_outline,
                      validator: (v) => (v == null || v.isEmpty)
                          ? context.tr('please_enter_old_password')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _StyledField(
                      controller: newCtrl,
                      label: context.tr('new_password'),
                      icon: Icons.lock_reset_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return context.tr('please_enter_new_password');
                        if (v.length < 6) return context.tr('password_too_short');
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dCtx),
                      style: TextButton.styleFrom(
                        foregroundColor: _AppColors.slate,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.tr('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!fKey.currentState!.validate()) return;
                        Navigator.pop(dCtx);
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final ok = await auth.changePassword(
                          oldPassword: oldCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (!mounted) return;
                        _showSnack(
                          ok
                              ? context.l10n.tr('password_changed')
                              : (auth.errorMessage ?? context.l10n.tr('password_change_failed')),
                          success: ok,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.forest,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.tr('change')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    return showDialog(
      context: context,
      builder: (dCtx) => Dialog(
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
                  color: _AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: _AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('delete_account'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('delete_account_confirmation'),
                style: const TextStyle(fontSize: 14, color: _AppColors.slate, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dCtx),
                      style: TextButton.styleFrom(
                        foregroundColor: _AppColors.slate,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.tr('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dCtx);
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final ok = await auth.deleteAccount();
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                        } else {
                          _showSnack(auth.errorMessage ?? context.l10n.tr('delete_failed'),
                              success: false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.tr('delete')),
                    ),
                  ),
                ],
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
      backgroundColor: _AppColors.cream,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final isSeller = authProvider.isSeller;
          final user   = authProvider.user;
          final seller = authProvider.seller;

          if ((!isSeller && user == null) || (isSeller && seller == null)) {
            return const Scaffold(
              backgroundColor: _AppColors.cream,
              body: Center(
                child: CircularProgressIndicator(color: _AppColors.sage),
              ),
            );
          }

          final displayName = isSeller ? seller!.businessName : user!.fullName;
          final email       = isSeller ? seller!.email : user!.email;
          final picUrl      = isSeller ? seller!.logoUrl : user!.profilePictureUrl;
          final initials    = isSeller
              ? (seller!.businessName.isNotEmpty
                  ? seller.businessName.substring(0, 1).toUpperCase()
                  : 'S')
              : ((user!.firstname.isNotEmpty ? user.firstname[0] : '') +
                      (user.lastname.isNotEmpty ? user.lastname[0] : ''))
                  .toUpperCase();

          return CustomScrollView(
            slivers: [
              // ── Hero AppBar ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: _AppColors.forest,
                elevation: 0,
                leading: const SizedBox.shrink(),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                      ),
                      onPressed: () async {
                        await authProvider.logout();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_AppColors.forest, _AppColors.leaf, _AppColors.sage],
                          ),
                        ),
                      ),
                      // Decorative circles
                      Positioned(
                        top: -40, right: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20, left: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Profile content
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Avatar
                            Stack(
                              children: [
                                Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: _AppColors.mint,
                                    child: picUrl != null && picUrl.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              picUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              headers: const {'Cache-Control': 'no-cache'},
                                              errorBuilder: (_, __, ___) => Text(
                                                initials,
                                                style: const TextStyle(
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w700,
                                                  color: _AppColors.forest,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            initials,
                                            style: const TextStyle(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w700,
                                              color: _AppColors.forest,
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded,
                                          color: _AppColors.forest, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.75),
                                letterSpacing: 0.1,
                              ),
                            ),
                            if (picUrl != null && picUrl.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => authProvider.deleteProfilePicture(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    context.tr('remove_picture'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Form Body ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Business Info (Seller only) ──────────────────
                          if (isSeller) ...[
                            _SectionHeader(
                              label: context.tr('business_info'),
                              icon: Icons.storefront_outlined,
                            ),
                            _StyledField(
                              controller: _businessNameController,
                              label: context.tr('business_name'),
                              icon: Icons.storefront_outlined,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? context.tr('please_enter_business_name')
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _StyledField(
                              controller: _descriptionController,
                              label: context.tr('business_description'),
                              icon: Icons.description_outlined,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 28),
                          ],

                          // ── Personal Info ─────────────────────────────────
                          _SectionHeader(
                            label: isSeller
                                ? context.tr('owner_info')
                                : context.tr('personal_info'),
                            icon: Icons.person_outline_rounded,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _StyledField(
                                  controller: _firstnameController,
                                  label: isSeller
                                      ? context.tr('owner_first_name')
                                      : context.tr('first_name'),
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? context.tr('please_enter_first_name')
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StyledField(
                                  controller: _lastnameController,
                                  label: isSeller
                                      ? context.tr('owner_last_name')
                                      : context.tr('last_name'),
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? context.tr('please_enter_last_name')
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _StyledField(
                            controller: _phoneController,
                            label: context.tr('phone'),
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _StyledField(
                            controller: _addressController,
                            label: isSeller
                                ? context.tr('business_address')
                                : context.tr('address'),
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 28),

                          // ── Shop Location (Seller only) ───────────────────
                          if (isSeller) ...[
                            _SectionHeader(
                              label: context.tr('shop_location'),
                              icon: Icons.map_outlined,
                            ),

                            if (_currentPosition != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: _AppColors.successBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _AppColors.sage.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _AppColors.mint,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.location_on,
                                          color: _AppColors.forest, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr('current_location_coordinates'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _AppColors.forest,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_currentPosition!.latitude.toStringAsFixed(5)}, '
                                          '${_currentPosition!.longitude.toStringAsFixed(5)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _AppColors.slate,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            _StyledField(
                              controller: _locationNameController,
                              label: context.tr('shop_location_name'),
                              hint: 'e.g. Downtown Shop, Main Street Store',
                              icon: Icons.place_outlined,
                            ),
                            const SizedBox(height: 16),

                            _OutlineButton(
                              label: _currentPosition == null
                                  ? context.tr('get_current_location')
                                  : context.tr('update_current_location'),
                              icon: _isLoadingLocation ? null : Icons.my_location_outlined,
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                            ),
                            if (_isLoadingLocation) ...[
                              const SizedBox(height: 12),
                              const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _AppColors.sage,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _PrimaryButton(
                              label: context.tr('save_location'),
                              icon: Icons.save_alt_outlined,
                              onPressed: _currentPosition == null ? null : _updateLocation,
                            ),
                            const SizedBox(height: 28),
                          ],

                          // ── Update Profile Button ─────────────────────────
                          authProvider.isLoading
                              ? Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _AppColors.forest,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : _PrimaryButton(
                                  label: context.tr('update_profile'),
                                  icon: Icons.check_rounded,
                                  onPressed: _updateProfile,
                                ),
                          const SizedBox(height: 12),

                          // ── Change Password ───────────────────────────────
                          _OutlineButton(
                            label: context.tr('change_password'),
                            icon: Icons.lock_outline_rounded,
                            onPressed: _showChangePasswordDialog,
                          ),
                          const SizedBox(height: 32),

                          // ── Danger Zone ────────────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _AppColors.errorLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _AppColors.error.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: _AppColors.error, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Danger Zone',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _AppColors.error.withOpacity(0.9),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _confirmDeleteAccount,
                                    icon: const Icon(Icons.delete_forever_rounded,
                                        color: _AppColors.error, size: 18),
                                    label: Text(
                                      context.tr('delete_account'),
                                      style: const TextStyle(
                                        color: _AppColors.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(
                                          color: _AppColors.error, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}