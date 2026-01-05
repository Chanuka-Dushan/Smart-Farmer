import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '../utils/firebase_helper.dart';
import 'screens/splash_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/camera_scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/seller_onboarding_screen.dart';
import 'screens/seller_register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/spare_part_request_screen.dart';
import 'screens/my_spare_part_requests_screen.dart';
import 'screens/seller_spare_part_requests_screen.dart';
import 'services/l10n.dart';
import 'services/theme_service.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize FCM
  await FirebaseHelper.initialize();
  
  // Initialize L10n singleton and load language preference
  final l10n = L10n();
  await l10n.loadLanguage();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider.value(value: l10n),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SmartSparePartApp(),
    ),
  );
}

class SmartSparePartApp extends StatelessWidget {
  const SmartSparePartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      title: 'Smart Farmer Spare Parts',
      debugShowCheckedModeBanner: false,
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Define Routes for easy navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),   
        '/register': (context) => const RegisterScreen(),
        '/seller-register': (context) => const SellerRegisterScreen(),
        '/camera': (context) => const CameraScanScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/seller-onboarding': (context) => const SellerOnboardingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/find-spare-part': (context) => const SparePartRequestScreen(),
        '/my-spare-part-requests': (context) => const MySparePartRequestsScreen(),
        '/seller-spare-part-requests': (context) => const SellerSparePartRequestsScreen(),
      },
    );
  }
}