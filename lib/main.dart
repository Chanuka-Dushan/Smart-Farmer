import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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
import 'screens/my_offerings_screen.dart';
import 'screens/payment_screen.dart';
import 'services/l10n.dart';
import 'services/theme_service.dart';
import 'providers/auth_provider.dart';
import 'config/app_config.dart';

import 'screens/nlp_search_screen.dart';
import 'screens/compatibility_screen.dart';
import 'screens/inventory_optimization_screen.dart';
import 'screens/part_detail_screen.dart';
import 'screens/comparison_screen.dart';
import 'screens/inventory_details_screen.dart';
import 'screens/high_demand_parts_screen.dart';
import 'screens/seasonal_demand_machines_screen.dart';
import 'screens/lifecycle_prediction_screen.dart';
import 'screens/accepted_orders_screen.dart';
import 'screens/my_payments_screen.dart';


Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize L10n singleton and load language preference
  final l10n = L10n();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Stripe
    try {
      final publishableKey = AppConfig.stripePublishableKey;
      
      // Validate publishable key
      if (publishableKey.isEmpty || !publishableKey.startsWith('pk_')) {
        ErrorHandler.logWarning('Invalid Stripe publishable key format');
      } else {
        Stripe.publishableKey = publishableKey;
        
        // Apply Stripe settings with error handling
        try {
          await Stripe.instance.applySettings();
          ErrorHandler.logInfo('Stripe initialized successfully');
        } on PlatformException catch (e) {
          ErrorHandler.logWarning('Stripe PlatformException: ${e.message}');
          ErrorHandler.logWarning('Stripe error code: ${e.code}');
          ErrorHandler.logWarning('Stripe error details: ${e.details}');
        } catch (e) {
          ErrorHandler.logWarning('Failed to apply Stripe settings: $e');
        }
      }
    } catch (e) {
      ErrorHandler.logWarning('Failed to initialize Stripe: $e');
      // Continue with app startup even if Stripe fails
    }
    
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

class SmartSparePartApp extends StatefulWidget {
  const SmartSparePartApp({super.key});

  @override
  State<SmartSparePartApp> createState() => _SmartSparePartAppState();
}

class _SmartSparePartAppState extends State<SmartSparePartApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Re-initialize notifications when app starts
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - re-initialize notifications
        _initializeNotifications();
        break;
      case AppLifecycleState.paused:
        // App went to background
        break;
      case AppLifecycleState.inactive:
        // App is transitioning
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      // Re-initialize notification service to ensure it's working
      await NotificationService.instance.initialize();
      ErrorHandler.logInfo('Notifications re-initialized on app state change');
    } catch (e) {
      ErrorHandler.logError('Failed to re-initialize notifications', e);
      // Don't crash the app, just log the error
    }
  }

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
        '/part-detail': (context) => PartDetailScreen(),
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
        '/my-offerings': (context) => const MyOfferingsScreen(),
        '/accepted-order': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AcceptedOrdersScreen(requestId: args['request_id'] as int);
        },
        '/payment': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaymentScreen(
            offerId: args['offer_id'] as int,
            amount: args['amount'] as double,
            totalAmount: args['total_amount'] as double,
          );
        },
        '/transaction-history': (context) => const MyPaymentsScreen(),
      },
    );
  }
}