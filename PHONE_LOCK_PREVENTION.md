# Phone Lock Prevention Documentation

## Overview

The Peaceful Wake Up app prevents the phone from locking automatically when an alarm is set. This ensures that the sunrise animation and alarm interface remain visible and accessible throughout the night.

## Implementation

### Core Mechanism

The app uses iOS's `UIApplication.shared.isIdleTimerDisabled` property to control whether the device should automatically lock after a period of inactivity.

- **When alarm is set**: `isIdleTimerDisabled = true` (prevents locking)
- **When no alarm is set**: `isIdleTimerDisabled = false` (allows normal locking)

### Key Components

#### 1. ContentView - Main Controller

Located in: `ContentView.swift`

The main view controller manages idle timer state through the `updateIdleTimerForAlarmState()` method:

```swift
private func updateIdleTimerForAlarmState() {
    let shouldDisableIdleTimer = alarmManager.isAlarmSet

    if UIApplication.shared.isIdleTimerDisabled != shouldDisableIdleTimer {
        UIApplication.shared.isIdleTimerDisabled = shouldDisableIdleTimer
        appStateManager.saveIdleTimerState(shouldDisableIdleTimer)

        // Logging for debugging
        if shouldDisableIdleTimer {
            print("🔒 Phone lock disabled - alarm is set")
        } else {
            print("🔓 Phone lock enabled - no alarm set")
        }
    }
}
```

#### 2. AppStateManager - State Persistence

Located in: `Managers/AppStateManager.swift`

Manages the persistence of idle timer state to handle app crashes or unexpected termination:

```swift
func saveIdleTimerState(_ isDisabled: Bool)
func loadIdleTimerState() -> Bool
func restoreIdleTimerStateOnAppLaunch()
```

### When Idle Timer State Changes

1. **Alarm Set**: Called when user confirms alarm setting
2. **Alarm Cancelled**: Called when user cancels an active alarm
3. **App Lifecycle**: Called when app goes to background/foreground
4. **App Launch**: Called during app initialization

### App Lifecycle Integration

The app properly handles state changes during different lifecycle events:

```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
    backgroundTaskManager.handleAppGoingToBackground()
    updateIdleTimerForAlarmState()
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
    backgroundTaskManager.handleAppReturningToForeground()
    updateIdleTimerForAlarmState()
}
```

## Safety Measures

### 1. State Recovery

If the app crashes while the idle timer is disabled, the app detects this on launch and logs a warning. The idle timer state is then updated based on the current alarm state.

### 2. Cleanup on Exit

When the app is properly terminated, the idle timer is always re-enabled to prevent battery drain:

```swift
private func cleanupApp() {
    // Always re-enable idle timer on cleanup
    UIApplication.shared.isIdleTimerDisabled = false
    AppLogger.info("Idle timer re-enabled during app cleanup", category: .system)
}
```

### 3. Optimization

The system only updates the idle timer state when it actually changes, avoiding unnecessary operations:

```swift
if UIApplication.shared.isIdleTimerDisabled != shouldDisableIdleTimer {
    // Only update if state actually changed
}
```

## User Experience

### When Alarm is Active

- ✅ Phone screen stays on
- ✅ Sunrise animation continues throughout the night
- ✅ Alarm interface remains visible and accessible
- ✅ Touch interactions work normally

### When No Alarm is Set

- ✅ Phone locks normally according to device settings
- ✅ Battery is conserved
- ✅ Normal device behavior is maintained

## Testing

The functionality is tested through:

1. **Unit Tests**: `AppStateManagerTests.swift` verifies state persistence
2. **Integration Tests**: Verify idle timer state changes with alarm state
3. **Manual Testing**: Confirm phone doesn't lock when alarm is set

## Power Consumption Considerations

### Battery Impact

Keeping the screen on will drain battery faster than normal. However:

- This is the expected behavior for an alarm clock app
- Users typically charge their phone overnight when using bedside alarms
- The app only prevents locking when an alarm is actually set

### Performance Optimizations

- State changes are minimized through change detection
- Background processing is optimized
- Memory management prevents resource leaks

## Debugging

### Console Output

The app provides clear console logging:

- `🔒 Phone lock disabled - alarm is set`
- `🔓 Phone lock enabled - no alarm set`

### App Logger Integration

Detailed logging is available through the AppLogger system:

- `AppLogger.info("Idle timer disabled - preventing device sleep", category: .system)`
- `AppLogger.info("Idle timer enabled - allowing device sleep", category: .system)`

## Troubleshooting

### If Phone Still Locks

1. Check that an alarm is actually set (`alarmManager.isAlarmSet == true`)
2. Verify app is in foreground
3. Check for iOS restrictions or Low Power Mode
4. Review console logs for state changes

### If Phone Won't Lock After Alarm

1. Ensure alarm was properly cancelled
2. Check if app crashed during cleanup
3. Manually restart the app to reset state
4. Verify `updateIdleTimerForAlarmState()` was called

## Future Enhancements

Potential improvements could include:

- User setting to disable this behavior
- Smart detection of charging state
- Integration with Focus modes
- Reduced brightness mode during night hours
