# Development Guide

## Overview

This guide covers best practices and workflows for developing UniConnect features.

## Development Workflow

### 1. Setting Up Your Development Environment

```bash
# Clone the repository
git clone [repository-url]
cd UniConnect

# Install dependencies
flutter pub get

# Run the app in debug mode
flutter run
```

### 2. Creating a New Branch

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Create bugfix branch
git checkout -b bugfix/issue-description
```

## Code Organization

### Feature Structure

When creating a new feature, follow this structure:

```
lib/features/your_feature/
├── screens/
│   ├── your_feature_screen.dart
│   └── your_feature_detail_screen.dart
├── widgets/
│   ├── custom_widget.dart
│   └── another_widget.dart
├── models/
│   └── feature_specific_model.dart
└── services/
    └── feature_service.dart
```

### Naming Conventions

#### Files
- Use `snake_case` for file names
- Be descriptive: `user_profile_screen.dart` not `profile.dart`

#### Classes
- Use `PascalCase` for class names
- Suffix screens with `Screen`
- Suffix widgets with `Widget` or their type

#### Variables and Methods
- Use `camelCase` for variables and methods
- Use descriptive names: `getUserProfile()` not `getProfile()`
- Private members start with underscore: `_privateMethod()`

## Adding New Features

### Step 1: Create Feature Structure

```bash
# Create feature directory
mkdir -p lib/features/new_feature/{screens,widgets,models,services}
```

### Step 2: Create the Screen

```dart
// lib/features/new_feature/screens/new_feature_screen.dart
import 'package:flutter/material.dart';

class NewFeatureScreen extends StatefulWidget {
  const NewFeatureScreen({Key? key}) : super(key: key);

  @override
  State<NewFeatureScreen> createState() => _NewFeatureScreenState();
}

class _NewFeatureScreenState extends State<NewFeatureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Feature'),
      ),
      body: const Center(
        child: Text('New Feature Content'),
      ),
    );
  }
}
```

### Step 3: Add Navigation

Update `lib/shared/widgets/main_navigation.dart` if needed:

```dart
// Add to navigation items
NavigationDestination(
  icon: Icon(Icons.new_icon),
  label: 'New Feature',
),

// Add to body pages
NewFeatureScreen(),
```

### Step 4: Create Service (if needed)

```dart
// lib/core/services/new_feature_service.dart
class NewFeatureService {
  static final NewFeatureService _instance = NewFeatureService._internal();
  factory NewFeatureService() => _instance;
  NewFeatureService._internal();

  // Service methods
  Future<List<Item>> getItems() async {
    // Implementation
  }
}
```

### Step 5: Add Demo Data (if needed)

Update `lib/core/demo_data/demo_data_manager.dart`:

```dart
// Add to appropriate section
List<NewModel> _demoNewModels = [
  NewModel(
    id: 'new_001',
    name: 'Demo Item',
    // ... other properties
  ),
];
```

## State Management

### Using Provider

#### 1. Create State Class

```dart
// lib/features/new_feature/state/new_feature_state.dart
import 'package:flutter/foundation.dart';

class NewFeatureState extends ChangeNotifier {
  bool _isLoading = false;
  List<Item> _items = [];

  bool get isLoading => _isLoading;
  List<Item> get items => _items;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _items = await NewFeatureService().getItems();
    
    _isLoading = false;
    notifyListeners();
  }
}
```

#### 2. Provide State

```dart
// In main.dart or feature root
ChangeNotifierProvider(
  create: (_) => NewFeatureState(),
  child: NewFeatureScreen(),
)
```

#### 3. Consume State

```dart
// In widget
Consumer<NewFeatureState>(
  builder: (context, state, child) {
    if (state.isLoading) {
      return CircularProgressIndicator();
    }
    return ListView.builder(
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(state.items[index].name),
        );
      },
    );
  },
)
```

## Working with Demo Data

### Adding New Demo Users

```dart
// In demo_data_manager.dart
User(
  id: 'user_010',
  name: 'New User',
  email: 'new.user@student.uts.edu.au',
  course: 'Bachelor of Engineering',
  year: '2nd Year',
  // ... other properties
),
```

### Adding New Events

```dart
Event(
  id: 'event_new',
  title: 'New Event',
  startTime: DateTime.now().add(Duration(days: 1)),
  endTime: DateTime.now().add(Duration(days: 1, hours: 2)),
  // ... other properties
),
```

## UI/UX Guidelines

### Using App Theme

```dart
// Use theme colors
Theme.of(context).primaryColor
Theme.of(context).colorScheme.secondary

// Use theme text styles
Theme.of(context).textTheme.headlineLarge
Theme.of(context).textTheme.bodyMedium
```

### Custom Colors

```dart
// Use AppColors from constants
import 'package:uniconnect/core/constants/app_colors.dart';

Container(
  color: AppColors.primary,
  child: Text(
    'Text',
    style: TextStyle(color: AppColors.textLight),
  ),
)
```

### Responsive Design

```dart
// Use MediaQuery for responsive layouts
double screenWidth = MediaQuery.of(context).size.width;
double screenHeight = MediaQuery.of(context).size.height;

// Responsive padding
EdgeInsets.symmetric(
  horizontal: screenWidth * 0.05,
  vertical: screenHeight * 0.02,
)
```

## Testing

### Unit Tests

```dart
// test/services/new_feature_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NewFeatureService', () {
    test('should return items', () async {
      final service = NewFeatureService();
      final items = await service.getItems();
      
      expect(items, isNotEmpty);
      expect(items.first.id, isNotNull);
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/new_feature_screen_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NewFeatureScreen displays correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NewFeatureScreen(),
      ),
    );

    expect(find.text('New Feature'), findsOneWidget);
  });
}
```

## Code Quality

### Before Committing

```bash
# Format code
dart format lib/

# Analyze code
flutter analyze

# Run tests
flutter test
```

### Code Review Checklist

- [ ] Code follows naming conventions
- [ ] No hardcoded strings (use constants)
- [ ] Proper error handling
- [ ] Widget keys where necessary
- [ ] Dispose of controllers/streams
- [ ] No unnecessary rebuilds
- [ ] Responsive design considered
- [ ] Dark mode supported
- [ ] Tests added/updated
- [ ] Documentation updated

## Performance Optimization

### Image Optimization

```dart
// Use CachedNetworkImage for network images
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### List Optimization

```dart
// Use ListView.builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(items[index].name),
    );
  },
)
```

### State Optimization

```dart
// Use const constructors where possible
const Text('Static Text')
const Icon(Icons.star)

// Use keys for stateful widgets in lists
ListView.builder(
  itemBuilder: (context, index) {
    return MyStatefulWidget(
      key: ValueKey(items[index].id),
      item: items[index],
    );
  },
)
```

## Debugging

### Debug Prints

```dart
// Use debugPrint instead of print
debugPrint('Debug message: ${variable}');

// For objects
debugPrint(jsonEncode(object.toJson()));
```

### Flutter Inspector

- Use Flutter Inspector in VS Code/Android Studio
- Inspect widget tree
- Check widget properties
- Debug layout issues

### DevTools

```bash
# Open DevTools
flutter pub global run devtools
```

## Documentation

### Code Comments

```dart
/// Brief description of the class.
///
/// More detailed explanation if needed.
class MyClass {
  /// Brief description of the method.
  ///
  /// [param1] - Description of parameter.
  /// Returns description of return value.
  String myMethod(String param1) {
    // Implementation
  }
}
```

### Update Changes Stack

After making changes, update `docs/CHANGES_STACK.md`:

```markdown
### YYYY-MM-DD HH:MM
- **Type**: Feature
- **Location**: lib/features/new_feature/
- **Change**: Added new feature for X functionality
- **Docs Impact**: Update features documentation
```

## Git Workflow

### Commit Messages

Format: `type: description`

Types:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Code style
- `refactor:` Code refactoring
- `test:` Testing
- `chore:` Maintenance

Examples:
```bash
git commit -m "feat: add friend location sharing"
git commit -m "fix: resolve calendar event overlap issue"
git commit -m "docs: update API documentation"
```

## Next Steps

1. Review [Testing Guide](testing-guide.md)
2. Check [Demo Data Guide](demo-data-guide.md)
3. See [Adding Features](adding-features.md)
4. Read [State Management](state-management.md)