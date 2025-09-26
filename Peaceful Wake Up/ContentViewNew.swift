//
//  ContentView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/7/25.
//  Refactored on 9/26/25 for better modularity
//

import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Managers
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var backgroundTaskManager = BackgroundTaskManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var appStateManager = AppStateManager()
    @StateObject private var performanceMetrics = PerformanceMetrics()
    
    // Use existing BrightnessManager as @Observable
    @State private var brightnessManager = BrightnessManager()
    
    // MARK: - UI State (minimal state in main view)
    @State private var lastInteraction: Date = Date()

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
                        timeUntilAlarm: alarmManager.timeUntilAlarm(currentTime: currentTime),
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
                                onConfirm: alarmManager.setAlarm
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
                            onCancel: handleCancelAlarm
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                
                // Brightness overlays - use existing BrightnessManager structure
                BrightnessOverlayView(
                    currentBrightness: brightnessManager.currentBrightness,
                    showBlackOverlay: brightnessManager.showBlackOverlay,
                    currentTime: currentTime,
                    onTap: userInteracted,
                    setBrightness: { brightness in
                        brightnessManager.setBrightnessSafely(brightness)
                    }
                )
                
                if alarmManager.isAlarmSet {
                    SunriseTimelineView(
                        alarmTime: alarmManager.alarmTime,
                        hasEnteredSunrisePhase: $alarmManager.hasEnteredSunrisePhase,
                        brightnessManager: brightnessManager,
                        onAlarmCompleted: handleAlarmCompleted
                    )
                }
                
                if let alarmStartTime = alarmManager.alarmStartTime {
                    VolumeTimelineView(
                        alarmStartTime: alarmStartTime,
                        setSystemVolume: audioManager.setSystemVolume
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
            backgroundTaskManager.handleAppGoingToBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            backgroundTaskManager.handleAppReturningToForeground()
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
        if alarmManager.showingAlarmSetter {
            withAnimation(AnimationCompat.easeInOut) {
                alarmManager.showingAlarmSetter = false
            }
        }
    }
    
    private func handleAlarmButton() {
        if alarmManager.isAlarmSet {
            handleCancelAlarm()
        } else if alarmManager.showingAlarmSetter {
            alarmManager.setAlarm()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                alarmManager.showingAlarmSetter = true
            }
        }
    }
    
    private func handleCancelAlarm() {
        alarmManager.cancelAlarm()
        audioManager.stopAlarmSound()
        appStateManager.setIdleTimerEnabled(true)
    }
    
    private func handleAlarmCompleted() {
        audioManager.playAlarmSound()
    }
    
    private func userInteracted() {
        lastInteraction = Date()
        brightnessManager.userInteracted()
    }
    
    // MARK: - App Lifecycle
    private func setupApp() {
        let setupStartTime = CFAbsoluteTimeGetCurrent()
        
        // Setup managers
        brightnessManager.setupBrightness()
        appStateManager.setIdleTimerEnabled(false)
        audioManager.setupAudioSession()
        audioManager.preloadAudioResources()
        
        // Setup notifications
        notificationManager.setupNotificationObservers(
            onMemoryWarning: handleMemoryWarning,
            onAudioInterruption: audioManager.handleAudioSessionInterruption
        )
        
        let setupTime = CFAbsoluteTimeGetCurrent() - setupStartTime
        performanceMetrics.recordAudioSetupTime(setupTime)
    }
    
    private func cleanupApp() {
        performanceMetrics.logMetrics()
        notificationManager.removeNotificationObservers()
        appStateManager.setIdleTimerEnabled(true)
        brightnessManager.cleanup()
        audioManager.stopAlarmSound()
        audioManager.cleanupAudioResources()
        backgroundTaskManager.endBackgroundTask()
    }
    
    private func handleMemoryWarning() {
        print("Received memory warning - performing cleanup")
        if !alarmManager.isAlarmSet {
            audioManager.cleanupAudioResources()
        }
        performanceMetrics.logMetrics()
    }
}
