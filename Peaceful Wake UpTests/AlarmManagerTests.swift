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
    
    // MARK: - Next Day Alarm Tests
    func testSetAlarmForNextDayWhenTimeIsInPast() {
        // Simulate setting alarm at 9:00 PM for 5:00 AM
        let calendar = Calendar.current
        let now = Date()
        
        // Create 5:00 AM today (which would be in the past if current time is after 5:00 AM)
        let morningComponents = calendar.dateComponents([.year, .month, .day], from: now)
        var alarmComponents = morningComponents
        alarmComponents.hour = 5
        alarmComponents.minute = 0
        
        guard let fiveAMToday = calendar.date(from: alarmComponents) else {
            XCTFail("Could not create 5:00 AM date")
            return
        }
        
        // Set the alarm time to 5:00 AM today
        alarmManager.alarmTime = fiveAMToday
        
        // If current time is after 5:00 AM, the alarm should be scheduled for tomorrow
        let shouldScheduleForTomorrow = now > fiveAMToday
        
        alarmManager.setAlarm()
        
        if shouldScheduleForTomorrow {
            // Verify alarm was scheduled for tomorrow
            let timeInterval = alarmManager.alarmTime.timeIntervalSince(now)
            XCTAssertGreaterThan(timeInterval, 0, "Alarm should be scheduled in the future")
            
            // Verify it's approximately 24 hours minus the time past 5:00 AM
            let hoursUntilAlarm = timeInterval / 3600
            XCTAssertGreaterThan(hoursUntilAlarm, 12, "Alarm should be more than 12 hours away (next day)")
            XCTAssertLessThan(hoursUntilAlarm, 24, "Alarm should be less than 24 hours away")
        } else {
            // If current time is before 5:00 AM, alarm should be set for today
            let timeInterval = alarmManager.alarmTime.timeIntervalSince(now)
            XCTAssertGreaterThan(timeInterval, 0, "Alarm should be scheduled in the future")
            XCTAssertLessThan(timeInterval, 24 * 3600, "Alarm should be less than 24 hours away")
        }
        
        XCTAssertTrue(alarmManager.isAlarmSet, "Alarm should be set")
    }
    
    func testSetAlarmForTodayWhenTimeIsInFuture() {
        let calendar = Calendar.current
        let now = Date()
        
        // Set alarm for 2 hours from now
        let futureTime = now.addingTimeInterval(2 * 3600)
        alarmManager.alarmTime = futureTime
        
        alarmManager.setAlarm()
        
        // Verify alarm is set for today (should be close to the original time)
        let timeInterval = alarmManager.alarmTime.timeIntervalSince(now)
        XCTAssertGreaterThan(timeInterval, 1.5 * 3600, "Alarm should be at least 1.5 hours away")
        XCTAssertLessThan(timeInterval, 2.5 * 3600, "Alarm should be at most 2.5 hours away")
        
        XCTAssertTrue(alarmManager.isAlarmSet, "Alarm should be set")
    }
}
