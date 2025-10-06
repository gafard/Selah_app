# Enhanced Architecture Implementation Guide

This document describes the enhanced architecture implementation for the Selah app, featuring improved local storage, background tasks, and state management.

## 🏗️ Architecture Overview

The enhanced architecture consists of several key components:

### Core Services
1. **UserPrefsHive** - Enhanced local storage with profile and preferences management
2. **TelemetryConsole** - Event tracking and analytics
3. **BackgroundTasks** - Workmanager integration with notifications
4. **HomeVM** - Simplified state management for the home page

### Key Features
- **Local-First Storage**: All user data stored locally with Hive
- **Background Processing**: Bible downloads and sync operations
- **Push Notifications**: User feedback for background operations
- **State Management**: Reactive UI updates with Provider
- **Offline Capability**: Full functionality without network

## 📦 Package Updates

Updated `pubspec.yaml` with the following versions:
```yaml
dependencies:
  hive: ^4.0.0
  hive_flutter: ^1.1.0
  flutter_local_notifications: ^17.2.1
  provider: ^6.1.2
  workmanager: ^0.5.2
  timezone: ^0.9.4
```

## 🔧 Implementation Details

### 1. UserPrefsHive Service

**Location**: `lib/services/user_prefs_hive.dart`

**Features**:
- Profile management (display name, onboarding status)
- Bible version preferences
- Downloaded versions tracking
- Optimistic updates with timestamps

**Usage**:
```dart
// Get user profile
final profile = await UserPrefsHive.getProfile();

// Set Bible version
await UserPrefsHive.setBibleVersion('LSG');

// Mark as onboarded
await UserPrefsHive.markOnboardedOptimistic();

// Track downloaded versions
await UserPrefsHive.addDownloadedVersion('LSG');
```

### 2. TelemetryConsole Service

**Location**: `lib/services/telemetry_console.dart`

**Features**:
- Event tracking with timestamps
- Properties support
- Console logging (ready for production analytics)

**Usage**:
```dart
final telemetry = TelemetryConsole();
telemetry.track('user_action', props: {'action': 'bible_download'});
```

### 3. BackgroundTasks Service

**Location**: `lib/services/background_tasks.dart`

**Features**:
- Workmanager integration
- Push notifications
- Bible download queuing
- Timezone support

**Usage**:
```dart
// Setup (call in main())
await BackgroundTasks.setup();

// Queue Bible download
await BackgroundTasks.queueBible('LSG');
```

### 4. HomeVM State Management

**Location**: `lib/viewmodels/home_vm.dart`

**Features**:
- Reactive state management
- Profile hydration
- Progress tracking
- Bible version management

**Usage**:
```dart
// In your widget
final homeVM = context.watch<HomeVM>();
final state = homeVM.state;

// Access data
final name = state.greetingName;
final progress = state.progress;
final hasSync = state.hasPendingSync;
```

## 🚀 Bootstrap Architecture

### New Main.dart Structure

**Location**: `lib/main_new.dart`

```dart
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

### Key Bootstrap Steps:
1. **Hive Initialization**: Local storage setup
2. **UserPrefsHive Init**: Profile and preferences loading
3. **BackgroundTasks Setup**: Workmanager and notifications
4. **Provider Setup**: State management initialization

## 📱 Platform Configuration

### iOS Configuration
- **Background Modes**: Already configured in `Info.plist`
  - Background fetch
  - Background processing
- **Notifications**: Darwin settings configured

### Android Configuration
- **Permissions**: Already configured in `AndroidManifest.xml`
  - `RECEIVE_BOOT_COMPLETED`
  - `POST_NOTIFICATIONS`
  - `WAKE_LOCK`
- **Receivers**: Boot completion and notification receivers

## 🔄 Integration Examples

### Home Page Integration

**Location**: `lib/examples/home_integration_example.dart`

Shows how to integrate the new HomeVM with existing UI:

```dart
Consumer<HomeVM>(
  builder: (context, homeVM, child) {
    final state = homeVM.state;
    return Column(
      children: [
        Text('Shalom, ${state.greetingName}'),
        LinearProgressIndicator(value: state.progress),
        Text('${state.tasksDone}/${state.tasksTotal} tâches'),
      ],
    );
  },
)
```

### Background Download Integration

```dart
ElevatedButton(
  onPressed: () async {
    await BackgroundTasks.queueBible('LSG');
    // User gets notification when download completes
  },
  child: const Text('Télécharger LSG'),
)
```

## 🔧 Migration Strategy

### From Existing System

1. **Gradual Migration**: New system runs alongside existing
2. **Data Migration**: UserPrefsHive can read from existing storage
3. **UI Updates**: Replace direct service calls with HomeVM
4. **Background Tasks**: Add download functionality incrementally

### Migration Steps:

1. **Phase 1**: Deploy new services alongside existing
2. **Phase 2**: Update home page to use HomeVM
3. **Phase 3**: Add background download functionality
4. **Phase 4**: Migrate remaining features

## 🧪 Testing

### Unit Tests
- Test UserPrefsHive operations
- Test HomeVM state changes
- Test BackgroundTasks queuing

### Integration Tests
- Test full bootstrap flow
- Test background task execution
- Test notification delivery

### Manual Testing
- Test offline functionality
- Test background downloads
- Test state persistence

## 📊 Monitoring

### Telemetry Events
- `home_loaded`: Home page initialization
- `bible_download_started`: Download queued
- `bible_download_completed`: Download finished
- `bible_download_failed`: Download error

### Performance Metrics
- Bootstrap time
- State update frequency
- Background task success rate
- Storage usage

## 🔮 Future Enhancements

### Planned Features
1. **Advanced Sync**: Conflict resolution UI
2. **Progress Indicators**: Detailed download progress
3. **Offline Mode**: Clear offline indicators
4. **Data Compression**: Optimize storage usage
5. **Selective Sync**: User-controlled sync options

### Technical Improvements
1. **Error Recovery**: Better error handling
2. **Performance**: Optimize state updates
3. **Memory**: Reduce memory footprint
4. **Battery**: Optimize background tasks

## 🐛 Troubleshooting

### Common Issues

1. **Bootstrap Fails**: Check Hive initialization order
2. **Background Tasks Not Running**: Verify Workmanager setup
3. **Notifications Not Showing**: Check platform permissions
4. **State Not Updating**: Verify Provider setup

### Debug Information

Enable debug logging:
```dart
// In main.dart
await BackgroundTasks.setup(); // Logs setup progress
```

Check telemetry events:
```dart
final telemetry = TelemetryConsole();
final events = telemetry.dump(); // Get all tracked events
```

## 📚 Additional Resources

- **Hive Documentation**: https://docs.hivedb.dev/
- **Workmanager Documentation**: https://pub.dev/packages/workmanager
- **Provider Documentation**: https://pub.dev/packages/provider
- **Flutter Local Notifications**: https://pub.dev/packages/flutter_local_notifications

## 🤝 Contributing

When adding new features:

1. Follow the established patterns
2. Add telemetry events for tracking
3. Update documentation
4. Add integration examples
5. Test on both platforms

This enhanced architecture provides a solid foundation for the Selah app's growth while maintaining simplicity and reliability.

