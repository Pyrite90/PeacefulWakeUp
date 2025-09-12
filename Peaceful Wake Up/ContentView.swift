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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var alarmTime: Date = Date().addingTimeInterval(3600)
    @State private var lastInteraction: Date = Date()
    @State private var showBlackOverlay: Bool = false
    @State private var inactivityTimer: Timer?
    @State private var sunriseTimer: Timer?
    @State private var timeTimer: Timer?
    @State private var originalBrightness: CGFloat = UIScreen.main.brightness
    @State private var isAlarmSet: Bool = false
    @State private var currentBrightness: CGFloat = 1.0
    @State private var currentTime: Date = Date()
    @State private var showingAlarmSetter: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var originalVolume: Float = 0.0
    @State private var brightnessBeforeInactivity: CGFloat = 1.0
    @State private var volumeTimer: Timer?
    @State private var alarmStartTime: Date?
    @State private var isSilentAlarm: Bool = false
    @State private var systemBrightnessAtSunriseStart: CGFloat = 1.0
    @State private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    @State private var hasEnteredSunrisePhase: Bool = false

    var body: some View {
        ZStack {
            // Sunrise gradient background - fills entire screen
            SunriseBackgroundView()
            
            // Main content
            VStack(spacing: 0) {
                // Title at the very top
                Text("Peaceful Wake Up")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(1.0))
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        handleTapToDismissAlarmSetter()
                    }
                
                Spacer()
                    .onTapGesture {
                        handleTapToDismissAlarmSetter()
                    }
                
                // Current time and alarm display
                TimeDisplayView(
                    currentTime: currentTime,
                    alarmTime: alarmTime,
                    isAlarmSet: isAlarmSet,
                    timeUntilAlarm: timeUntilAlarm,
                    onTapGesture: handleTapToDismissAlarmSetter
                )
                
                Spacer()
                    .onTapGesture {
                        handleTapToDismissAlarmSetter()
                    }
                
                // Main alarm interface at bottom
                VStack {
                    // Only show DatePicker when setting alarm
                    if showingAlarmSetter {
                        AlarmSetterView(
                            alarmTime: $alarmTime,
                            isSilentAlarm: $isSilentAlarm,
                            showingAlarmSetter: $showingAlarmSetter,
                            onConfirm: setAlarm
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Show different UI based on alarm state
                    AlarmControlsView(
                        isAlarmSet: isAlarmSet,
                        showingAlarmSetter: showingAlarmSetter,
                        buttonText: buttonText,
                        buttonColor: buttonColor,
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
                onTap: userInteracted,
                setBrightness: { brightness in
                    setBrightnessSafely(brightness)
                    currentBrightness = brightness
                }
            )
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
            withAnimation(.easeInOut(duration: 0.3)) {
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
    
    private var timeUntilAlarm: String {
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
        
        setupAudioSession()
        startInactivityTimer()
        startTimeTimer()
    }

    private func cleanupApp() {
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Safety check before restoring brightness
        if UIScreen.main.responds(to: #selector(setter: UIScreen.brightness)) {
            setBrightnessSafely(originalBrightness)
        }
        
        stopAlarmSound()
        invalidateAllTimers()
        endBackgroundTask()
    }
    
    // MARK: - Secure Brightness Control
    private func setBrightnessSafely(_ brightness: CGFloat) {
        let safeBrightness = min(max(brightness, 0.0), 1.0)
        
        guard UIScreen.main.responds(to: #selector(setter: UIScreen.brightness)) else {
            print("Brightness control not available")
            return
        }
        
        UIScreen.main.brightness = safeBrightness
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
            
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            
            // Store original volume safely
            originalVolume = audioSession.outputVolume
            
            // Prepare audio player with validation
            setupAudioPlayerSecurely()
            
        } catch let error as NSError {
            print("Failed to set up audio session: \(error.localizedDescription)")
            // Handle specific error cases
            if error.code == AVAudioSession.ErrorCode.cannotStartPlaying.rawValue {
                print("Cannot start playing audio - permission denied or hardware issue")
            }
            // Note: categoryNotAvailable was removed as it's not a valid error code
        } catch {
            print("Unexpected audio session error: \(error.localizedDescription)")
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
            
            // Set audio player volume to lowest audible level
            setVolumeSecurely(0.1)
            
            // Start playing with validation
            let playResult = player.play()
            if playResult {
                startVolumeTimer()
            } else {
                print("Failed to start audio playback")
            }
            
        } catch let error as NSError {
            print("Failed to override silent mode: \(error.localizedDescription)")
            
            // Try to play anyway but log the specific error
            if error.code == AVAudioSession.ErrorCode.cannotStartPlaying.rawValue {
                print("Cannot start playing - system restriction")
            }
            
            // Attempt fallback playback
            let playResult = player.play()
            if playResult {
                startVolumeTimer()
            }
        } catch {
            print("Unexpected audio playback error: \(error.localizedDescription)")
        }
    }
    
    private func setVolumeSecurely(_ volume: Float) {
        let safeVolume = min(max(volume, 0.0), 1.0)
        audioPlayer?.volume = safeVolume
    }
    
    private func stopAlarmSound() {
        audioPlayer?.stop()
        
        // Restore original audio session settings safely
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
        } catch {
            print("Failed to restore audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Enhanced Timer Management
    private func invalidateAllTimers() {
        let timers = [inactivityTimer, sunriseTimer, timeTimer, volumeTimer]
        timers.forEach { timer in
            timer?.invalidate()
        }
        inactivityTimer = nil
        sunriseTimer = nil
        timeTimer = nil
        volumeTimer = nil
    }
    
    // Keep original function for backward compatibility
    private func invalidateTimers() {
        invalidateAllTimers()
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
    
    // MARK: - Timer Functions
    private func startTimeTimer() {
        timeTimer?.invalidate()
        timeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentTime = Date()
            }
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
    
    private func cancelAlarm() {
        isAlarmSet = false
        showingAlarmSetter = false
        hasEnteredSunrisePhase = false // Reset sunrise phase flag
        invalidateAllTimers()
        startInactivityTimer()
        startTimeTimer()
        
        // Restore system brightness to what it was before sunrise phase started
        setBrightnessSafely(systemBrightnessAtSunriseStart)
        currentBrightness = 1.0
        
        // Stop the audio when the alarm is canceled
        stopAlarmSound()
        endBackgroundTask()
    }
    
    // MARK: - Enhanced Input Validation
    private func setAlarm() {
        // Remove seconds and nanoseconds from the selected alarm time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarmTime)
        guard let exactTime = calendar.date(from: components) else {
            print("Failed to create exact alarm time - invalid date components")
            return
        }
        
        // Validate alarm time is reasonable (not too far in future)
        let maxFutureTime = Date().addingTimeInterval(7 * 24 * 3600) // 7 days
        guard exactTime <= maxFutureTime else {
            print("Alarm time too far in future - maximum 7 days allowed")
            return
        }
        
        // Validate alarm time is not in the past by more than a few minutes
        let minimumValidTime = Date().addingTimeInterval(-300) // Allow 5 minutes in past for clock sync issues
        guard exactTime > minimumValidTime else {
            print("Alarm time too far in the past")
            return
        }
        
        alarmTime = exactTime
        
        // Adjust to tomorrow if needed
        if alarmTime <= Date() {
            guard let tomorrowTime = Calendar.current.date(byAdding: .day, value: 1, to: alarmTime) else {
                print("Failed to calculate tomorrow's alarm time")
                return
            }
            alarmTime = tomorrowTime
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingAlarmSetter = false
            isAlarmSet = true
        }
        startSunriseTimer()
    }

    private func toggleAlarm() {
        if isAlarmSet {
            // Cancel alarm
            isAlarmSet = false
            invalidateAllTimers()
            startInactivityTimer()
            startTimeTimer()
            setBrightnessSafely(originalBrightness)
            currentBrightness = originalBrightness
        } else {
            // Set alarm
            guard alarmTime > Date() else {
                // If time is in the past, set it for tomorrow
                guard let tomorrowTime = Calendar.current.date(byAdding: .day, value: 1, to: alarmTime) else {
                    print("Failed to set alarm for tomorrow")
                    return
                }
                alarmTime = tomorrowTime
                return
            }
            isAlarmSet = true
            startSunriseTimer()
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
        // 1. During sunrise phase (in updateBrightnessForSunrise)
        // 2. When app starts/ends (in setupApp/cleanupApp)
        // 3. When alarm is canceled (in cancelAlarm)
    }

    private func startInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let timeSinceLastInteraction = Date().timeIntervalSince(self.lastInteraction)
            let now = Date()
            let sunriseStart = self.alarmTime.addingTimeInterval(-600) // 10 minutes before alarm
            
            // If alarm is set and we're within 10 minutes of alarm time, keep overlay off
            let shouldKeepOverlayOff = self.isAlarmSet && now >= sunriseStart
            
            let shouldShowOverlay = !shouldKeepOverlayOff && timeSinceLastInteraction > 30

            if shouldShowOverlay != self.showBlackOverlay {
                DispatchQueue.main.async {
                    if shouldShowOverlay {
                        // About to show black overlay - save current brightness and set to minimum
                        self.brightnessBeforeInactivity = UIScreen.main.brightness
                        self.setBrightnessSafely(0.01)
                        self.currentBrightness = 0.01
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showBlackOverlay = shouldShowOverlay
                    }
                }
            }
        }
    }

    private func startSunriseTimer() {
        sunriseTimer?.invalidate()
        sunriseTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.updateBrightnessForSunrise()
        }
    }

    private func restartSunriseTimer() {
        if isAlarmSet {
            startSunriseTimer()
        }
    }

    private func updateBrightnessForSunrise() {
        let now = Date()
        let sunriseStart = alarmTime.addingTimeInterval(-600) // 10 minutes before alarm

        DispatchQueue.main.async {
            if now >= sunriseStart && now <= self.alarmTime {
                // Check if this is the first time entering sunrise phase
                if !self.hasEnteredSunrisePhase {
                    // Mark that we've entered sunrise phase
                    self.hasEnteredSunrisePhase = true
                    
                    // Capture the current system brightness before we change it
                    self.systemBrightnessAtSunriseStart = UIScreen.main.brightness
                    
                    // Set system brightness to maximum immediately
                    self.setBrightnessSafely(1.0)
                    
                    print("Sunrise phase started - system brightness set to maximum")
                }
                
                // Calculate sunrise progress (0.0 to 1.0)
                let progress = now.timeIntervalSince(sunriseStart) / 600.0
                let targetBrightness = max(0.0, min(1.0, progress))
                
                // Update app brightness for visual overlay (this creates the gradual sunrise effect)
                self.currentBrightness = CGFloat(targetBrightness)
                
            } else if now > self.alarmTime {
                // Alarm time reached - ensure full brightness and complete sunrise
                self.setBrightnessSafely(1.0)
                self.currentBrightness = 1.0
                self.alarmCompleted()
            }
        }
    }
    
    private func alarmCompleted() {
        // Only play alarm sound if it's not a silent alarm
        if !isSilentAlarm {
            // Record the time when alarm sound starts
            alarmStartTime = Date()
            
            // Play alarm sound at lowest volume and keep it looping
            playAlarmSound()
        }
        
        // DON'T reset alarm state here - keep alarm active so audio continues
        // The user must manually cancel via the slider to stop the audio
    }
    
    private func startVolumeTimer() {
        volumeTimer?.invalidate()
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.increaseVolume()
        }
    }
    
    private func increaseVolume() {
        guard let startTime = alarmStartTime else {
            print("No alarm start time set")
            return
        }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        print("Volume increase: \(timeElapsed) seconds elapsed")
        
        // Stop increasing volume after 3 minutes (180 seconds)
        guard timeElapsed <= 180 else {
            volumeTimer?.invalidate()
            volumeTimer = nil
            print("Volume timer stopped after 3 minutes")
            return
        }
        
        // Calculate target volume: from 10% to 100% over 3 minutes
        // Every 10 seconds for 3 minutes = 18 intervals
        // Volume increase per interval = (100% - 10%) / 18 = 5% per interval
        let intervalsElapsed = timeElapsed / 10.0
        let targetVolume = min(1.0, 0.1 + (intervalsElapsed * 0.05)) // 10% + 5% per interval, max 100%
        
        print("Setting volume to: \(targetVolume)")
        setSystemVolume(to: Float(targetVolume))
    }
    
    private func setSystemVolume(to volume: Float) {
        print("Setting volume to: \(volume)")
        // Control the audio player volume directly with bounds checking
        setVolumeSecurely(volume)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
