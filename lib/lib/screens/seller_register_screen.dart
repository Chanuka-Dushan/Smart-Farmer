import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../providers/auth_provider.dart';
import '../services/l10n_extension.dart';
import '../utils/error_handler.dart';

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.registerSeller(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      businessName: _businessNameController.text.trim(),
      ownerFirstname: _firstnameController.text.trim(),
      ownerLastname: _lastnameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seller account created! Please complete your shop setup."),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to seller onboarding
      Navigator.pushReplacementNamed(context, '/seller-onboarding');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? "Registration failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      String email = '';
      String firstname = '';
      String lastname = '';
      String socialId = '';
      String? profilePictureUrl;

      if (provider == 'google') {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email'],
          serverClientId: '941688275134-rdm2qs0drvkceu69f0n8n71lth01h63b.apps.googleusercontent.com',
        );
        await googleSignIn.signOut(); // Force account selection
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return;

        email = googleUser.email;
        final nameParts = googleUser.displayName?.split(' ') ?? ['User'];
        firstname = nameParts[0];
        lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        socialId = googleUser.id;
        profilePictureUrl = googleUser.photoUrl;
      } else if (provider == 'facebook') {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status != LoginStatus.success) return;

        final userData = await FacebookAuth.instance.getUserData();
        email = userData['email'];
        final nameParts = (userData['name'] as String).split(' ');
        firstname = nameParts[0];
        lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        socialId = userData['id'];
        profilePictureUrl = userData['picture']['data']['url'];
      }

      final success = await authProvider.socialLogin(
        provider: provider,
        idToken: socialId ?? "mock_id_${DateTime.now().millisecondsSinceEpoch}",
        email: email ?? "seller_${provider}@example.com",
        name: "${firstname ?? "Social"} ${lastname ?? provider.toUpperCase()}",
        photoUrl: profilePictureUrl,
        userType: 'seller',
        businessName: '${firstname ?? "Social"}\'s Shop',
      );

      if (!mounted) return;
      if (success) {
        if (authProvider.seller != null && !authProvider.seller!.onboardingCompleted) {
          Navigator.pushReplacementNamed(context, '/seller-onboarding');
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        if (authProvider.errorMessage?.toLowerCase().contains('banned') ?? false) {
          _showBannedDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.errorMessage ?? "Social login failed")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().toLowerCase().contains('banned')) {
        _showBannedDialog(context);
      } else {
        final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBannedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text("Access Denied", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your account has been restricted.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              "An administrator has suspended your access for violating our terms of service or safety guidelines.",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              "If you believe this is a mistake, please reach out to our support team at support@smartfarmer.com",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Understand", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Seller'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.store_rounded,
                  size: 64,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green[400]
                      : const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 16),
                Text(
                  "Create Seller Account",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Sell farm equipment & spare parts",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 32),

                // Social Login Options
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleSocialLogin('google'),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleSocialLogin('facebook'),
                        icon: const Icon(Icons.facebook, size: 24),
                        label: const Text('Facebook'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: 'Business/Shop Name *',
                    hintText: 'e.g., Green Farm Supplies',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.store),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your business name' : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  '📍 You can add your business location and logo after registration',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstnameController,
                  decoration: InputDecoration(
                    labelText: '${context.tr('first_name')} *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter first name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastnameController,
                  decoration: InputDecoration(
                    labelText: '${context.tr('last_name')} *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter last name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '${context.tr('email')} *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return context.tr('please_enter_email');
                    if (!value.contains('@')) return context.tr('please_enter_valid_email');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '${context.tr('password')} *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    helperText: 'Minimum 6 characters',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return context.tr('please_enter_password');
                    if (value.length < 6) return context.tr('password_too_short');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Register as Seller", style: TextStyle(fontSize: 18)),
                          );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('already_have_account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
