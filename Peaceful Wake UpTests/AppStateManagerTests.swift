//
//  AppStateManagerTests.swift
//  Peaceful Wake UpTests
//
//  Created by Mike McDonald on 10/23/25.
//

import Testing
import Foundation
@testable import Peaceful_Wake_Up

@Suite(.serialized)
struct AppStateManagerTests {
    
    // Helper to create a clean test environment
    private func createTestManager() -> AppStateManager {
        // Clear all potential UserDefaults keys before each test
        let keys = ["isIdleTimerDisabled", "alarmTime", "isSilent", "alarmSoundName", "snoozeCount", "brightness"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        let manager = AppStateManager()
        return manager
    }
    
    // Clean up after each test
    private func cleanupTestEnvironment() {
        let keys = ["isIdleTimerDisabled", "alarmTime", "isSilent", "alarmSoundName", "snoozeCount", "brightness"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
    }
    
    @Test func saveAndLoadIdleTimerState() {
        let manager = createTestManager()
        
        // Test saving enabled state
        manager.saveIdleTimerState(true)
        #expect(manager.loadIdleTimerState() == true)
        
        // Test saving disabled state
        manager.saveIdleTimerState(false)
        #expect(manager.loadIdleTimerState() == false)
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test func idleTimerStateDefaultsToFalse() {
        let manager = createTestManager()
        
        // Explicitly verify no state exists
        #expect(UserDefaults.standard.object(forKey: "isIdleTimerDisabled") == nil)
        
        let defaultState = manager.loadIdleTimerState()
        #expect(defaultState == false)
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test func idleTimerStatePersistence() {
        let manager1 = createTestManager()
        
        // Save state in one manager instance
        manager1.saveIdleTimerState(true)
        UserDefaults.standard.synchronize() // Force sync
        
        // Create new manager instance and verify persistence
        let manager2 = AppStateManager()
        #expect(manager2.loadIdleTimerState() == true)
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test func restoreIdleTimerStateOnAppLaunch() {
        let manager = createTestManager()
        
        // Save a state
        manager.saveIdleTimerState(true)
        UserDefaults.standard.synchronize()
        
        // Call restore function (which would typically happen on app launch)
        // This method just logs, so we're testing it doesn't crash
        manager.restoreIdleTimerStateOnAppLaunch()
        
        // Verify state is still available
        #expect(manager.loadIdleTimerState() == true)
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test func clearPersistedStateRemovesIdleTimerState() {
        let manager = createTestManager()
        
        // Save idle timer state
        manager.saveIdleTimerState(true)
        UserDefaults.standard.synchronize()
        #expect(manager.loadIdleTimerState() == true)
        
        // Clear all persisted state
        manager.clearPersistedState()
        UserDefaults.standard.synchronize()
        
        // Verify idle timer state is reset to default
        #expect(manager.loadIdleTimerState() == false)
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test func idleTimerStateDoesNotAffectOtherState() {
        let manager = createTestManager()
        
        // Save some alarm state to verify it's not affected
        let testDate = Date()
        manager.saveAlarmState(alarmTime: testDate, isSilent: true)
        UserDefaults.standard.synchronize()
        
        // Save idle timer state
        manager.saveIdleTimerState(true)
        UserDefaults.standard.synchronize()
        
        // Verify both states exist independently
        #expect(manager.loadIdleTimerState() == true)
        let loadedState = manager.loadPersistedState()
        #expect(loadedState.alarmTime != nil) // Check existence rather than exact equality due to precision
        #expect(loadedState.isSilent == true)
        
        // Clear only idle timer state (by setting it to false)
        manager.saveIdleTimerState(false)
        UserDefaults.standard.synchronize()
        
        // Verify idle timer changed but alarm state unchanged
        #expect(manager.loadIdleTimerState() == false)
        let loadedStateAfter = manager.loadPersistedState()
        #expect(loadedStateAfter.alarmTime != nil) // Still exists
        #expect(loadedStateAfter.isSilent == true)
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test func idleTimerStateIntegrationWithAlarmState() {
        let manager = createTestManager()
        
        // Save some alarm state
        let testDate = Date().addingTimeInterval(3600)
        manager.saveAlarmState(alarmTime: testDate, isSilent: true)
        UserDefaults.standard.synchronize()
        
        // Save idle timer state
        manager.saveIdleTimerState(true)
        UserDefaults.standard.synchronize()
        
        // Verify alarm state is still intact
        let loadedState = manager.loadPersistedState()
        #expect(loadedState.alarmTime != nil)
        #expect(loadedState.isSilent == true)
        
        // Verify idle timer state is also intact
        #expect(manager.loadIdleTimerState() == true)
        
        // Cleanup
        cleanupTestEnvironment()
    }
}