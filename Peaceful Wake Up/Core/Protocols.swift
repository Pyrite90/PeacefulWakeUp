//
//  Protocols.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

// MARK: - Audio Management Protocol
protocol AudioManaging: AnyObject {
    func setupAudioSession()
    func playAlarmSound()
    func stopAlarmSound()
    func setSystemVolume(to volume: Float)
    func setSystemVolumeSafely(_ volume: Float)
    func preloadAudioResources()
    func cleanupAudioResources()
    func handleAudioSessionInterruption(notification: Notification)
}

// MARK: - Brightness Management Protocol
protocol BrightnessManaging: AnyObject {
    var currentBrightness: CGFloat { get set }
    var showBlackOverlay: Bool { get set }
    
    func setupBrightness()
    func setBrightnessSafely(_ brightness: CGFloat)
    func userInteracted()
    func cleanup()
}

// MARK: - Alarm Management Protocol  
protocol AlarmManaging: ObservableObject {
    var alarmTime: Date { get set }
    var isAlarmSet: Bool { get set }
    var showingAlarmSetter: Bool { get set }
    var isSilentAlarm: Bool { get set }
    var alarmStartTime: Date? { get set }
    var hasEnteredSunrisePhase: Bool { get set }
    
    var buttonText: String { get }
    var buttonColor: Color { get }
    
    func setAlarm()
    func cancelAlarm()
    func timeUntilAlarm(currentTime: Date) -> String
}

// MARK: - Performance Metrics Protocol
protocol PerformanceTracking: ObservableObject {
    func recordAudioSetupTime(_ time: TimeInterval)
    func recordBrightnessChange()
    func recordVolumeChange()
    func logMetrics()
}

// MARK: - Background Task Management Protocol
protocol BackgroundTaskManaging: AnyObject {
    func handleAppGoingToBackground()
    func handleAppReturningToForeground()
    func startBackgroundTask()
    func endBackgroundTask()
}

// MARK: - Notification Management Protocol
protocol NotificationManaging: AnyObject {
    func setupNotificationObservers(
        onMemoryWarning: @escaping () -> Void,
        onAudioInterruption: @escaping (Notification) -> Void
    )
    func removeNotificationObservers()
}

// MARK: - App State Management Protocol
protocol AppStateManaging: ObservableObject {
    func saveAlarmState(alarmTime: Date, isSilent: Bool)
    func loadPersistedState() -> (alarmTime: Date?, isSilent: Bool)
    func saveBrightnessState(_ brightness: CGFloat)
    func loadBrightnessState() -> CGFloat?
    func clearPersistedState()
}

// MARK: - Dependency Container
class DependencyContainer {
    // Managers
    lazy var audioManager: AudioManaging = AudioManager()
    lazy var alarmManager: any AlarmManaging = AlarmManager()
    lazy var performanceMetrics: any PerformanceTracking = PerformanceMetrics()
    lazy var backgroundTaskManager: BackgroundTaskManaging = BackgroundTaskManager()
    lazy var notificationManager: NotificationManaging = NotificationManager()
    lazy var appStateManager: any AppStateManaging = AppStateManager()
    
    // For testing - allows injection of mock implementations
    static var shared = DependencyContainer()
    
    func reset() {
        // Reset all managers - useful for testing
        Self.shared = DependencyContainer()
    }
}

// MARK: - Mock Implementations for Testing
#if DEBUG
class MockAudioManager: AudioManaging {
    var setupCalled = false
    var playCalled = false
    var stopCalled = false
    var volumeSet: Float?
    
    func setupAudioSession() { setupCalled = true }
    func playAlarmSound() { playCalled = true }
    func stopAlarmSound() { stopCalled = true }
    func setSystemVolume(to volume: Float) { volumeSet = volume }
    func setSystemVolumeSafely(_ volume: Float) { volumeSet = volume }
    func preloadAudioResources() { }
    func cleanupAudioResources() { }
    func handleAudioSessionInterruption(notification: Notification) { }
}

class MockBrightnessManager: BrightnessManaging {
    var currentBrightness: CGFloat = 1.0
    var showBlackOverlay: Bool = false
    var setupCalled = false
    var brightnessSet: CGFloat?
    
    func setupBrightness() { setupCalled = true }
    func setBrightnessSafely(_ brightness: CGFloat) { brightnessSet = brightness }
    func userInteracted() { }
    func cleanup() { }
}
#endif
