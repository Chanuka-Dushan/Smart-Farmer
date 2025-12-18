import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/l10n.dart';
import '../services/l10n_extension.dart';

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
    await Future.delayed(const Duration(seconds: 3));
    
    final prefs = await SharedPreferences.getInstance();
    final languageSelected = prefs.getBool('language_selected') ?? false;
    
    if (!mounted) return;
    
    if (languageSelected) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/language');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Logo - You can replace Icon with Image.asset()
            const Icon(
              Icons.agriculture,
              size: 100,
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('app_name'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('app_subtitle'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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