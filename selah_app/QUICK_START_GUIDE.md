# Quick Start Guide - Enhanced Architecture

This guide shows you how to quickly get started with the new enhanced architecture for the Selah app.

## 🚀 Quick Setup

### 1. Use the New Main File

Replace your current `main.dart` with the new bootstrap architecture:

```dart
// Use lib/main_new.dart as your main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'services/user_prefs_hive.dart';
import 'services/background_tasks.dart';
import 'viewmodels/home_vm.dart';
import 'views/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await UserPrefsHive.init();
  await BackgroundTasks.setup();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeVM()..bootstrap()),
      ],
      child: const SelahApp(),
    ),
  );
}
```

### 2. Update Your Home Page

In your home page widget, use the new HomeVM:

```dart
import 'package:provider/provider.dart';
import '../viewmodels/home_vm.dart';

@override
Widget build(BuildContext context) {
  final homeVM = context.watch<HomeVM>();
  final state = homeVM.state;

  return Scaffold(
    body: Column(
      children: [
        // Salutation
        Text('Shalom, ${state.greetingName}'),
        
        // Progression
        LinearProgressIndicator(value: state.progress),
        Text('${state.tasksDone}/${state.tasksTotal} tâches'),
        
        // Version de la Bible
        Text('Version: ${state.bibleVersion ?? 'Aucune'}'),
        
        // Indicateur de sync
        if (state.hasPendingSync)
          const Icon(Icons.sync, color: Colors.orange),
      ],
    ),
  );
}
```

### 3. Add Bible Download Functionality

Add download buttons to your settings or home page:

```dart
import '../services/background_tasks.dart';

ElevatedButton(
  onPressed: () async {
    await BackgroundTasks.queueBible('LSG');
    // User will receive notifications about download progress
  },
  child: const Text('Télécharger LSG'),
)
```

## 📱 Key Features

### ✅ What's Working Now

1. **Local Storage**: All user data stored locally with Hive
2. **Background Downloads**: Bible versions download in background
3. **Push Notifications**: Users get notified when downloads complete
4. **State Management**: Reactive UI updates with Provider
5. **Offline Support**: App works without network connection

### 🔧 Available Services

#### UserPrefsHive
```dart
// Get user profile
final profile = await UserPrefsHive.getProfile();

// Set Bible version
await UserPrefsHive.setBibleVersion('LSG');

// Mark as onboarded
await UserPrefsHive.markOnboardedOptimistic();
```

#### BackgroundTasks
```dart
// Queue Bible download
await BackgroundTasks.queueBible('LSG');
await BackgroundTasks.queueBible('S21');
```

#### HomeVM
```dart
// Access in widgets
final homeVM = context.watch<HomeVM>();
final state = homeVM.state;

// Change Bible version
await homeVM.changeBibleVersion('LSG');
```

## 🎯 Common Use Cases

### 1. Onboarding Flow
```dart
// Mark user as onboarded
await UserPrefsHive.markOnboardedOptimistic();

// Navigate to next page
Navigator.of(context).pushReplacementNamed('/home');
```

### 2. Bible Version Selection
```dart
// In settings page
ElevatedButton(
  onPressed: () async {
    await homeVM.changeBibleVersion('LSG');
    await BackgroundTasks.queueBible('LSG');
  },
  child: const Text('Utiliser LSG'),
)
```

### 3. Progress Tracking
```dart
// Show daily progress
Consumer<HomeVM>(
  builder: (context, homeVM, child) {
    final progress = homeVM.state.progress;
    return LinearProgressIndicator(value: progress);
  },
)
```

### 4. Sync Status
```dart
// Show sync indicator
Consumer<HomeVM>(
  builder: (context, homeVM, child) {
    final hasSync = homeVM.state.hasPendingSync;
    return hasSync 
      ? const Icon(Icons.sync, color: Colors.orange)
      : const Icon(Icons.check_circle, color: Colors.green);
  },
)
```

## 🔄 Migration from Existing System

### Step 1: Gradual Integration
- Keep existing system running
- Add new services alongside
- Test new functionality

### Step 2: Update UI Components
- Replace direct service calls with HomeVM
- Add Provider context where needed
- Update state management

### Step 3: Add New Features
- Implement background downloads
- Add sync indicators
- Enhance offline capabilities

## 🐛 Troubleshooting

### Common Issues

1. **Provider Not Found**
   ```dart
   // Make sure HomeVM is provided in widget tree
   MultiProvider(
     providers: [
       ChangeNotifierProvider(create: (_) => HomeVM()..bootstrap()),
     ],
     child: YourApp(),
   )
   ```

2. **Background Tasks Not Working**
   ```dart
   // Ensure setup is called in main()
   await BackgroundTasks.setup();
   ```

3. **Notifications Not Showing**
   - Check platform permissions
   - Verify notification channels are created

### Debug Tips

1. **Check Telemetry Events**
   ```dart
   final telemetry = TelemetryConsole();
   final events = telemetry.dump();
   print('Events: $events');
   ```

2. **Monitor State Changes**
   ```dart
   // Add debug prints in HomeVM
   void _set(HomeState s) {
     _state = s;
     print('State updated: $s');
     notifyListeners();
   }
   ```

## 📚 Next Steps

1. **Test the Implementation**: Run the app and test all features
2. **Customize UI**: Adapt the examples to your design
3. **Add More Features**: Extend the system with additional functionality
4. **Monitor Performance**: Use telemetry to track app performance

## 🆘 Need Help?

- Check the examples in `lib/examples/`
- Read the full documentation in `ENHANCED_ARCHITECTURE_GUIDE.md`
- Review the original sync system in `OFFLINE_SYNC_IMPLEMENTATION.md`

The enhanced architecture is now ready to use! Start with the quick setup and gradually integrate more features as needed.

