# Smart Farmer - Agricultural Spare Parts Management System

A comprehensive Flutter-based mobile application for managing agricultural machinery spare parts, connecting farmers with sellers, and providing AI-powered features for part identification and inventory management.

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Building for Production](#building-for-production)
- [Dependencies](#dependencies)
- [API Integration](#api-integration)
- [Firebase Setup](#firebase-setup)
- [Troubleshooting](#troubleshooting)

## 🚀 Features

### Core Features
- **Multi-language Support**: Supports Sinhala, Tamil, and English
- **User Authentication**: Secure login/registration with JWT tokens
- **Social Login**: Google and Facebook authentication
- **User Roles**: Separate interfaces for Farmers and Sellers
- **Camera Integration**: AI-powered spare part recognition
- **Real-time Notifications**: Firebase Cloud Messaging integration
- **Location Services**: Find nearby sellers and spare part shops
- **Payment Integration**: Stripe payment processing
- **PDF Generation**: Generate and share invoices/receipts

### Farmer Features
- Create spare part requests with images
- Search parts using NLP (Natural Language Processing)
- View and compare offers from multiple sellers
- Track order status
- Payment history
- Location-based seller search
- Part compatibility checker
- 3D part viewer

### Seller Features
- View and respond to spare part requests
- Manage inventory
- Accept/reject orders
- Track payments
- High-demand parts analytics
- Seasonal demand insights
- Lifecycle prediction for parts
- Inventory optimization recommendations

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.7.2 or higher
  - [Download Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK**: Version 3.7.2 or higher (bundled with Flutter)
- **Android Studio** (for Android development)
  - Android SDK (API Level 29 or higher)
  - Android NDK version 29.0.13113456
  - Kotlin version 2.0.0
- **Xcode** (for iOS development - macOS only)
  - iOS 12.0 or higher
- **Git**: For version control
- **VS Code** or **Android Studio** (recommended IDEs)

### System Requirements

#### Android Development
- Min SDK: 29 (Android 10)
- Target SDK: 35
- Compile SDK: 35
- Kotlin: 2.0.0
- JDK: 11 or higher
- Gradle: 8.7.0
- Android Gradle Plugin: 8.7.0

#### iOS Development
- iOS 12.0 or higher
- Xcode 14.0 or higher
- CocoaPods

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Chanuka-Dushan/smart_farmer.git
cd smart_farmer
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

This will download all the required packages listed in `pubspec.yaml`.

### 3. Set Up Environment Variables

Create a `.env` file in the project root directory:

```bash
# .env file
API_BASE_URL=https://farmerlk.me/backend
ENVIRONMENT=development
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRATION=3600
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
```

**Note**: Never commit the `.env` file to version control. It's already included in `.gitignore`.

### 4. Firebase Configuration

The project uses Firebase for:
- Cloud Messaging (Push Notifications)
- Authentication
- Analytics

Firebase configuration files are already included:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Web/Desktop: `lib/firebase_options.dart`

If you need to reconfigure Firebase:
1. Create a project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android/iOS apps to your Firebase project
3. Download and replace the configuration files
4. Run: `flutterfire configure`

### 5. Android Setup

For Android, ensure you have the correct Kotlin version:

The project uses Kotlin 2.0.0. The configuration is already set in:
- `android/settings.gradle.kts`
- `android/gradle.properties`
- `android/app/build.gradle.kts`

### 6. iOS Setup (macOS only)

```bash
cd ios
pod install
cd ..
```

## 📁 Project Structure

```
smart_farmer/
├── android/                    # Android native code
│   ├── app/
│   │   ├── build.gradle.kts   # App-level Gradle configuration
│   │   ├── google-services.json # Firebase Android config
│   │   └── src/               # Android source files
│   ├── settings.gradle.kts    # Project-level Gradle settings
│   └── gradle.properties      # Gradle properties
├── ios/                        # iOS native code
│   ├── Runner/
│   └── Podfile                # iOS dependencies
├── lib/                        # Main Flutter application code
│   ├── config/                # App configuration
│   │   └── app_config.dart    # API and environment config
│   ├── models/                # Data models
│   │   ├── user_model.dart
│   │   ├── seller_model.dart
│   │   ├── spare_part_model.dart
│   │   └── shop_location_model.dart
│   ├── providers/             # State management
│   │   └── auth_provider.dart # Authentication state
│   ├── screens/               # UI screens (37+ screens)
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── camera_scan_screen.dart
│   │   ├── spare_part_request_screen.dart
│   │   ├── payment_screen.dart
│   │   └── ... (30+ more screens)
│   ├── services/              # Business logic services
│   │   ├── api_service.dart   # Backend API integration
│   │   ├── notification_service.dart # FCM notifications
│   │   ├── l10n.dart          # Localization service
│   │   └── theme_service.dart # Theme management
│   ├── translations/          # Multi-language support
│   ├── utils/                 # Utility functions
│   │   ├── error_handler.dart
│   │   ├── api_error_messages.dart
│   │   └── firebase_helper.dart
│   ├── widgets/               # Reusable UI components
│   │   └── quick_camera_analysis.dart
│   ├── firebase_options.dart  # Firebase configuration
│   └── main.dart              # App entry point
├── test/                      # Unit and widget tests
├── web/                       # Web platform files
├── windows/                   # Windows platform files
├── linux/                     # Linux platform files
├── macos/                     # macOS platform files
├── .env                       # Environment variables (create this)
├── .gitignore                 # Git ignore rules
├── analysis_options.yaml      # Dart analyzer configuration
├── firebase.json              # Firebase project configuration
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # This file
```

## ⚙️ Configuration

### API Configuration

The application connects to a backend API. Configure the API endpoint in `.env`:

```env
API_BASE_URL=https://farmerlk.me/backend
```

### Supported API Endpoints

The app integrates with the following backend endpoints:
- `/api/auth/login` - User login
- `/api/auth/register` - User registration
- `/api/auth/social` - Social login (Google/Facebook)
- `/api/spare-parts/requests` - Spare part requests
- `/api/spare-parts/offers` - Offers management
- `/api/payments/*` - Payment processing (Stripe)
- `/api/sellers/*` - Seller management
- `/api/ml/*` - Machine learning features

### Theme Configuration

The app supports both light and dark themes. Users can toggle between themes in the settings screen.

### Language Configuration

Three languages are supported:
- English (en)
- Sinhala (si)
- Tamil (ta)

Users can select their preferred language on first launch or change it in settings.

## 🚀 Running the Application

### Check Flutter Environment

Before running, verify your Flutter installation:

```bash
flutter doctor
```

Fix any issues reported by `flutter doctor`.

### Run on Android Emulator/Device

1. Start an Android emulator or connect an Android device
2. Check connected devices:
   ```bash
   flutter devices
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Run on iOS Simulator/Device (macOS only)

1. Start an iOS simulator or connect an iOS device
2. Run the app:
   ```bash
   flutter run
   ```

### Run on Chrome (Web)

```bash
flutter run -d chrome
```

### Run with Hot Reload

Flutter supports hot reload for faster development:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Run in Release Mode

```bash
flutter run --release
```

## 🏗️ Building for Production

### Build Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Android App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Build iOS App (macOS only)

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to archive and upload to App Store.

### Build Web App

```bash
flutter build web --release
```

Output: `build/web/`

### Build Windows App

```bash
flutter build windows --release
```

### Build macOS App

```bash
flutter build macos --release
```

## 📚 Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK | Flutter framework |
| cupertino_icons | ^1.0.8 | iOS style icons |
| http | ^1.6.0 | HTTP client |
| provider | ^6.1.2 | State management |
| shared_preferences | ^2.3.4 | Local data storage |
| flutter_secure_storage | ^9.0.0 | Secure storage for tokens |

### Firebase & Authentication

| Package | Version | Purpose |
|---------|---------|---------|
| firebase_core | ^2.24.2 | Firebase core SDK |
| firebase_messaging | ^14.7.9 | Push notifications |
| google_sign_in | ^6.2.1 | Google authentication |
| flutter_facebook_auth | ^7.0.1 | Facebook authentication |

### UI & Media

| Package | Version | Purpose |
|---------|---------|---------|
| camera | ^0.11.0+2 | Camera access |
| image_picker | ^1.1.2 | Image selection |
| lottie | ^3.1.0 | Animations |
| flutter_local_notifications | ^17.0.0 | Local notifications |

### Maps & Location

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_map | ^6.1.0 | Map display |
| latlong2 | ^0.9.1 | Latitude/longitude handling |
| geolocator | ^11.0.0 | Location services |

### Payments & Documents

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_stripe | ^11.1.0 | Stripe payments |
| pdf | ^3.10.7 | PDF generation |
| path_provider | ^2.1.1 | File system access |
| share_plus | ^7.2.1 | Share functionality |

### Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_dotenv | ^5.2.1 | Environment variables |
| permission_handler | ^11.3.1 | Permission management |
| url_launcher | ^6.2.5 | URL/phone launching |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_test | SDK | Testing framework |
| flutter_lints | ^5.0.0 | Lint rules |

To install all dependencies:

```bash
flutter pub get
```

To upgrade dependencies:

```bash
flutter pub upgrade
```

To check for outdated dependencies:

```bash
flutter pub outdated
```

## 🔗 API Integration

### Backend Requirements

The application requires a backend API with the following features:
- User authentication (JWT tokens)
- Spare parts management
- Order processing
- Payment processing (Stripe integration)
- Machine learning endpoints for:
  - Part recognition from images
  - NLP-based search
  - Demand prediction
  - Inventory optimization

### Authentication Flow

1. User logs in via:
   - Email/Password
   - Google Sign-In
   - Facebook Login
2. Backend returns JWT token
3. Token stored securely in `flutter_secure_storage`
4. Token sent in `Authorization` header for all API requests
5. Token refreshed when expired

### API Error Handling

The app includes comprehensive error handling:
- Network errors (timeout, no connection)
- Server errors (500+)
- Authentication errors (401, 403)
- Validation errors (400)
- User-friendly error messages in multiple languages

## 🔥 Firebase Setup

### Initial Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android app:
   - Package name: `com.example.smart_farmer`
   - Download `google-services.json` to `android/app/`
3. Add iOS app:
   - Bundle ID: `com.example.smartFarmer`
   - Download `GoogleService-Info.plist` to `ios/Runner/`

### Firebase Features Used

- **Cloud Messaging (FCM)**: Push notifications for:
  - New spare part requests
  - Order updates
  - Payment confirmations
  - Chat messages
- **Analytics**: User behavior tracking
- **Crashlytics**: Crash reporting (optional)

### Enable Required Firebase Services

In Firebase Console:
1. Enable **Authentication** providers:
   - Email/Password
   - Google
   - Facebook
2. Enable **Cloud Messaging**
3. Set up **Cloud Functions** for background message handling

## 🐛 Troubleshooting

### Common Issues

#### 1. Gradle Build Failures

**Issue**: `Kotlin metadata version 2.1.0 not supported`

**Solution**: 
The project uses Kotlin 2.0.0. Ensure your `android/settings.gradle.kts` has:
```kotlin
id("org.jetbrains.kotlin.android") version "2.0.0" apply false
```

#### 2. Flutter Pub Get Fails

**Issue**: Dependency resolution errors

**Solution**:
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

#### 3. Firebase Not Working

**Issue**: Firebase services not initializing

**Solution**:
- Verify `google-services.json` (Android) is in `android/app/`
- Verify `GoogleService-Info.plist` (iOS) is in `ios/Runner/`
- Check Firebase project ID matches in `firebase.json`
- Run: `flutterfire configure`

#### 4. Camera/Location Permissions

**Issue**: Permissions denied

**Solution**:
Add permissions in:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

The required permissions are already configured in the project.

#### 5. Environment Variables Not Loading

**Issue**: `.env` file not found

**Solution**:
- Create `.env` file in project root
- Add required variables (see Configuration section)
- Ensure `.env` is listed in `pubspec.yaml` assets

#### 6. iOS Build Fails

**Issue**: CocoaPods errors

**Solution**:
```bash
cd ios
pod repo update
pod install
cd ..
```

#### 7. "Lost Connection to Device"

**Issue**: App crashes or disconnects during `flutter run`

**Solution**:
- Check device logs for exceptions
- Ensure `.env` file exists with valid API_BASE_URL
- Verify backend API is accessible
- Check Firebase configuration

### Clean Build

If you encounter persistent issues, try a clean build:

```bash
# Clean Flutter build
flutter clean

# Remove build directories
rm -rf build/
rm -rf android/.gradle/
rm -rf android/app/build/

# iOS (macOS only)
cd ios
rm -rf Pods/
rm Podfile.lock
pod install
cd ..

# Get dependencies
flutter pub get

# Run again
flutter run
```

### Debug Logs

Enable verbose logging:

```bash
flutter run -v
```

Check device logs:

```bash
# Android
adb logcat

# iOS
flutter logs
```

## 📱 Testing

### Run Unit Tests

```bash
flutter test
```

### Run Integration Tests

```bash
flutter test integration_test/
```

### Test Coverage

```bash
flutter test --coverage
```

## 📄 License

This project is proprietary software. All rights reserved.

## 👥 Contributors

- Development Team: Smart Farmer Development Team
- Backend API: farmerlk.me
- Firebase Project: smart-farmer-39b56

## 📞 Support

For issues, questions, or support:
- Create an issue in the repository
- Contact: support@farmerlk.me
- Documentation: [Project Wiki](https://github.com/yourusername/smart_farmer/wiki)

## 🔄 Version History

- **v1.0.0+1** (Current)
  - Initial release
  - Multi-language support
  - Social authentication
  - Payment integration
  - AI-powered features

## 🚧 Roadmap

- [ ] Offline mode support
- [ ] Enhanced 3D part viewer
- [ ] Video tutorials
- [ ] In-app chat system
- [ ] Advanced analytics dashboard
- [ ] Multi-currency support
- [ ] Warranty tracking

---

**Built with ❤️ using Flutter**
