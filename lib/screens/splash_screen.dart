import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/l10n_extension.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLanguageSelection();
  }

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
      
      // Language is selected, check onboarding
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      debugPrint('Onboarding completed: $onboardingCompleted');
      
      if (!onboardingCompleted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }
      
      // Onboarding completed, check authentication
      debugPrint('Checking auth status...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        await authProvider.checkAuthStatus();
        debugPrint('Auth check complete. Authenticated: ${authProvider.isAuthenticated}');
      } catch (e) {
        debugPrint('Error checking auth status: $e');
        // If auth check fails, go to login
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      
      if (!mounted) return;
      
      if (authProvider.isAuthenticated) {
        debugPrint('User is authenticated. IsSeller: ${authProvider.isSeller}');
        if (authProvider.isSeller && authProvider.seller != null && !authProvider.seller!.onboardingCompleted) {
          debugPrint('Navigating to seller onboarding');
          Navigator.pushReplacementNamed(context, '/seller-onboarding');
        } else {
          debugPrint('Navigating to home');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        debugPrint('User not authenticated, navigating to login');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Error in splash screen: $e');
      // On any error, go to login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Logo - You can replace Icon with Image.asset()
            Icon(
              Icons.agriculture,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('app_name'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('app_subtitle'),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }
}