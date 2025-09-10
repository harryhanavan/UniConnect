# Getting Started with UniConnect

## Overview

This guide will help you set up and run UniConnect on your local development environment.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0.0 or higher)
   - Download from [flutter.dev](https://flutter.dev)
   - Add Flutter to your PATH

2. **Dart SDK** (comes with Flutter)
   - Verify with `dart --version`

3. **IDE/Editor**
   - VS Code with Flutter extension (recommended)
   - Android Studio with Flutter plugin
   - IntelliJ IDEA with Flutter plugin

4. **Git**
   - For cloning the repository

### Platform-Specific Requirements

#### Android Development
- Android Studio
- Android SDK
- Android emulator or physical device
- Java 11 or higher

#### iOS Development (Mac only)
- Xcode
- iOS Simulator or physical device
- CocoaPods (`sudo gem install cocoapods`)

#### Web Development
- Chrome browser
- Any modern web browser for testing

## Installation Steps

### 1. Clone the Repository

```bash
git clone [repository-url]
cd UniConnect
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Setup

```bash
flutter doctor
```

This command checks your environment and displays a report:
- ✓ Green checkmarks indicate correctly configured components
- ! Yellow warnings for optional components
- ✗ Red X marks for required fixes

### 4. Run the App

#### On Android Emulator/Device
```bash
flutter run -d android
```

#### On iOS Simulator/Device
```bash
flutter run -d ios
```

#### On Web (Chrome)
```bash
flutter run -d chrome
```

#### On Windows Desktop
```bash
flutter run -d windows
```

#### List Available Devices
```bash
flutter devices
```

## Project Structure

```
UniConnect/
├── lib/
│   ├── main.dart           # App entry point
│   ├── core/               # Core functionality
│   │   ├── demo_data/      # Mock data management
│   │   ├── services/       # Business logic
│   │   └── constants/      # App constants
│   ├── features/           # Feature modules
│   │   ├── home/
│   │   ├── calendar/
│   │   ├── chat/
│   │   ├── friends/
│   │   ├── societies/
│   │   ├── privacy/
│   │   └── settings/
│   └── shared/             # Shared resources
│       ├── models/         # Data models
│       └── widgets/        # Reusable widgets
├── test/                   # Test files
├── android/               # Android specific files
├── ios/                   # iOS specific files
├── web/                   # Web specific files
├── windows/               # Windows specific files
└── pubspec.yaml          # Dependencies and metadata
```

## First Run

### What to Expect

1. **Splash Screen**: Brief loading screen
2. **Home Screen**: Dashboard with demo data
3. **Navigation**: Bottom navigation with 5 sections
4. **Demo User**: Logged in as Andrea Fernandez

### Demo Credentials

The app uses demo data with a pre-configured user:
- **Name**: Andrea Fernandez
- **Email**: andrea.fernandez@student.uts.edu.au
- **Course**: Bachelor of Science in IT
- **Year**: 3rd Year

### Key Features to Explore

1. **Home Dashboard**
   - Today's schedule
   - Friend activity
   - Quick actions

2. **Calendar**
   - View events
   - Different calendar views
   - Event details

3. **Chat**
   - Message conversations
   - Unread indicators

4. **Societies**
   - Browse societies
   - Join/leave societies
   - Society details

5. **Friends**
   - Friends list
   - Friend requests
   - Friend profiles

## Development Commands

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test
```

### Building

```bash
# Build APK (Android)
flutter build apk

# Build for iOS
flutter build ios

# Build for Web
flutter build web
```

### Hot Reload

While the app is running:
- Press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit

## Common Issues and Solutions

### Issue: Flutter command not found
**Solution**: Add Flutter to your PATH environment variable

### Issue: Android licenses not accepted
**Solution**: Run `flutter doctor --android-licenses`

### Issue: CocoaPods not installed (iOS)
**Solution**: Run `sudo gem install cocoapods`

### Issue: Gradle build failed (Android)
**Solution**: 
- Clean build: `flutter clean`
- Then: `flutter pub get`
- Retry: `flutter run`

### Issue: Chrome not found (Web)
**Solution**: Install Chrome or use another browser:
```bash
flutter run -d web-server
```

## IDE Setup

### VS Code

1. Install Flutter extension
2. Install Dart extension
3. Open project folder
4. Press F5 to run

### Android Studio

1. Install Flutter plugin
2. Install Dart plugin
3. Open project
4. Click Run button

## Next Steps

1. **Explore the Code**: Browse the `lib/` directory
2. **Read Documentation**: Check other guides in `docs/`
3. **Modify Demo Data**: See [Demo Data Guide](demo-data-guide.md)
4. **Start Developing**: See [Development Guide](development-guide.md)
5. **Run Tests**: See [Testing Guide](testing-guide.md)

## Useful Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

## Getting Help

- Check the [FAQ](../faq.md)
- Review [Common Issues](../troubleshooting.md)
- Search existing issues in the repository
- Create a new issue with detailed information