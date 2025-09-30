//
//  MockManagersForTesting.swift
//  Peaceful Wake UpTests
//
//  Created by Mike McDonald on 9/26/25.
//

import XCTest
import SwiftUI
@testable import Peaceful_Wake_Up

// MARK: - Mock Audio Manager with Full Testability
class MockAudioManager: AudioManaging {
    // Test tracking properties
    var setupAudioSessionCalled = false
    var playAlarmSoundCalled = false
    var stopAlarmSoundCalled = false
    var preloadResourcesCalled = false
    var cleanupResourcesCalled = false
    var interruptionHandled = false
    
    var volumeHistory: [Float] = []
    var shouldFailSetup = false
    var shouldFailPlayback = false
    
    // AudioManaging implementation
    func setupAudioSession() {
        setupAudioSessionCalled = true
        if shouldFailSetup {
            AppErrorHandler.handleError(
                AppErrorHandler.AlarmError.audioPlayerFailed,
                context: "Mock audio setup"
            )
        }
    }
    
    func playAlarmSound() {
        playAlarmSoundCalled = true
        if shouldFailPlayback {
            AppErrorHandler.handleError(
                AppErrorHandler.AlarmError.audioPlayerFailed,
                context: "Mock audio playback"
            )
        }
    }
    
    func stopAlarmSound() {
        stopAlarmSoundCalled = true
    }
    
    func setSystemVolume(to volume: Float) {
        volumeHistory.append(volume)
    }
    
    func setSystemVolumeSafely(_ volume: Float) {
        let safeVolume = min(max(volume, 0.0), 1.0)
        volumeHistory.append(safeVolume)
    }
    
    func preloadAudioResources() {
        preloadResourcesCalled = true
    }
    
    func cleanupAudioResources() {
        cleanupResourcesCalled = true
    }
    
    func handleAudioSessionInterruption(notification: Notification) {
        interruptionHandled = true
    }
    
    // Test helpers
    func reset() {
        setupAudioSessionCalled = false
        playAlarmSoundCalled = false
        stopAlarmSoundCalled = false
        preloadResourcesCalled = false
        cleanupResourcesCalled = false
        interruptionHandled = false
        volumeHistory.removeAll()
        shouldFailSetup = false
        shouldFailPlayback = false
    }
}

// MARK: - Mock Brightness Manager
class MockBrightnessManager: BrightnessManaging, ObservableObject {
    @Published var currentBrightness: CGFloat = 1.0
    @Published var showBlackOverlay: Bool = false
    
    var setupBrightnessCalled = false
    var userInteractedCalled = false
    var cleanupCalled = false
    var brightnessHistory: [CGFloat] = []
    
    func setupBrightness() {
        setupBrightnessCalled = true
    }
    
    func setBrightnessSafely(_ brightness: CGFloat) {
        let safeBrightness = min(max(brightness, 0.0), 1.0)
        currentBrightness = safeBrightness
        brightnessHistory.append(safeBrightness)
    }
    
    func userInteracted() {
        userInteractedCalled = true
        showBlackOverlay = false
    }
    
    func cleanup() {
        cleanupCalled = true
    }
    
    func reset() {
        setupBrightnessCalled = false
        userInteractedCalled = false
        cleanupCalled = false
        brightnessHistory.removeAll()
        currentBrightness = 1.0
        showBlackOverlay = false
    }
}

// MARK: - Test Dependency Container
class TestDependencyContainer {
    let mockAudioManager = MockAudioManager()
    let mockBrightnessManager = MockBrightnessManager()
    
    init() {
        // Initialize with mock implementations
        // Note: Actual dependency injection to be implemented later
    }
    
    func resetAllMocks() {
        mockAudioManager.reset()
        mockBrightnessManager.reset()
    }
}
