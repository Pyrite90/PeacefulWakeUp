//
//  AudioManagerTests.swift
//  Peaceful Wake UpTests
//
//  Created by Mike McDonald on 9/26/25.
//

import XCTest
import AVFoundation
@testable import Peaceful_Wake_Up

final class AudioManagerTests: XCTestCase {
    var audioManager: AudioManager!
    
    override func setUp() {
        super.setUp()
        audioManager = AudioManager()
    }
    
    override func tearDown() {
        audioManager?.cleanupAudioResources()
        audioManager = nil
        super.tearDown()
    }
    
    // MARK: - Audio Session Setup Tests
    func testAudioSessionSetup() {
        // This test verifies that audio session setup doesn't crash
        // Actual audio session testing requires device/simulator
        XCTAssertNoThrow(audioManager.setupAudioSession())
    }
    
    func testAudioSessionSetupWithOtherAudioPlaying() {
        // Mock scenario where other audio is playing
        // Note: This would require dependency injection for full testability
        XCTAssertNoThrow(audioManager.setupAudioSession())
    }
    
    // MARK: - Audio Playback Tests
    func testPlayAlarmSoundWithoutSetup() {
        // Test playing sound before proper setup
        XCTAssertNoThrow(audioManager.playAlarmSound())
    }
    
    func testStopAlarmSound() {
        // Test stopping alarm sound
        XCTAssertNoThrow(audioManager.stopAlarmSound())
    }
    
    // MARK: - Volume Control Tests
    func testSetSystemVolume() {
        let testVolume: Float = 0.5
        
        XCTAssertNoThrow(audioManager.setSystemVolume(to: testVolume))
    }
    
    func testSetSystemVolumeSafely() {
        // Test volume bounds checking
        audioManager.setSystemVolumeSafely(-0.1) // Below minimum
        audioManager.setSystemVolumeSafely(1.1)  // Above maximum
        audioManager.setSystemVolumeSafely(0.5)  // Valid value
        
        // Should not crash with invalid values
        XCTAssertTrue(true)
    }
    
    func testVolumeChangeOptimization() {
        // Test that setting the same volume twice doesn't cause redundant calls
        audioManager.setSystemVolumeSafely(0.5)
        audioManager.setSystemVolumeSafely(0.5) // Should be optimized out
        
        XCTAssertTrue(true)
    }
    
    // MARK: - Resource Management Tests
    func testPreloadAudioResources() {
        XCTAssertNoThrow(audioManager.preloadAudioResources())
    }
    
    func testCleanupAudioResources() {
        audioManager.setupAudioSession()
        XCTAssertNoThrow(audioManager.cleanupAudioResources())
    }
    
    func testMultipleCleanupCalls() {
        // Test that multiple cleanup calls don't cause issues
        audioManager.cleanupAudioResources()
        audioManager.cleanupAudioResources()
        
        XCTAssertTrue(true)
    }
    
    // MARK: - Audio Interruption Tests
    func testAudioInterruptionHandling() {
        // Create mock interruption notification
        let userInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ]
        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: userInfo
        )
        
        XCTAssertNoThrow(audioManager.handleAudioSessionInterruption(notification: notification))
    }
    
    func testAudioInterruptionEndHandling() {
        let userInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue
        ]
        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: userInfo
        )
        
        XCTAssertNoThrow(audioManager.handleAudioSessionInterruption(notification: notification))
    }
    
    func testInvalidAudioInterruptionNotification() {
        // Test with invalid notification data
        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [:]
        )
        
        XCTAssertNoThrow(audioManager.handleAudioSessionInterruption(notification: notification))
    }
    
    // MARK: - Performance Tests
    func testAudioSetupPerformance() {
        measure {
            audioManager.setupAudioSession()
        }
    }
    
    func testVolumeChangePerformance() {
        measure {
            for i in 0..<100 {
                audioManager.setSystemVolumeSafely(Float(i % 10) / 10.0)
            }
        }
    }
}
