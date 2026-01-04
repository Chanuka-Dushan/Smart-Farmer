import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'utils/error_handler.dart';
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

import 'screens/nlp_search_screen.dart';
import 'screens/compatibility_screen.dart';
import 'screens/inventory_optimization_screen.dart';
import 'screens/comparison_screen.dart';
import 'screens/inventory_details_screen.dart';
import 'screens/high_demand_parts_screen.dart';
import 'screens/seasonal_demand_machines_screen.dart';
import 'screens/alternative_parts_screen.dart';
import 'screens/part_search_result_screen.dart';
import 'screens/lifecycle_prediction_screen.dart';


Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize L10n singleton and load language preference
  final l10n = L10n();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize notification service
    await NotificationService.instance.initialize();
    
    // Load language preference
    await l10n.loadLanguage();
    
    ErrorHandler.logInfo('App initialization completed successfully');
  } catch (e) {
    ErrorHandler.logError('Failed to initialize app', e);
    // Continue with app startup even if some services fail
  }
  
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
        '/home': (context) => HomeScreen(),
        '/login': (context) => const LoginScreen(),   
        '/register': (context) => const RegisterScreen(),
        '/seller-register': (context) => const SellerRegisterScreen(),
        '/camera': (context) => const CameraScanScreen(),
        '/settings': (context) => const SettingsScreen(),

        '/nlp-search': (context) => NlpSearchScreen(),
        '/part-search-result': (context) => PartSearchResultScreen(),
        '/alternative-parts': (context) => AlternativePartsScreen(),
        '/comparison': (context) => ComparisonScreen(),
        '/compatibility': (context) => CompatibilityScreen(),
        '/inventory-optimization': (context) => InventoryOptimizationScreen(),
        '/inventory-details': (context) => InventoryDetailsScreen(),
        '/high-demand-results': (context) => const HighDemandResultScreen(),
        '/seasonal-machines': (context) => const SeasonalMachineScreen(),
        '/lifecycle-prediction': (context) => const LifecyclePredictionScreen(),

        '/seller-onboarding': (context) => const SellerOnboardingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/find-spare-part': (context) => const SparePartRequestScreen(),
        '/my-spare-part-requests': (context) => const MySparePartRequestsScreen(),
        '/seller-spare-part-requests': (context) => const SellerSparePartRequestsScreen(),

      },
    );
  }
}