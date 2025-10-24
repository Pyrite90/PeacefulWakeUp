//
//  AppStateManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import Foundation
import SwiftUI

// MARK: - App State Persistence
class AppStateManager: ObservableObject, AppStateManaging {
    // Singleton pattern for better memory management
    static let shared = AppStateManager()
    
    // Persistent storage keys
    private enum Keys {
        static let lastAlarmTime = "lastAlarmTime"
        static let isSilentAlarm = "isSilentAlarm"
        static let originalBrightness = "originalBrightness"
        static let idleTimerWasDisabled = "idleTimerWasDisabled"
    }
    
    init() {
        // AppStateManager provides access to UserDefaults storage
        // No initialization needed as it's a stateless service
    }


    // MARK: - State Persistence
    func saveAlarmState(alarmTime: Date, isSilent: Bool) {
        UserDefaults.standard.set(alarmTime, forKey: Keys.lastAlarmTime)
        UserDefaults.standard.set(isSilent, forKey: Keys.isSilentAlarm)
    }
    
    func loadPersistedState() -> (alarmTime: Date?, isSilent: Bool) {
        let alarmTime = UserDefaults.standard.object(forKey: Keys.lastAlarmTime) as? Date
        let isSilent = UserDefaults.standard.bool(forKey: Keys.isSilentAlarm)
        return (alarmTime, isSilent)
    }
    
    func saveBrightnessState(_ brightness: CGFloat) {
        UserDefaults.standard.set(Double(brightness), forKey: Keys.originalBrightness)
    }
    
    func loadBrightnessState() -> CGFloat? {
        let brightness = UserDefaults.standard.double(forKey: Keys.originalBrightness)
        return brightness > 0 ? CGFloat(brightness) : nil
    }
    
    func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: Keys.lastAlarmTime)
        UserDefaults.standard.removeObject(forKey: Keys.isSilentAlarm)
        UserDefaults.standard.removeObject(forKey: Keys.originalBrightness)
        UserDefaults.standard.removeObject(forKey: Keys.idleTimerWasDisabled)
    }
    
    // MARK: - Idle Timer State Management
    func saveIdleTimerState(_ isDisabled: Bool) {
        UserDefaults.standard.set(isDisabled, forKey: Keys.idleTimerWasDisabled)
    }
    
    func loadIdleTimerState() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.idleTimerWasDisabled)
    }
    
    func restoreIdleTimerStateOnAppLaunch() {
        // On app launch, check if we had disabled the idle timer previously
        // This helps recover from unexpected app termination
        let wasDisabled = loadIdleTimerState()
        if wasDisabled {
            // If it was disabled, we probably had an alarm set
            // The app will update this properly when it fully initializes
            print("⚠️ Idle timer was disabled on last app session - will be updated based on current alarm state")
        }
    }
}

// MARK: - Performance Optimizations
struct ViewOptimizations {
    // Reduce unnecessary view updates
    static func shouldUpdateTime(_ oldTime: Date, _ newTime: Date) -> Bool {
        // Only update if minutes have changed (reduces second-by-second updates)
        let calendar = Calendar.current
        let oldComponents = calendar.dateComponents([.hour, .minute], from: oldTime)
        let newComponents = calendar.dateComponents([.hour, .minute], from: newTime)
        return oldComponents != newComponents
    }
    
    // Debounce rapid user interactions
    static func debounceUserInteraction(lastInteraction: Date, threshold: TimeInterval = 1.0) -> Bool {
        return Date().timeIntervalSince(lastInteraction) > threshold
    }
}