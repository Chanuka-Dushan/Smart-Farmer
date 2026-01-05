import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../providers/auth_provider.dart';
import '../services/l10n_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to handle login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.isSeller &&
          authProvider.seller != null &&
          !authProvider.seller!.onboardingCompleted) {
        Navigator.pushReplacementNamed(context, '/seller-onboarding');
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else {
      if (authProvider.errorMessage?.toLowerCase().contains('banned') ??
          false) {
        _showBannedDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? context.l10n.tr('login_failed'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to handle social login
  Future<void> _handleSocialLogin(String provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Connecting to $provider...')));

    try {
      String? email;
      String? firstName;
      String? lastName;
      String? socialId;
      String? profilePic;

      if (provider == 'google') {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email'],
          // Use the web client ID from Firebase Console for Android
          serverClientId:
              '941688275134-rdm2qs0drvkceu69f0n8n71lth01h63b.apps.googleusercontent.com',
        );
        await googleSignIn.signOut(); // Force account selection
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google Sign-In cancelled')),
            );
          }
          return;
        }

        email = googleUser.email;
        final nameParts =
            googleUser.displayName?.split(' ') ?? ['Social', 'User'];
        firstName = nameParts.first;
        lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Google';
        socialId = googleUser.id;
        profilePic = googleUser.photoUrl;
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
        profilePic = userData['picture']?['data']?['url'];
      }

      final success = await authProvider.socialLogin(
        provider: provider,
        idToken: socialId ?? "mock_id_${DateTime.now().millisecondsSinceEpoch}",
        email: email ?? "user_${provider}@example.com",
        name: "${firstName ?? "Social"} ${lastName ?? provider.toUpperCase()}",
        photoUrl: profilePic,
      );

      if (!mounted) return;

      if (success) {
        if (authProvider.isSeller &&
            authProvider.seller != null &&
            !authProvider.seller!.onboardingCompleted) {
          Navigator.pushReplacementNamed(context, '/seller-onboarding');
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        if (authProvider.errorMessage?.toLowerCase().contains('banned') ??
            false) {
          _showBannedDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Social login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Social login error: $e");
      if (!mounted) return;
      if (e.toString().toLowerCase().contains('banned')) {
        _showBannedDialog(context);
      } else {
        String errorMessage = 'Login failed';
        if (e.toString().contains('PlatformException')) {
          if (e.toString().contains('sign_in_canceled')) {
            errorMessage = 'Sign-in cancelled';
          } else if (e.toString().contains('network_error')) {
            errorMessage = 'Network error. Please check your connection.';
          } else if (e.toString().contains('sign_in_failed')) {
            errorMessage = 'Sign-in failed. Please try again.';
          } else {
            errorMessage =
                'Google Sign-In error. Please check your configuration.';
          }
        } else {
          errorMessage = 'Login failed: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showBannedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.report_problem, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text(
                  "Access Denied",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                child: const Text(
                  "Understand",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.agriculture,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('welcome_back'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login as Farmer or Seller',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.tr('email'),
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.surface
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
                    labelText: context.tr('password'),
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.surface
                            : Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('please_enter_password');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: _login,
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
                            context.tr('login'),
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
                    // Navigate to forgot password screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(context.tr('forgot_password')),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        context.tr('or_continue_with'),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _socialButton(
                        icon: Icons.g_mobiledata,
                        color: Colors.red,
                        label: 'Google',
                        onPressed: () => _handleSocialLogin('google'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _socialButton(
                        icon: Icons.facebook,
                        color: Colors.blue[800]!,
                        label: 'Facebook',
                        onPressed: () => _handleSocialLogin('facebook'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(
                              context,
                            ).colorScheme.surface.withOpacity(0.5)
                            : Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.5)
                              : Colors.blue[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color
                                      : Colors.blue[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  () =>
                                      Navigator.pushNamed(context, '/register'),
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('Register as Farmer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(
                                  color: Color(0xFF2E7D32),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/seller-register',
                                  ),
                              icon: const Icon(Icons.store, size: 18),
                              label: const Text('Register as Seller'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(
                                  color: Color(0xFF2E7D32),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
          border: Border.all(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                    : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('forgot_password')),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isSent ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('enter_email_to_reset'),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.tr('email'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return context.tr('please_enter_email');
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final success = await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).forgotPassword(_emailController.text.trim());
                if (success) {
                  setState(() => _isSent = true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.tr('failed_to_send_reset')),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(context.tr('send_reset_token')),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final tokenController = TextEditingController();
    final passwordController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    return Form(
      key: resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            context.tr('reset_token_sent'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: tokenController,
            decoration: InputDecoration(
              labelText: context.tr('enter_token'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) => value!.isEmpty ? 'Please enter token' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.tr('new_password'),
              border: const OutlineInputBorder(),
            ),
            validator:
                (value) => value!.length < 6 ? 'Password too short' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (resetFormKey.currentState!.validate()) {
                final success = await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).resetPassword(tokenController.text, passwordController.text);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.tr('password_reset_success')),
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.tr('invalid_token'))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(context.tr('reset_password')),
          ),
        ],
      ),
    );
  }
}
