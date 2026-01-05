import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../providers/auth_provider.dart';
import '../services/l10n_extension.dart';


// TODO: For production deployment, consider implementing:
// 1. Proper geocoding service (Google Maps Platform, Mapbox, or OpenStreetMap Nominatim)
// 2. Location validation and reverse geocoding
// 3. Offline map tiles for areas with poor connectivity
// 4. Location accuracy improvements
// 5. Privacy policy compliance for location data

import '../utils/error_handler.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
  }



  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      firstname: _firstnameController.text.trim(),
      lastname: _lastnameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('account_created')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? context.tr('registration_failed')),
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
        await googleSignIn.signOut();
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
        idToken: socialId,
        email: email,
        name: "$firstname $lastname",
        photoUrl: profilePictureUrl,
      );

      if (!mounted) return;
      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? "Social login failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Farmer'),
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
                Text(
                  'Create Farmer Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Buy farm equipment & spare parts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
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

                // Basic Information
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_first_name');
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_last_name');
                    }
                    return null;
                  },
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
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_email');
                    }
                    if (!value.contains('@')) {
                      return context.tr('please_enter_valid_email');
                    }
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
                    helperText: context.tr('password_min_length'),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_password');
                    }
                    if (value.length < 6) {
                      return context.tr('password_too_short');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: '${context.tr('phone')} (${context.tr('optional')})',
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '${context.tr('address')} (${context.tr('optional')})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                  ),
                ),

                const SizedBox(height: 24),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              context.tr('register'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(context.tr('already_have_account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSocialLogin(String provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to $provider...')),
    );

    try {
      String? email;
      String? firstName;
      String? lastName;
      String? socialId;

      if (provider == 'google') {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email'],
          serverClientId: '941688275134-rdm2qs0drvkceu69f0n8n71lth01h63b.apps.googleusercontent.com',
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return; // User cancelled

        email = googleUser.email;
        final nameParts = googleUser.displayName?.split(' ') ?? ['Social', 'User'];
        firstName = nameParts.first;
        lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Google';
        socialId = googleUser.id;
      } else {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status != LoginStatus.success) {
          throw Exception('Facebook login failed: ${result.message}');
        }

        final userData = await FacebookAuth.instance.getUserData();
        email = userData['email'];
        firstName = userData['name']?.split(' ').first ?? 'Social';
        lastName = userData['name']?.split(' ').last ?? 'Facebook';
        socialId = userData['id'];
      }

      final success = await authProvider.socialLogin(
        email: email ?? "user_$provider@example.com",
        firstname: firstName ?? "Social",
        lastname: lastName ?? provider.toUpperCase(),
        socialId: socialId ?? "mock_id_${DateTime.now().millisecondsSinceEpoch}",
        provider: provider,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Social login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Social login registration error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}



