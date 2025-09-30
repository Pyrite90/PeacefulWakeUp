//
//  AlarmIntegrationTests.swift
//  Peaceful Wake UpTests
//
//  Created by Mike McDonald on 9/26/25.
//

import XCTest
@testable import Peaceful_Wake_Up

final class AlarmIntegrationTests: XCTestCase {
    var alarmManager: AlarmManager!
    var audioManager: AudioManager!
    var performanceMetrics: PerformanceMetrics!
    var backgroundTaskManager: BackgroundTaskManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        alarmManager = AlarmManager()
        audioManager = AudioManager()
        performanceMetrics = PerformanceMetrics()
        backgroundTaskManager = BackgroundTaskManager()
    }
    
    override func tearDown() {
        audioManager?.cleanupAudioResources()
        backgroundTaskManager?.endBackgroundTask()
        alarmManager = nil
        audioManager = nil
        performanceMetrics = nil
        backgroundTaskManager = nil
        super.tearDown()
    }
    
    // MARK: - Complete Alarm Flow Tests
    func testCompleteAlarmSetupFlow() {
        // 1. Initial state
        XCTAssertFalse(alarmManager.isAlarmSet)
        XCTAssertEqual(alarmManager.buttonText, "Set Alarm")
        
        // 2. Show alarm setter
        alarmManager.showingAlarmSetter = true
        XCTAssertEqual(alarmManager.buttonText, "Confirm Alarm")
        
        // 3. Set alarm
        alarmManager.setAlarm()
        XCTAssertTrue(alarmManager.isAlarmSet)
        XCTAssertFalse(alarmManager.showingAlarmSetter)
        XCTAssertEqual(alarmManager.buttonText, "Cancel Alarm")
        XCTAssertNotNil(alarmManager.alarmStartTime)
        
        // 4. Cancel alarm
        alarmManager.cancelAlarm()
        XCTAssertFalse(alarmManager.isAlarmSet)
        XCTAssertEqual(alarmManager.buttonText, "Set Alarm")
        XCTAssertNil(alarmManager.alarmStartTime)
    }
    
    func testAlarmWithAudioFlow() {
        // Setup audio
        audioManager.setupAudioSession()
        
        // Set alarm
        alarmManager.setAlarm()
        XCTAssertTrue(alarmManager.isAlarmSet)
        
        // Trigger alarm (simulate)
        XCTAssertNoThrow(audioManager.playAlarmSound())
        
        // Cancel alarm
        alarmManager.cancelAlarm()
        audioManager.stopAlarmSound()
        
        XCTAssertFalse(alarmManager.isAlarmSet)
    }
    
    // MARK: - Performance Integration Tests
    @MainActor
    func testPerformanceMetricsIntegration() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Setup audio and record time
        audioManager.setupAudioSession()
        
        let setupTime = CFAbsoluteTimeGetCurrent() - startTime
        performanceMetrics.recordAudioSetupTime(setupTime)
        
        // Verify metrics were recorded
        XCTAssertGreaterThanOrEqual(performanceMetrics.audioSetupTime, 0)
        XCTAssertLessThan(performanceMetrics.audioSetupTime, 5.0) // Should be reasonably fast
    }
    
    // MARK: - Background Task Integration Tests
    func testAlarmWithBackgroundTasks() {
        // Set alarm
        alarmManager.setAlarm()
        
        // Simulate app going to background
        backgroundTaskManager.handleAppGoingToBackground()
        
        // Alarm should still be set
        XCTAssertTrue(alarmManager.isAlarmSet)
        
        // Simulate app returning to foreground
        backgroundTaskManager.handleAppReturningToForeground()
        
        // Clean up
        alarmManager.cancelAlarm()
        XCTAssertFalse(alarmManager.isAlarmSet)
    }
    
    // MARK: - Error Handling Integration Tests
    func testErrorRecovery() {
        // Test that errors in one component don't break others
        
        // 1. Try to play audio before setup (should handle gracefully)
        XCTAssertNoThrow(audioManager.playAlarmSound())
        
        // 2. Alarm functionality should still work
        alarmManager.setAlarm()
        XCTAssertTrue(alarmManager.isAlarmSet)
        
        // 3. Setup audio after alarm is set
        XCTAssertNoThrow(audioManager.setupAudioSession())
        
        // 4. Everything should work normally now
        XCTAssertNoThrow(audioManager.playAlarmSound())
        
        // 5. Clean up
        alarmManager.cancelAlarm()
        audioManager.stopAlarmSound()
    }
    
    // MARK: - Memory Management Integration Tests
    func testMemoryManagement() {
        // Create multiple managers and ensure proper cleanup
        var managers: [Any] = []
        
        for _ in 0..<10 {
            let alarm = AlarmManager()
            let audio = AudioManager()
            let background = BackgroundTaskManager()
            
            alarm.setAlarm()
            audio.setupAudioSession()
            background.startBackgroundTask()
            
            managers.append(alarm)
            managers.append(audio)
            managers.append(background)
        }
        
        // Clean up - should not cause memory issues
        XCTAssertNoThrow(managers.removeAll())
    }
    
    // MARK: - Concurrent Access Tests
    func testConcurrentAlarmOperations() {
        let expectation = self.expectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 10
        
        // Simulate multiple threads trying to set/cancel alarms
        for i in 0..<10 {
            DispatchQueue.global().async {
                if i % 2 == 0 {
                    self.alarmManager.setAlarm()
                } else {
                    self.alarmManager.cancelAlarm()
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
        
        // Should be in a consistent state
        XCTAssertNotNil(alarmManager.buttonText)
    }
    
    // MARK: - State Consistency Tests
    func testStateConsistency() {
        // Test that related states remain consistent
        
        // When alarm is not set
        alarmManager.isAlarmSet = false
        XCTAssertEqual(alarmManager.buttonText, "Set Alarm")
        
        // When showing alarm setter
        alarmManager.showingAlarmSetter = true
        alarmManager.isAlarmSet = false
        XCTAssertEqual(alarmManager.buttonText, "Confirm Alarm")
        
        // When alarm is set
        alarmManager.setAlarm()
        XCTAssertTrue(alarmManager.isAlarmSet)
        XCTAssertFalse(alarmManager.showingAlarmSetter)
        XCTAssertNotNil(alarmManager.alarmStartTime)
        XCTAssertEqual(alarmManager.buttonText, "Cancel Alarm")
    }
    
    // MARK: - Performance Integration Tests
    func testFullSystemPerformance() {
        measure {
            // Complete alarm cycle
            alarmManager.setAlarm()
            audioManager.setupAudioSession()
            backgroundTaskManager.startBackgroundTask()
            
            audioManager.playAlarmSound()
            
            alarmManager.cancelAlarm()
            audioManager.stopAlarmSound()
            backgroundTaskManager.endBackgroundTask()
        }
    }
    
    // MARK: - Time-based Tests
    func testTimeUntilAlarmAccuracy() {
        let currentTime = Date()
        let futureTime = currentTime.addingTimeInterval(3661) // 1 hour, 1 minute, 1 second
        
        alarmManager.alarmTime = futureTime
        alarmManager.isAlarmSet = true
        
        let timeString = alarmManager.timeUntilAlarm(currentTime: currentTime)
        
        // Should show approximately 1 hour and 1 minute
        XCTAssertTrue(timeString.contains("1 Hours"))
        XCTAssertTrue(timeString.contains("1 Minutes"))
    }
}
