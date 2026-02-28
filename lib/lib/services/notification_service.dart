import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/error_handler.dart';

/// Enhanced Notification Service for handling Firebase Cloud Messaging
/// 
/// This service provides comprehensive notification handling for:
/// - Foreground notifications
/// - Background notifications
/// - Notification tapping
/// - Token management
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _currentToken;
  bool _isInitialized = false;
  
  /// Get current FCM token
  String? get currentToken => _currentToken;
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get and store FCM token
      await _initializeFCMToken();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      _isInitialized = true;
      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      ErrorHandler.logError('Failed to initialize NotificationService', e);
      rethrow;
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional notification permission');
      } else {
        debugPrint('❌ User declined notification permission');
      }
      
      return settings;
    } catch (e) {
      ErrorHandler.logError('Failed to request notification permissions', e);
      rethrow;
    }
  }

  /// Initialize local notifications for displaying notifications in foreground
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();
      
      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      ErrorHandler.logError('Failed to initialize local notifications', e);
      rethrow;
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'smart_farmer_channel',
        'Smart Farmer Notifications',
        description: 'Notifications for Smart Farmer app',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
          
      debugPrint('✅ Notification channel created');
    } catch (e) {
      ErrorHandler.logError('Failed to create notification channel', e);
    }
  }

  /// Initialize FCM token
  Future<void> _initializeFCMToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        debugPrint('📱 FCM Token obtained: $_currentToken');
        // TODO: Send token to backend
        await _sendTokenToServer(_currentToken!);
      } else {
        debugPrint('❌ Failed to get FCM token');
      }
    } catch (e) {
      ErrorHandler.logError('Failed to get FCM token', e);
    }
  }

  /// Set up message handlers for different notification states
  void _setupMessageHandlers() {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification opened from terminated state
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleMessageOpened(message);
        }
      });

      // Handle notification opened from background state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      // Handle token refresh
      _messaging.onTokenRefresh.listen(_handleTokenRefresh);
      
      debugPrint('✅ Message handlers set up');
    } catch (e) {
      ErrorHandler.logError('Failed to set up message handlers', e);
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('📬 Foreground message received:');
      debugPrint('Title: ${message.notification?.title ?? "No title"}');
      debugPrint('Body: ${message.notification?.body ?? "No body"}');
      debugPrint('Data: ${message.data}');

      // Show local notification when app is in foreground
      try {
        await _showLocalNotification(message);
      } catch (e) {
        ErrorHandler.logError('Failed to show local notification', e);
        // Don't rethrow, just log the error
      }
    } catch (e) {
      ErrorHandler.logError('Failed to handle foreground message', e);
      // Don't crash the app, just log the error
    }
  }

  /// Handle message opened from background/terminated state
  Future<void> _handleMessageOpened(RemoteMessage message) async {
    try {
      debugPrint('📬 Message opened:');
      debugPrint('Title: ${message.notification?.title ?? "No title"}');
      debugPrint('Body: ${message.notification?.body ?? "No body"}');
      debugPrint('Data: ${message.data}');

      // Handle navigation based on message data
      try {
        if (message.data.isNotEmpty) {
          await _handleNotificationAction(message.data);
        }
      } catch (e) {
        ErrorHandler.logError('Failed to handle notification action', e);
        // Don't rethrow, just log the error
      }
    } catch (e) {
      ErrorHandler.logError('Failed to handle message opened', e);
      // Don't crash the app, just log the error
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      _currentToken = newToken;
      // Update token on server
      await _sendTokenToServer(newToken);
    } catch (e) {
      ErrorHandler.logError('Failed to handle token refresh', e);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'smart_farmer_channel',
        'Smart Farmer Notifications',
        channelDescription: 'Notifications for Smart Farmer app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = message.notification?.title ?? 'Smart Farmer';
      final body = message.notification?.body ?? 'New notification';
      final payload = message.data.isNotEmpty 
          ? message.data.toString() 
          : null;

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to show local notification', e);
      // Don't rethrow, just log the error
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('📱 Notification tapped: ${response.payload}');
      if (response.payload != null) {
        // Parse payload and handle action
        // TODO: Implement navigation based on payload
      }
    } catch (e) {
      ErrorHandler.logError('Failed to handle notification tap', e);
    }
  }

  /// Handle notification actions based on data
  Future<void> _handleNotificationAction(Map<String, dynamic> data) async {
    try {
      final action = data['action'];
      // type is available for future use if needed
      // final type = data['type'];

      switch (action) {
        case 'open_weather':
          // Navigate to weather screen
          break;
        case 'open_irrigation':
          // Navigate to irrigation screen
          break;
        case 'open_field_details':
          // Navigate to field details
          break;
        case 'open_market':
          // Navigate to market screen
          break;
        case 'open_harvest_schedule':
          // Navigate to harvest schedule
          break;
        case 'open_home':
        default:
          // Navigate to home screen
          break;
      }
      
      debugPrint('✅ Notification action handled: $action');
    } catch (e) {
      ErrorHandler.logError('Failed to handle notification action', e);
    }
  }

  /// Send token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: Implement API call to update user's FCM token
      // This should be integrated with your ApiService
      debugPrint('📤 Sending token to server: $token');
    } catch (e) {
      ErrorHandler.logError('Failed to send token to server', e);
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      ErrorHandler.logError('Failed to subscribe to topic: $topic', e);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      ErrorHandler.logError('Failed to unsubscribe from topic: $topic', e);
    }
  }

  /// Delete FCM token (call when user logs out)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      ErrorHandler.logError('Failed to delete FCM token', e);
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('✅ All notifications cleared');
    } catch (e) {
      ErrorHandler.logError('Failed to clear notifications', e);
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await _messaging.getNotificationSettings();
    } catch (e) {
      ErrorHandler.logError('Failed to get notification settings', e);
      rethrow;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      ErrorHandler.logError('Failed to check notification status', e);
      return false;
    }
  }
}

/// Background message handler
/// This must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('📬 Background message: ${message.messageId ?? "unknown"}');
    debugPrint('Title: ${message.notification?.title ?? "No title"}');
    debugPrint('Body: ${message.notification?.body ?? "No body"}');
    debugPrint('Data: ${message.data}');
    
    // Handle background message processing here
    // Note: You cannot update UI from here
  } catch (e) {
    debugPrint('❌ Error in background handler: $e');
    // Don't rethrow, just log the error to prevent crashes
  }
}