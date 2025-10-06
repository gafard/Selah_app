# Offline-First Sync System Implementation

This document describes the implementation of the offline-first sync system for the Selah app, which provides seamless data synchronization between local storage and Supabase backend.

## Architecture Overview

The sync system consists of several key components:

1. **SyncTask Model** (`lib/core/sync_models.dart`) - Represents sync operations
2. **Hive Boxes** (`lib/core/hive_boxes.dart`) - Local storage configuration
3. **UserRepo** (`lib/data/user_repo.dart`) - Handles local and remote data operations
4. **SyncQueue** (`lib/sync/sync_queue.dart`) - Manages sync task queue with Workmanager
5. **AppState** (`lib/app_state.dart`) - Provides reactive state management
6. **Connectivity Service** (`lib/services/connectivity_service.dart`) - Monitors network changes

## Key Features

- **Offline-First**: All operations work locally first, then sync to server
- **Optimistic Updates**: UI updates immediately, syncs in background
- **Idempotent Sync**: Prevents duplicate operations using idempotency keys
- **Background Processing**: Uses Workmanager for background sync
- **Network Awareness**: Automatically syncs when network becomes available
- **Retry Logic**: Built-in retry mechanism with exponential backoff

## Usage Examples

### 1. Setting Up the App State Provider

The new sync system is integrated into the main app through the `AppStateProvider`:

```dart
// In your widget tree
AppStateProvider(
  userRepo: userRepo,
  queue: syncQueue,
  child: YourApp(),
)
```

### 2. Reading Local Data

```dart
// Get the app state
final appState = AppStateProvider.of(context);

// Access local profile data
final profile = appState.profile;
final displayName = profile?['display_name'] ?? 'Guest';
final hasOnboarded = profile?['hasOnboarded'] ?? false;
```

### 3. Optimistic Updates

```dart
// Mark user as onboarded (optimistic update)
final appState = AppStateProvider.of(context);
await appState.setHasOnboardedOptimistic();

// UI updates immediately, sync happens in background
```

### 4. Monitoring Sync Status

```dart
// Check if there are pending sync operations
final appState = AppStateProvider.of(context);
final hasPendingSync = appState.hasPendingSync;

// Show sync indicator in UI
if (hasPendingSync) {
  return Icon(Icons.sync, color: Colors.orange);
} else {
  return Icon(Icons.check_circle, color: Colors.green);
}
```

### 5. Custom Sync Operations

To add new sync operations, extend the `SyncQueueImpl.processOnce` method:

```dart
// In sync/sync_queue.dart
switch (task.type) {
  case 'profile_sync':
    await repo.syncProfileToServer(task.payload, idempotencyKey: task.idempotencyKey);
    break;
  case 'your_new_sync_type':
    // Add your custom sync logic here
    await yourCustomSyncMethod(task.payload);
    break;
}
```

## Database Schema

The system expects a `profiles` table in Supabase with the following structure:

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  display_name TEXT,
  hasOnboarded BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at_local TIMESTAMP WITH TIME ZONE,
  idempotency_key TEXT
);
```

## Configuration

### iOS Background Modes

The iOS `Info.plist` is already configured with the required background modes:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
    <string>fetch</string>
</array>
```

### Android Configuration

No additional Android configuration is required. The default Workmanager setup handles background processing.

### Environment Variables

Make sure to set the following environment variables:

```bash
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Sync Flow

1. **Local Operation**: User performs an action (e.g., completes onboarding)
2. **Optimistic Update**: Data is immediately written to local Hive storage
3. **Queue Task**: A sync task is added to the queue with an idempotency key
4. **Background Sync**: Workmanager processes the queue when network is available
5. **Server Sync**: Data is synced to Supabase with conflict resolution
6. **Local Update**: Local data is updated with the server response

## Error Handling

- **Network Errors**: Tasks are retried with exponential backoff
- **Max Retries**: After 5 failed attempts, tasks are removed from the queue
- **Conflict Resolution**: Server data takes precedence if it's newer than local data
- **Idempotency**: Duplicate operations are prevented using idempotency keys

## Testing

The system includes example usage in `lib/examples/sync_usage_example.dart`:

- `SyncUsageExample`: Shows how to display sync status and perform optimistic updates
- `OnboardingExample`: Demonstrates optimistic onboarding flow

## Migration from Existing System

The new sync system runs alongside the existing system. To migrate:

1. Replace direct Supabase calls with optimistic updates
2. Use `AppStateProvider.of(context)` to access local data
3. Monitor `hasPendingSync` for UI indicators
4. Gradually migrate features to use the new sync system

## Performance Considerations

- **Local-First**: All UI operations are instant (no network delays)
- **Background Processing**: Sync happens in background isolates
- **Efficient Storage**: Hive provides fast local storage
- **Minimal Network Usage**: Only changed data is synced
- **Batched Operations**: Multiple changes can be batched together

## Troubleshooting

### Common Issues

1. **Sync Not Working**: Check network connectivity and Supabase configuration
2. **Data Not Updating**: Verify the AppState provider is properly set up
3. **Background Tasks Not Running**: Ensure iOS background modes are enabled
4. **Duplicate Data**: Check idempotency key implementation

### Debug Information

The system logs sync operations and errors. Check the console for:
- Sync task enqueueing
- Background task execution
- Network connectivity changes
- Error messages and retry attempts

## Future Enhancements

Potential improvements to consider:

1. **Conflict Resolution UI**: Allow users to resolve conflicts manually
2. **Sync Progress Indicators**: Show detailed sync progress
3. **Offline Mode Indicators**: Clear UI feedback when offline
4. **Data Compression**: Compress sync payloads for better performance
5. **Selective Sync**: Allow users to choose what data to sync
6. **Sync Scheduling**: Allow users to control when sync happens


