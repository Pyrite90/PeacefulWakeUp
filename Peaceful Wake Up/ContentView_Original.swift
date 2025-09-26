//
//  ContentView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/7/25.
//

import SwiftUI
import SwiftData
import AVFoundation
import MediaPlayer

// MARK: - Alarm State Management (ObservableObject for better state management)
class AlarmManager: ObservableObject {
    @Published var alarmTime: Date = Date().addingTimeInterval(3600)
    @Published var isAlarmSet: Bool = false
    @Published var showingAlarmSetter: Bool = false
    @Published var isSilentAlarm: Bool = false
    @Published var alarmStartTime: Date?
    @Published var hasEnteredSunrisePhase: Bool = false
    
    // Computed properties for better performance
    var buttonText: String {
        if isAlarmSet {
            return "Cancel Alarm"
        } else if showingAlarmSetter {
            return "Confirm Alarm"
        } else {
            return "Set Alarm"
        }
    }
    
    var buttonColor: Color {
        if isAlarmSet {
            return Color.red.opacity(0.8)
        } else if showingAlarmSetter {
            return Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.8)
        } else {
            return Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.8)
        }
    }
}

struct ContentView: View {
    // MARK: - Timer Management Improvements
    // Use weak self in all timer/closure-based code to avoid retain cycles
    // TimelineView is used for periodic updates, so no manual timers for UI updates
    // If you add any new Timer, always invalidate before creating a new one

    // Example for a custom timer (if needed):
    private var customTimer: Timer? {
        willSet { customTimer?.invalidate() }
    }
    @Environment(\.modelContext) private var modelContext
    @StateObject private var alarmManager = AlarmManager()
    
    // MARK: - UI State (reduced @State variables)
    @State private var lastInteraction: Date = Date()
    @State private var showBlackOverlay: Bool = false
    @State private var currentBrightness: CGFloat = 1.0
    @State private var brightnessBeforeInactivity: CGFloat = 1.0
    @State private var systemBrightnessAtSunriseStart: CGFloat = 1.0
    
    // MARK: - System State
    @State private var originalBrightness: CGFloat = UIScreen.main.brightness
    @State private var originalVolume: Float = 0.0
    @State private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Audio Resources
    @State private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Performance Monitoring
    @State private var performanceMetrics = PerformanceMetrics()
    
    // MARK: - Notification Observers (for proper cleanup)
    @State private var notificationObservers: [NSObjectProtocol] = []

// MARK: - Performance Monitoring
struct PerformanceMetrics {
    private(set) var audioSetupTime: TimeInterval = 0
    private(set) var brightnessChangeCount: Int = 0
    private(set) var volumeChangeCount: Int = 0
    
    mutating func recordAudioSetupTime(_ time: TimeInterval) {
        audioSetupTime = time
    }
    
    mutating func recordBrightnessChange() {
        brightnessChangeCount += 1
    }
    
    mutating func recordVolumeChange() {
        volumeChangeCount += 1
    }
    
    func logMetrics() {
        print("Performance Metrics:")
        print("  Audio Setup Time: \(audioSetupTime)s")
        print("  Brightness Changes: \(brightnessChangeCount)")
        print("  Volume Changes: \(volumeChangeCount)")
    }
}

    var body: some View {
        // Compatible TimelineView for iOS 18-26
        TimelineView(TimelineViewCompat.createPeriodicSchedule(interval: 1.0)) { timeline in
            let currentTime = timeline.date
            
            ZStack {
                // Sunrise gradient background - fills entire screen
                SunriseBackgroundView()
                
                // Main content
                VStack(spacing: 0) {
                    // Title at the very top with iOS version info in debug
                    VStack {
                        Text("Peaceful Wake Up")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(1.0))
                        
                        #if DEBUG
                        Text("iOS \(iOSCompatibility.versionString)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        #endif
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        handleTapToDismissAlarmSetter()
                    }
                    
                    Spacer()
                        .onTapGesture {
                            handleTapToDismissAlarmSetter()
                        }
                    
                    // Current time and alarm display - now uses TimelineView's currentTime
                    TimeDisplayView(
                        currentTime: currentTime,
                        alarmTime: alarmManager.alarmTime,
                        isAlarmSet: alarmManager.isAlarmSet,
                        timeUntilAlarm: timeUntilAlarm(currentTime: currentTime),
                        onTapGesture: handleTapToDismissAlarmSetter
                    )
                    
                    Spacer()
                        .onTapGesture {
                            handleTapToDismissAlarmSetter()
                        }
                    
                    // Main alarm interface at bottom
                    VStack {
                        // Only show DatePicker when setting alarm
                        if alarmManager.showingAlarmSetter {
                            AlarmSetterView(
                                alarmTime: $alarmManager.alarmTime,
                                isSilentAlarm: $alarmManager.isSilentAlarm,
                                showingAlarmSetter: $alarmManager.showingAlarmSetter,
                                onConfirm: setAlarm
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Show different UI based on alarm state
                        AlarmControlsView(
                            isAlarmSet: alarmManager.isAlarmSet,
                            showingAlarmSetter: alarmManager.showingAlarmSetter,
                            buttonText: alarmManager.buttonText,
                            buttonColor: alarmManager.buttonColor,
                            onAlarmButton: handleAlarmButton,
                            onCancel: cancelAlarm
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                
                // Brightness overlays
                BrightnessOverlayView(
                    currentBrightness: currentBrightness,
                    showBlackOverlay: showBlackOverlay,
                    currentTime: currentTime,
                    onTap: userInteracted,
                    setBrightness: { brightness in
                        setBrightnessSafely(brightness)
                        currentBrightness = brightness
                    }
                )
                
                // Inactivity TimelineView - replaces inactivityTimer
                InactivityTimelineView(
                    lastInteraction: lastInteraction,
                    isAlarmSet: alarmManager.isAlarmSet,
                    alarmTime: alarmManager.alarmTime,
                    showBlackOverlay: $showBlackOverlay,
                    currentBrightness: $currentBrightness,
                    brightnessBeforeInactivity: $brightnessBeforeInactivity,
                    setBrightness: setBrightnessSafely
                )
                
                // Sunrise TimelineView - replaces sunriseTimer
                if alarmManager.isAlarmSet {
                    SunriseTimelineView(
                        alarmTime: alarmManager.alarmTime,
                        hasEnteredSunrisePhase: $alarmManager.hasEnteredSunrisePhase,
                        systemBrightnessAtSunriseStart: $systemBrightnessAtSunriseStart,
                        currentBrightness: $currentBrightness,
                        setBrightness: setBrightnessSafely,
                        onAlarmCompleted: alarmCompleted
                    )
                }
                
                // Volume TimelineView - replaces volumeTimer
                if let alarmStartTime = alarmManager.alarmStartTime {
                    VolumeTimelineView(
                        alarmStartTime: alarmStartTime,
                        setSystemVolume: setSystemVolume
                    )
                }
            }
        }
        .onAppear {
            setupApp()
        }
        .onDisappear {
            cleanupApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            handleAppGoingToBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            handleAppReturningToForeground()
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    userInteracted()
                }
        )
    }
    
    // MARK: - Helper Functions
    
    private func handleTapToDismissAlarmSetter() {
        if showingAlarmSetter {
            withAnimation(AnimationCompat.easeInOut) {
                showingAlarmSetter = false
            }
        }
    }

    // MARK: - App Lifecycle Management
    // Note: Using .onDisappear instead of deinit since SwiftUI structs don't support deinitializers
    
    // MARK: - Computed Properties
    private var buttonText: String {
        if isAlarmSet {
            return "Cancel Alarm"
        } else if showingAlarmSetter {
            return "Confirm Alarm"
        } else {
            return "Set Alarm"
        }
    }
    
    private var buttonColor: Color {
        if isAlarmSet {
            return Color.red.opacity(0.8)
        } else if showingAlarmSetter {
            return Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.8) // Warm sunrise orange
        } else {
            return Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.8) // Soft sunrise yellow
        }
    }
    
    private func timeUntilAlarm(currentTime: Date) -> String {
        guard isAlarmSet else { return "" }
        
        let timeInterval = alarmTime.timeIntervalSince(currentTime)
        
        // If alarm time has passed, show that it's active
        guard timeInterval > 0 else { return "Alarm Active" }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours) Hours \(minutes) Minutes"
        } else {
            return "\(minutes) Minutes"
        }
    }

    // MARK: - Enhanced Security Functions
    
    private func setupApp() {
        // Performance tracking
        let setupStartTime = CFAbsoluteTimeGetCurrent()
        
        // Always capture the current system brightness when app opens for restoration later
        let currentSystemBrightness = UIScreen.main.brightness
        originalBrightness = currentSystemBrightness
        
        // Safe brightness control with bounds checking
        let targetBrightness: CGFloat = 1.0
        setBrightnessSafely(targetBrightness)
        currentBrightness = 1.0
        
        // Safety check: Only disable idle timer if brightness control is available
        if UIScreen.main.responds(to: #selector(setter: UIScreen.brightness)) {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        setupNotificationObservers()
        setupAudioSession()
        // Timer functions removed - now handled by TimelineView components
        
        // Performance: Preload audio to avoid delays during alarm
        preloadAudioResources()
        
        let setupTime = CFAbsoluteTimeGetCurrent() - setupStartTime
        performanceMetrics.recordAudioSetupTime(setupTime)
    }

    private func cleanupApp() {
        // Log performance metrics
        performanceMetrics.logMetrics()
        
        // Remove notification observers to prevent memory leaks
        removeNotificationObservers()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Safety check before restoring brightness
        if UIScreen.main.responds(to: #selector(setter: UIScreen.brightness)) {
            setBrightnessSafely(originalBrightness)
        }
        
        stopAlarmSound()
        
        // Memory cleanup: Explicitly release audio player
        cleanupAudioResources()
        
        endBackgroundTask()
        // Timer cleanup removed - TimelineView components handle their own lifecycle
    }
    
    // MARK: - Enhanced Notification Observer Management
    private func setupNotificationObservers() {
        // Clear any existing observers first
        removeNotificationObservers()
        
        let audioInterruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioSessionInterruption(notification: notification)
        }
        
        let memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        notificationObservers = [audioInterruptionObserver, memoryWarningObserver]
    }
    
    private func removeNotificationObservers() {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
    
    private func handleMemoryWarning() {
        print("Received memory warning - performing cleanup")
        // Release non-essential resources
        if !alarmManager.isAlarmSet {
            cleanupAudioResources()
        }
        // Log performance metrics for debugging
        performanceMetrics.logMetrics()
    }
    
    // MARK: - Audio Resource Management
    private func preloadAudioResources() {
        // Preload audio in background to avoid UI blocking
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.setupAudioPlayerSecurely()
        }
    }
    
    private func cleanupAudioResources() {
        audioPlayer?.stop()
        audioPlayer?.prepareToPlay() // Reset to prepared state
        audioPlayer = nil // Explicit cleanup
        
        // Reset audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Secure Brightness Control
    // MARK: - Brightness/Volume Update Optimization
    private var lastBrightnessSet: CGFloat? = nil
    private func setBrightnessSafely(_ brightness: CGFloat) {
        let safeBrightness = min(max(brightness, 0.0), 1.0)
        if let last = lastBrightnessSet, abs(last - safeBrightness) < 0.01 { return }
        guard UIScreen.main.responds(to: #selector(setter: UIScreen.brightness)) else {
            print("Brightness control not available")
            return
        }
        UIScreen.main.brightness = safeBrightness
        lastBrightnessSet = safeBrightness
        performanceMetrics.recordBrightnessChange()
    }

    private var lastVolumeSet: Float? = nil
    private func setSystemVolumeSafely(_ volume: Float) {
        let safeVolume = min(max(volume, 0.0), 1.0)
        if let last = lastVolumeSet, abs(last - safeVolume) < 0.01 { return }
        setSystemVolumeDirectly(to: safeVolume)
        lastVolumeSet = safeVolume
        performanceMetrics.recordVolumeChange()
    }
    
    // MARK: - Enhanced Audio Session Security
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Check if audio session is available and not being used by other apps
            guard !audioSession.isOtherAudioPlaying else {
                print("Other audio is playing - audio setup skipped")
                return
            }
            // Use compatibility layer for cross-version audio session setup
            try audioSession.setCompatibleCategory()
            try audioSession.setActive(true)
            // Store original volume safely
            originalVolume = audioSession.outputVolume
            // Prepare audio player with validation
            setupAudioPlayerSecurely()
            // Register for audio interruptions
            NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: audioSession, queue: .main) { [weak self] notification in
                self?.handleAudioSessionInterruption(notification: notification)
            }
        } catch let error as NSError {
            print("Failed to set up audio session: \(error.localizedDescription)")
            if error.code == AVAudioSession.ErrorCode.cannotStartPlaying.rawValue {
                print("Cannot start playing audio - permission denied or hardware issue")
            }
        } catch {
            print("Unexpected audio session error: \(error.localizedDescription)")
        }
    }

    private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            print("Audio session interruption began")
            audioPlayer?.pause()
        } else if type == .ended {
            print("Audio session interruption ended")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer?.play()
            } catch {
                print("Failed to reactivate audio session after interruption: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Secure Audio Player Setup
    private func setupAudioPlayerSecurely() {
        guard let soundURL = Bundle.main.url(forResource: "Mockingbird", withExtension: "mp3") else {
            print("Could not find Mockingbird.mp3 file")
            return
        }
        
        // Validate file exists and is readable
        guard FileManager.default.fileExists(atPath: soundURL.path),
              FileManager.default.isReadableFile(atPath: soundURL.path) else {
            print("Audio file is not accessible or readable")
            return
        }
        
        // Check file size to prevent loading extremely large files
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: soundURL.path)
            if let fileSize = fileAttributes[FileAttributeKey.size] as? NSNumber {
                let fileSizeInMB = fileSize.doubleValue / (1024 * 1024)
                guard fileSizeInMB < 50 else { // Limit to 50MB
                    print("Audio file too large: \(fileSizeInMB)MB")
                    return
                }
            }
        } catch {
            print("Could not get file attributes: \(error.localizedDescription)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 1.0
            
            // Validate player was created successfully
            guard let player = audioPlayer else {
                print("Failed to create audio player")
                return
            }
            
            let prepareResult = player.prepareToPlay()
            if !prepareResult {
                print("Audio player failed to prepare")
                audioPlayer = nil
            }
            
        } catch {
            print("Failed to initialize audio player: \(error.localizedDescription)")
            audioPlayer = nil
        }
    }
    
    private func playAlarmSound() {
        guard let player = audioPlayer else {
            print("Audio player not available")
            return
        }
        
        // Override silent mode and set system volume to lowest level
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check if we can actually play audio
            guard !audioSession.isOtherAudioPlaying else {
                print("Cannot play alarm - other audio is active")
                return
            }
            
            // Override silent mode by using .playback category without .mixWithOthers
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            
            // Set system volume to 10% of maximum immediately
            setSystemVolumeDirectly(to: 0.1)
            
            // Set audio player volume to maximum (system volume controls the actual output)
            player.volume = 1.0
            
            // Start playing with validation
            let playResult = player.play()
            if playResult {
                // Volume is now handled by VolumeTimelineView - no manual timer needed
                print("Alarm sound started - system volume set to 10%")
            } else {
                print("Failed to start audio playback")
            }
            
        } catch let error as NSError {
            print("Failed to override silent mode: \(error.localizedDescription)")
            
            // Try to play anyway but log the specific error
            if error.code == AVAudioSession.ErrorCode.cannotStartPlaying.rawValue {
                print("Cannot start playing - system restriction")
            }
            
            // Attempt fallback playback with system volume control
            setSystemVolumeDirectly(to: 0.1)
            let playResult = player.play()
            if playResult {
                // Volume is now handled by VolumeTimelineView
                print("Fallback alarm sound started")
            }
        } catch {
            print("Unexpected audio playback error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - System Volume Control
    private func setSystemVolumeDirectly(to volume: Float) {
        // Use compatibility layer for cross-version volume control
        VolumeControlCompat.setSystemVolume(volume)
    }
    
    private func setSystemVolume(to volume: Float) {
        print("Setting system volume to: \(volume)")
        VolumeControlCompat.setSystemVolume(volume)
    }

    // MARK: - Background Task Management
    private func handleAppGoingToBackground() {
        if isAlarmSet {
            startBackgroundTask()
        }
    }
    
    private func handleAppReturningToForeground() {
        endBackgroundTask()
    }
    
    private func startBackgroundTask() {
        endBackgroundTask() // End any existing background task
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AlarmTimer") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    private func handleAlarmButton() {
        if alarmManager.isAlarmSet {
            // Cancel alarm
            cancelAlarm()
        } else if alarmManager.showingAlarmSetter {
            // Confirm and set alarm
            setAlarm()
        } else {
            // Show alarm setter
            withAnimation(.easeInOut(duration: 0.3)) {
                alarmManager.showingAlarmSetter = true
            }
        }
    }

    private func cancelAlarm() {
        isAlarmSet = false
        showingAlarmSetter = false
        hasEnteredSunrisePhase = false // Reset sunrise phase flag
        alarmStartTime = nil // Reset alarm start time to stop VolumeTimelineView
        
        // Restore system brightness to what it was before sunrise phase started
        setBrightnessSafely(systemBrightnessAtSunriseStart)
        currentBrightness = 1.0
        
        // Stop the audio when the alarm is canceled
        stopAlarmSound()
        endBackgroundTask()
    }

    private func setAlarm() {
        // Remove seconds and nanoseconds from the selected alarm time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarmTime)
        guard let exactTime = calendar.date(from: components) else {
            print("Failed to create exact alarm time - invalid date components")
            return
        }
        
        var finalAlarmTime = exactTime
        
        // If the selected time is earlier than now, automatically set it for tomorrow
        if exactTime <= Date() {
            guard let tomorrowTime = Calendar.current.date(byAdding: .day, value: 1, to: exactTime) else {
                print("Failed to calculate tomorrow's alarm time")
                return
            }
            finalAlarmTime = tomorrowTime
            print("Alarm time was in the past, automatically set for tomorrow: \(tomorrowTime)")
        }
        
        // Validate alarm time is reasonable (not too far in future)
        let maxFutureTime = Date().addingTimeInterval(7 * 24 * 3600) // 7 days
        guard finalAlarmTime <= maxFutureTime else {
            print("Alarm time too far in future - maximum 7 days allowed")
            return
        }
        
        // Set the final alarm time
        alarmTime = finalAlarmTime
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingAlarmSetter = false
            isAlarmSet = true
        }
        // Timer management now handled by SunriseTimelineView
    }

    // MARK: - System Volume Control
    private func setSystemVolumeDirectly(to volume: Float) {
        // Use compatibility layer for cross-version volume control
        VolumeControlCompat.setSystemVolume(volume)
    }
    
    private func setSystemVolume(to volume: Float) {
        print("Setting system volume to: \(volume)")
        VolumeControlCompat.setSystemVolume(volume)
    }

    // MARK: - Background Task Management
    private func handleAppGoingToBackground() {
        if isAlarmSet {
            startBackgroundTask()
        }
    }
    
    private func handleAppReturningToForeground() {
        endBackgroundTask()
    }
    
    private func startBackgroundTask() {
        endBackgroundTask() // End any existing background task
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AlarmTimer") {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    private func handleAlarmButton() {
        if isAlarmSet {
            // Cancel alarm
            cancelAlarm()
        } else if showingAlarmSetter {
            // Confirm and set alarm
            setAlarm()
        } else {
            // Show alarm setter
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAlarmSetter = true
            }
        }
    }

    private func userInteracted() {
        lastInteraction = Date()
        
        // Always remove the black overlay when user interacts
        if showBlackOverlay {
            withAnimation(.easeInOut(duration: 0.3)) {
                showBlackOverlay = false
            }
            
            // Only restore visual brightness overlay, not system brightness
            // System brightness should only be changed during sunrise phase
            currentBrightness = 1.0
        }
        
        // Don't change system brightness here - it should only be changed:
        // 1. During sunrise phase (in SunriseTimelineView)
        // 2. When app starts/ends (in setupApp/cleanupApp)
        // 3. When alarm is canceled (in cancelAlarm)
    }
    
    private func alarmCompleted() {
        // Only play alarm sound if it's not a silent alarm
        if !isSilentAlarm {
            // Record the time when alarm sound starts - VolumeTimelineView will handle volume progression
            alarmStartTime = Date()
            
            // Play alarm sound at lowest volume and keep it looping
            playAlarmSound()
        }
        
        // DON'T reset alarm state here - keep alarm active so audio continues
        // The user must manually cancel via the slider to stop the audio
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
