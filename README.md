# UniConnect

A Flutter-based university social platform designed to help students connect, find friends on campus, manage their academic schedule, and engage with university societies.

## 🚀 Getting Started for Team Members

### Prerequisites

Before you can run UniConnect, ensure you have the following installed:

1. **Flutter SDK** (Latest stable version)
   - Download from: https://docs.flutter.dev/get-started/install
   - Follow platform-specific installation guide for your OS

2. **Development Environment** (Choose one):
   - **Android Studio** (Recommended)
     - Download from: https://developer.android.com/studio
     - Install Flutter and Dart plugins
   - **VS Code** with Flutter extension
   - **IntelliJ IDEA** with Flutter plugin

3. **Platform-Specific Requirements**:
   
   **For Android Development:**
   - Android Studio with Android SDK
   - Android emulator or physical device
   - Java 11+ (usually comes with Android Studio)

   **For iOS Development (macOS only):**
   - Xcode (latest version)
   - iOS Simulator or physical device
   - CocoaPods: `sudo gem install cocoapods`

   **For Web Development:**
   - Chrome browser (for debugging)

   **For Windows Desktop:**
   - Visual Studio 2019+ with C++ build tools

### 🛠️ Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone [REPOSITORY_URL]
   cd UniConnect
   ```

2. **Verify Flutter Installation**
   ```bash
   flutter doctor
   ```
   Ensure all checkmarks are green (or address any issues shown)

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Verify Setup**
   ```bash
   flutter analyze
   ```
   This should run without errors.

### 🏃‍♂️ Running the App

1. **Start an Emulator/Simulator**
   - **Android**: Open Android Studio > AVD Manager > Start emulator
   - **iOS**: Open Xcode > Open Developer Tool > Simulator
   - **Web**: No emulator needed
   - **Windows**: No emulator needed

2. **Run the App**
   ```bash
   # Run on available device (Flutter will prompt if multiple devices)
   flutter run
   
   # Or specify a platform:
   flutter run -d chrome        # Web
   flutter run -d windows       # Windows desktop
   flutter run -d android       # Android
   flutter run -d ios           # iOS (macOS only)
   ```

3. **Hot Reload During Development**
   - Press `r` in terminal for hot reload
   - Press `R` for hot restart
   - Press `q` to quit

### 📱 Platform-Specific Setup

#### Android Setup
1. Ensure Android SDK is installed via Android Studio
2. Create or start an Android Virtual Device (AVD)
3. For physical devices: Enable Developer Options and USB Debugging

#### iOS Setup (macOS only)
1. Install Xcode from Mac App Store
2. Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. Accept Xcode license: `sudo xcodebuild -license`
4. Install CocoaPods: `sudo gem install cocoapods`

#### Web Setup
1. Enable web support: `flutter config --enable-web`
2. Chrome browser required for debugging

### 🧪 Development Workflow

#### Code Quality Commands
```bash
# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Format code (do this before committing)
dart format lib/

# Clean build artifacts (if issues occur)
flutter clean
flutter pub get
```

#### Building for Release
```bash
# Android
flutter build apk --release

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

### 🗂️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── demo_data/           # Mock data for development
│   ├── services/            # Business logic services
│   └── constants/           # App-wide constants
├── features/                # Feature modules
│   ├── home/
│   ├── calendar/
│   ├── chat/
│   ├── friends/
│   └── societies/
└── shared/
    ├── models/              # Data models
    └── widgets/             # Reusable UI components
```

### 🎨 Design System

- **Material Design 3** with custom theming
- **Dark/Light mode** support
- **Responsive layouts** for different screen sizes
- **Google Fonts** for typography

### 📊 Demo Data

The app uses comprehensive demo data for development and testing:
- 20+ demo users with relationships
- University societies and events
- Chat conversations
- Calendar events
- Location data

All demo data is managed in `lib/core/demo_data/demo_data_manager.dart`

### 🚨 Troubleshooting

#### Common Issues:

1. **"Flutter command not found"**
   - Ensure Flutter is added to your PATH
   - Restart terminal/IDE after installation

2. **"No devices found"**
   - Start an emulator/simulator
   - For physical devices, enable Developer Mode

3. **"Gradle build failed" (Android)**
   - Try: `flutter clean && flutter pub get`
   - Check Java version (should be Java 11+)

4. **"Pod install failed" (iOS)**
   - Navigate to `ios/` folder and run: `pod install`
   - Ensure CocoaPods is installed

5. **"Version conflicts"**
   - Delete `pubspec.lock` and run `flutter pub get`
   - Try `flutter pub upgrade`

#### Getting Help:
- Check `flutter doctor` for system issues
- Run `flutter analyze` for code issues
- Consult [Flutter documentation](https://docs.flutter.dev/)

### 🤝 Development Guidelines

1. **Before Coding:**
   - Pull latest changes: `git pull origin main`
   - Run `flutter pub get` to ensure dependencies are up to date

2. **Before Committing:**
   - Format code: `dart format lib/`
   - Check for issues: `flutter analyze`
   - Test your changes: `flutter test`

3. **Code Style:**
   - Follow Dart conventions
   - Use meaningful variable names
   - Add comments for complex logic

### 🔧 IDE Configuration

#### VS Code Extensions (Recommended):
- Flutter
- Dart
- Material Icon Theme
- Bracket Pair Colorizer

#### Android Studio Plugins:
- Flutter
- Dart

### 📝 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design 3](https://m3.material.io/)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)

---

**Need Help?** Contact the development team or create an issue in the repository.