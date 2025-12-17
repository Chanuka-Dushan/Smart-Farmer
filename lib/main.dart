import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/camera_scan_screen.dart';

void main() {
  runApp(const SmartSparePartApp());
}

class SmartSparePartApp extends StatelessWidget {
  const SmartSparePartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Farmer Spare Parts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Agricultural Color Palette
        primaryColor: const Color(0xFF2E7D32), // Agri Green
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          secondary: const Color(0xFF1565C0), // Tech Blue
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default font
      ),
      // Define Routes for easy navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),   
        '/register': (context) => const RegisterScreen(),
        '/camera': (context) => const CameraScanScreen(),
      },
    );
  }
}