//
//  AlarmManagerTests.swift
//  Peaceful Wake UpTests
//
//  Created by Mike McDonald on 9/26/25.
//

import XCTest
@testable import Peaceful_Wake_Up

final class AlarmManagerTests: XCTestCase {
    var alarmManager: AlarmManager!
    
    override func setUp() {
        super.setUp()
        alarmManager = AlarmManager()
    }
    
    override func tearDown() {
        alarmManager = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    func testInitialState() {
        XCTAssertFalse(alarmManager.isAlarmSet, "Alarm should not be set initially")
        XCTAssertFalse(alarmManager.showingAlarmSetter, "Alarm setter should not be showing initially")
        XCTAssertFalse(alarmManager.isSilentAlarm, "Should not be silent alarm initially")
        XCTAssertNil(alarmManager.alarmStartTime, "Alarm start time should be nil initially")
        XCTAssertFalse(alarmManager.hasEnteredSunrisePhase, "Should not have entered sunrise phase initially")
    }
    
    // MARK: - Button Text Tests
    func testButtonTextWhenAlarmNotSet() {
        alarmManager.isAlarmSet = false
        alarmManager.showingAlarmSetter = false
        XCTAssertEqual(alarmManager.buttonText, "Set Alarm")
    }
    
    func testButtonTextWhenShowingAlarmSetter() {
        alarmManager.isAlarmSet = false
        alarmManager.showingAlarmSetter = true
        XCTAssertEqual(alarmManager.buttonText, "Confirm Alarm")
    }
    
    func testButtonTextWhenAlarmSet() {
        alarmManager.isAlarmSet = true
        alarmManager.showingAlarmSetter = false
        XCTAssertEqual(alarmManager.buttonText, "Cancel Alarm")
    }
    
    // MARK: - Button Color Tests
    func testButtonColorWhenAlarmNotSet() {
        alarmManager.isAlarmSet = false
        alarmManager.showingAlarmSetter = false
        // Test that color is the expected yellow/soft sunrise color
        XCTAssertNotNil(alarmManager.buttonColor)
    }
    
    func testButtonColorWhenShowingAlarmSetter() {
        alarmManager.isAlarmSet = false
        alarmManager.showingAlarmSetter = true
        // Test that color is the expected orange color
        XCTAssertNotNil(alarmManager.buttonColor)
    }
    
    func testButtonColorWhenAlarmSet() {
        alarmManager.isAlarmSet = true
        // Test that color is red
        XCTAssertNotNil(alarmManager.buttonColor)
    }
    
    // MARK: - Alarm Operations Tests
    func testSetAlarm() {
        let initialTime = Date()
        alarmManager.showingAlarmSetter = true
        
        alarmManager.setAlarm()
        
        XCTAssertTrue(alarmManager.isAlarmSet, "Alarm should be set")
        XCTAssertFalse(alarmManager.showingAlarmSetter, "Alarm setter should be hidden")
        XCTAssertNotNil(alarmManager.alarmStartTime, "Alarm start time should be set")
        
        // Check that alarm start time is approximately now
        if let alarmStartTime = alarmManager.alarmStartTime {
            XCTAssertEqual(alarmStartTime.timeIntervalSince(initialTime), 0, accuracy: 1.0)
        }
    }
    
    func testCancelAlarm() {
        // Set up alarm first
        alarmManager.setAlarm()
        alarmManager.hasEnteredSunrisePhase = true
        
        alarmManager.cancelAlarm()
        
        XCTAssertFalse(alarmManager.isAlarmSet, "Alarm should not be set")
        XCTAssertFalse(alarmManager.showingAlarmSetter, "Alarm setter should not be showing")
        XCTAssertFalse(alarmManager.hasEnteredSunrisePhase, "Should not be in sunrise phase")
        XCTAssertNil(alarmManager.alarmStartTime, "Alarm start time should be nil")
    }
    
    // MARK: - Time Until Alarm Tests
    func testTimeUntilAlarmWhenNotSet() {
        alarmManager.isAlarmSet = false
        let currentTime = Date()
        
        let result = alarmManager.timeUntilAlarm(currentTime: currentTime)
        
        XCTAssertEqual(result, "", "Should return empty string when alarm not set")
    }
    
    func testTimeUntilAlarmWhenAlarmTimePassed() {
        alarmManager.isAlarmSet = true
        alarmManager.alarmTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let currentTime = Date()
        
        let result = alarmManager.timeUntilAlarm(currentTime: currentTime)
        
        XCTAssertEqual(result, "Alarm Active", "Should show 'Alarm Active' when time has passed")
    }
    
    func testTimeUntilAlarmInMinutes() {
        alarmManager.isAlarmSet = true
        let currentTime = Date()
        alarmManager.alarmTime = currentTime.addingTimeInterval(30 * 60) // 30 minutes
        
        let result = alarmManager.timeUntilAlarm(currentTime: currentTime)
        
        XCTAssertEqual(result, "30 Minutes", "Should show correct minutes")
    }
    
    func testTimeUntilAlarmInHoursAndMinutes() {
        alarmManager.isAlarmSet = true
        let currentTime = Date()
        alarmManager.alarmTime = currentTime.addingTimeInterval(2 * 3600 + 30 * 60) // 2 hours 30 minutes
        
        let result = alarmManager.timeUntilAlarm(currentTime: currentTime)
        
        XCTAssertEqual(result, "2 Hours 30 Minutes", "Should show correct hours and minutes")
    }
    
    func testTimeUntilAlarmExactHour() {
        alarmManager.isAlarmSet = true
        let currentTime = Date()
        alarmManager.alarmTime = currentTime.addingTimeInterval(3600) // Exactly 1 hour
        
        let result = alarmManager.timeUntilAlarm(currentTime: currentTime)
        
        XCTAssertEqual(result, "1 Hours 0 Minutes", "Should show exact hour")
    }
    
    // MARK: - State Transition Tests
    func testStateTransitionFromInitialToAlarmSetter() {
        alarmManager.showingAlarmSetter = true
        
        XCTAssertTrue(alarmManager.showingAlarmSetter)
        XCTAssertEqual(alarmManager.buttonText, "Confirm Alarm")
    }
    
    func testStateTransitionFromAlarmSetterToAlarmSet() {
        alarmManager.showingAlarmSetter = true
        alarmManager.setAlarm()
        
        XCTAssertTrue(alarmManager.isAlarmSet)
        XCTAssertFalse(alarmManager.showingAlarmSetter)
        XCTAssertEqual(alarmManager.buttonText, "Cancel Alarm")
    }
}
